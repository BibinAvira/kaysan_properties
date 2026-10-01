import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/search_provider.dart';
import '../../../repositories/projects_repository.dart';
import '../../../services/projects_service.dart';

/// Filter sheet ("Form Fields" design) for Listings, also opened from the
/// Home filter button via [onShowResults]: Area and Developer are dropdown
/// fields that open a searchable list, Region is a row of chips, then the
/// max-price slider and Sort. It opens pre-filled with the filters already
/// applied; nothing changes until "Search" (or "Reset").
///
/// Area uses Reelly's full `/districts` list and, like region, developer
/// and price, is filtered server-side — see [ProjectFilter.hasServerFacet].
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key, this.onShowResults});

  /// Called after the chosen filters have been committed and the sheet
  /// popped. Listings (which already shows results inline) can leave this
  /// null; Home passes a callback that navigates to Listings.
  final VoidCallback? onShowResults;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  /// Max-price slider stops in AED; the last means "no maximum". Spaced
  /// tighter at the low end, where most projects are. (Stop 0 is unused
  /// by the slider, which starts at 500K.)
  static const List<double> _priceStops = <double>[
    0,
    500000,
    750000,
    1000000,
    1250000,
    1500000,
    2000000,
    2500000,
    3000000,
    4000000,
    5000000,
    7500000,
    10000000,
    15000000,
    20000000,
    double.infinity,
  ];
  static const int _lastStop = 15;

  AreaRef? _area;
  DeveloperModel? _developer;
  String? _region;
  double _maxPriceStop = _lastStop * 1.0;
  ProjectSort _sort = ProjectSort.recommended;

  /// True while a picker is opening or open. The first Area open waits for
  /// the area list to download; a second tap in that time used to stack a
  /// second picker, so picking an item seemed not to close it.
  bool _pickerOpen = false;

  @override
  void initState() {
    super.initState();
    // Start both lists downloading now, so a picker opens instantly.
    ref.read(allAreasProvider);
    ref.read(developersProvider);
    final ProjectFilter current = ref.read(projectFilterProvider);
    if (current.areaId != null) {
      _area = AreaRef(current.areaId!, current.areaName ?? 'Selected area');
    }
    if (current.developerId != null) {
      _developer = DeveloperModel(
          id: current.developerId!, name: current.developerName ?? '');
    }
    _region = current.region;
    _sort = current.sort;
    final double? max = current.maxPrice;
    if (max != null) {
      final int i = _priceStops.indexOf(max);
      if (i > 0) _maxPriceStop = i.toDouble();
    }
  }

  void _search() {
    final ProjectFilterController controller =
        ref.read(projectFilterProvider.notifier);
    controller.setArea(_area?.id, name: _area?.name);
    // The old client-side area pick; this sheet uses [setArea] instead.
    controller.setDistrict(null);
    controller.setRegion(_region);
    controller.setDeveloper(_developer?.id, name: _developer?.name);
    final int to = _maxPriceStop.round();
    controller.setPriceRange(null, to < _lastStop ? _priceStops[to] : null);
    controller.setSort(_sort);
    Navigator.of(context).pop();
    widget.onShowResults?.call();
  }

  void _reset() {
    setState(() {
      _area = null;
      _developer = null;
      _region = null;
      _maxPriceStop = _lastStop * 1.0;
      _sort = ProjectSort.recommended;
    });
    ref.read(projectFilterProvider.notifier).clearSheetFilters();
  }

  static String _aed(double value) {
    if (value >= 1000000) {
      final double m = value / 1000000;
      return '${m == m.roundToDouble() ? m.toStringAsFixed(0) : m.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '')}M';
    }
    return '${(value / 1000).toStringAsFixed(0)}K';
  }

  /// "Any price" or "Up to AED 3M".
  String get _priceLabel {
    final int to = _maxPriceStop.round();
    if (to == _lastStop) return 'Any price';
    return 'Up to AED ${_aed(_priceStops[to])}';
  }

  static String _sortLabel(ProjectSort sort) => switch (sort) {
        ProjectSort.recommended => 'Recommended',
        ProjectSort.priceLowToHigh => 'Price: Low to High',
        ProjectSort.priceHighToLow => 'Price: High to Low',
      };

  Future<void> _pickArea() async {
    final List<AreaRef> all =
        await ref.read(allAreasProvider.future).catchError((Object _) => <AreaRef>[]);
    if (!mounted) return;
    // Home's highlighted areas first, then everything else A–Z.
    final List<int> popular =
        homeAreas.map((HomeArea a) => a.districtId).toList();
    final List<AreaRef> sorted = <AreaRef>[
      for (final int id in popular) ...all.where((AreaRef a) => a.id == id),
      ...(all.where((AreaRef a) => !popular.contains(a.id)).toList()
        ..sort((AreaRef a, AreaRef b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()))),
    ];
    final _Pick<AreaRef>? pick = await _showPicker<AreaRef>(
      title: 'Area',
      items: sorted,
      label: (AreaRef a) => a.name,
      isSelected: (AreaRef a) => a.id == _area?.id,
      searchHint: 'Search areas',
    );
    if (pick != null) setState(() => _area = pick.value);
  }

  Future<void> _pickDeveloper() async {
    final List<DeveloperModel> all = await ref
        .read(developersProvider.future)
        .catchError((Object _) => <DeveloperModel>[]);
    if (!mounted) return;
    final _Pick<DeveloperModel>? pick = await _showPicker<DeveloperModel>(
      title: 'Developer',
      items: all,
      label: (DeveloperModel d) => d.name,
      isSelected: (DeveloperModel d) => d.id == _developer?.id,
      searchHint: 'Search developers',
    );
    if (pick != null) setState(() => _developer = pick.value);
  }

  Future<void> _pickSort() async {
    final _Pick<ProjectSort>? pick = await _showPicker<ProjectSort>(
      title: 'Sort by',
      items: ProjectSort.values,
      label: _sortLabel,
      isSelected: (ProjectSort s) => s == _sort,
      allowAny: false,
    );
    if (pick?.value != null) setState(() => _sort = pick!.value!);
  }

  /// Runs [open] unless a picker is already opening or open.
  Future<void> _once(Future<void> Function() open) async {
    if (_pickerOpen) return;
    _pickerOpen = true;
    try {
      await open();
    } finally {
      _pickerOpen = false;
    }
  }

  Future<_Pick<T>?> _showPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T) label,
    required bool Function(T) isSelected,
    String? searchHint,
    bool allowAny = true,
  }) {
    return showModalBottomSheet<_Pick<T>>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext context) => _PickerSheet<T>(
        title: title,
        items: items,
        label: label,
        isSelected: isSelected,
        searchHint: searchHint,
        allowAny: allowAny,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? labelStyle = theme.textTheme.titleSmall;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text('Search new homes',
                      style: theme.textTheme.headlineSmall),
                ),
                TextButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Area', style: labelStyle),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _area?.name,
                    placeholder: 'e.g. Downtown Dubai',
                    onTap: () => _once(_pickArea),
                  ),
                  const SizedBox(height: 18),
                  Text('Developer', style: labelStyle),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _developer?.name,
                    placeholder: 'e.g. Emaar',
                    onTap: () => _once(_pickDeveloper),
                  ),
                  const SizedBox(height: 18),
                  Text('Region', style: labelStyle),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: regionOptions.length + 1,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(width: 8),
                      itemBuilder: (BuildContext context, int index) {
                        final String? region =
                            index == 0 ? null : regionOptions[index - 1];
                        return ChoiceChip(
                          label: Text(region ?? 'Any'),
                          selected: _region == region,
                          onSelected: (bool _) =>
                              setState(() => _region = region),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Price range ($_priceLabel)', style: labelStyle),
                  // One handle — a maximum budget, from 500K (stop 1; a max
                  // of 0 would match nothing) up to "Any price".
                  Slider(
                    value: _maxPriceStop,
                    min: 1,
                    max: _lastStop * 1.0,
                    divisions: _lastStop - 1,
                    onChanged: (double v) => setState(() => _maxPriceStop = v),
                  ),
                  const SizedBox(height: 6),
                  Text('Sort by', style: labelStyle),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _sortLabel(_sort),
                    placeholder: '',
                    onTap: () => _once(_pickSort),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _search,
                    child: const Text('Search'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A white field showing the current choice (or a grey example) with a
/// chevron; tapping opens its picker.
class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String? value;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasValue = value != null && value!.isNotEmpty;
    return Material(
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(
            children: <Widget>[
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: hasValue ? null : AppColors.textSecondaryLight,
                    fontWeight: hasValue ? FontWeight.w500 : null,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSecondaryLight),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// A picker's result: [value] null means "Any". A dismissed picker returns
/// no [_Pick] at all, so "closed" and "chose Any" stay distinguishable.
class _Pick<T> {
  const _Pick(this.value);
  final T? value;
}

/// Searchable list for a dropdown field: an "Any" row (unless
/// [allowAny] is false), then [items], with the selected one ticked.
class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.items,
    required this.label,
    required this.isSelected,
    required this.searchHint,
    required this.allowAny,
  });

  final String title;
  final List<T> items;
  final String Function(T) label;
  final bool Function(T) isSelected;
  final String? searchHint;
  final bool allowAny;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String q = _query.trim().toLowerCase();
    final List<T> matches = q.isEmpty
        ? widget.items
        : widget.items
            .where((T item) => widget.label(item).toLowerCase().contains(q))
            .toList();
    final bool noneSelected = !widget.items.any(widget.isSelected);
    final bool showAny = widget.allowAny && q.isEmpty;

    Widget tile(String text, bool selected, VoidCallback onTap) => ListTile(
          title: Text(text,
              style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : null)),
          trailing: selected
              ? const Icon(Icons.check_rounded, color: AppColors.gold)
              : null,
          onTap: onTap,
        );

    return SizedBox(
      height: widget.searchHint != null
          ? MediaQuery.sizeOf(context).height * 0.8
          : null,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(widget.title, style: theme.textTheme.headlineSmall),
            ),
            if (widget.searchHint != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  autofocus: false,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: widget.searchHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                  ),
                  onChanged: (String v) => setState(() => _query = v),
                ),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: widget.searchHint == null,
                padding: const EdgeInsets.only(bottom: 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: <Widget>[
                  if (showAny)
                    tile('Any', noneSelected,
                        () => Navigator.of(context).pop(_Pick<T>(null))),
                  for (final T item in matches)
                    tile(widget.label(item), widget.isSelected(item),
                        () => Navigator.of(context).pop(_Pick<T>(item))),
                  if (matches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('No matches',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
