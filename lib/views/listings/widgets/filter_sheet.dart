import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import '../../../models/project_model.dart';
import '../../../models/supporting_models.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/search_provider.dart';

/// Modal filter sheet for the Listings screen (also reachable from the
/// Home filter icon via [onShowResults]). Area/Developer options are
/// pulled live from [areasProvider]/[developersProvider] — i.e. whatever
/// has actually appeared in the loaded property pages — rather than a
/// hardcoded list, since the real API's districts/developers are numerous
/// and open-ended (over a thousand properties across many developers).
///
/// Selections are held as **local draft state**, not written to
/// [projectFilterProvider] until "Show Results" is tapped — so every time
/// this sheet is opened it starts blank, even though the results it
/// produced last time stay applied. That's a deliberate one-shot pattern:
/// pick filters → Show Results → the sheet resets for next time, without
/// un-filtering whatever's currently on screen.
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
  static const int _collapsedCount = 10;

  AreaModel? _selectedArea;
  DeveloperModel? _selectedDeveloper;
  ProjectSort _sort = ProjectSort.recommended;

  bool _areasExpanded = false;
  bool _developersExpanded = false;

  void _showResults() {
    final ProjectFilterController controller = ref.read(projectFilterProvider.notifier);
    controller.setDistrict(_selectedArea?.districtId, name: _selectedArea?.name);
    controller.setDeveloper(_selectedDeveloper?.id, name: _selectedDeveloper?.name);
    controller.setSort(_sort);
    Navigator.of(context).pop();
    widget.onShowResults?.call();
  }

  void _clearAll() {
    setState(() {
      _selectedArea = null;
      _selectedDeveloper = null;
      _sort = ProjectSort.recommended;
    });
    ref.read(projectFilterProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final List<AreaModel> areas = ref.watch(areasProvider).valueOrNull ?? <AreaModel>[];
    final List<DeveloperModel> developers =
        ref.watch(developersProvider).valueOrNull ?? <DeveloperModel>[];

    final bool areasCanCollapse = areas.length > _collapsedCount;
    final List<AreaModel> visibleAreas =
        _areasExpanded || !areasCanCollapse ? areas : areas.take(_collapsedCount).toList();
    final bool developersCanCollapse = developers.length > _collapsedCount;
    final List<DeveloperModel> visibleDevelopers = _developersExpanded || !developersCanCollapse
        ? developers
        : developers.take(_collapsedCount).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      expand: false,
      builder: (BuildContext context, ScrollController scrollController) {
        final double bottomInset = MediaQuery.of(context).padding.bottom;
        return ListView(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(20, 8, 20, 24 + bottomInset),
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Filters',
                    style: Theme.of(context).textTheme.headlineSmall),
                TextButton(onPressed: _clearAll, child: const Text('Clear all')),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Area', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Based on the ${areas.length} areas seen so far — scroll the list to load more.',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleAreas.map((AreaModel area) {
                      final bool isSelected = _selectedArea?.districtId == area.districtId;
                      return ChoiceChip(
                        label: Text('${area.name} (${area.projectCount})'),
                        selected: isSelected,
                        onSelected: (bool value) =>
                            setState(() => _selectedArea = value ? area : null),
                      );
                    }).toList(),
                  ),
                  if (areasCanCollapse)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _areasExpanded = !_areasExpanded),
                        child: Text(_areasExpanded ? 'Show Less' : 'Read More'),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Developer',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: visibleDevelopers.map((DeveloperModel dev) {
                      final bool isSelected = _selectedDeveloper?.id == dev.id;
                      return ChoiceChip(
                        label: Text(dev.name),
                        selected: isSelected,
                        onSelected: (bool value) =>
                            setState(() => _selectedDeveloper = value ? dev : null),
                      );
                    }).toList(),
                  ),
                  if (developersCanCollapse)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => setState(() => _developersExpanded = !_developersExpanded),
                        child: Text(_developersExpanded ? 'Show Less' : 'Read More'),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ProjectSort.values.map((ProjectSort sort) {
                return ChoiceChip(
                  label: Text(_sortLabel(sort)),
                  selected: _sort == sort,
                  onSelected: (bool _) => setState(() => _sort = sort),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showResults,
                child: const Text('Show Results'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _sortLabel(ProjectSort sort) {
    switch (sort) {
      case ProjectSort.recommended:
        return 'Recommended';
      case ProjectSort.priceLowToHigh:
        return 'Price: Low to High';
      case ProjectSort.priceHighToLow:
        return 'Price: High to Low';
      case ProjectSort.handoverSoonest:
        return 'Handover: Soonest';
    }
  }
}
