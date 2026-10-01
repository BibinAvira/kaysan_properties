import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../models/supporting_models.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
import '../../repositories/projects_repository.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Areas screen — every district seen across the loaded property pages,
/// grouped client-side (see [AreaModel.fromProjects]). Counts reflect
/// loaded data and grow as more pages load elsewhere in the app.
class AreasView extends ConsumerWidget {
  const AreasView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AreaModel>> areas = ref.watch(areasProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore Areas')),
      body: areas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace st) => EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load areas',
          message: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onActionTap: () => ref.read(projectsProvider.notifier).refresh(),
        ),
        data: (List<AreaModel> list) {
          if (list.isEmpty) {
            return const EmptyStateView(
                icon: Icons.map_outlined,
                title: 'No areas yet',
                message: 'Check back soon.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(height: 14),
            itemBuilder: (BuildContext context, int index) {
              final AreaModel area = list[index];
              return GestureDetector(
                onTap: () =>
                    context.push(RouteNames.areaDetailsPath(area.districtId)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 150,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        AppNetworkImage(url: area.coverImage),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75)
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(area.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Area Details — every one of that district's projects, not just whatever
/// happened to already be loaded from the main feed's pagination (mirrors
/// [DeveloperDetailsView]'s use of [ProjectsController.loadAll]).
class AreaDetailsView extends ConsumerStatefulWidget {
  const AreaDetailsView({super.key, required this.districtId});
  final int districtId;

  @override
  ConsumerState<AreaDetailsView> createState() => _AreaDetailsViewState();
}

class _AreaDetailsViewState extends ConsumerState<AreaDetailsView> {
  String? _developerName;
  ProjectSort _sort = ProjectSort.recommended;

  @override
  void initState() {
    super.initState();
    // "This area's projects" means all of them — not just whichever page
    // happened to load first — so pull in the rest of the catalog once, in
    // the background, past whatever's already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).loadAll();
    });
  }

  /// Sold-out projects sink to the end regardless of [_sort] — a plain
  /// price/handover/recommended sort otherwise has no opinion on sales
  /// status, so a sold-out project can land first just by being cheapest or
  /// soonest to hand over, ahead of everything a visitor can still buy.
  ///
  /// Reelly's own label for this is "Out of Stock" (confirmed against the
  /// live `/projects/sale-statuses` dictionary: Announced, On Sale, Out of
  /// Stock, Presale (EOI), Start of Sales) — matching on "sold" alone, as
  /// if this API used the same wording as the old backend, never actually
  /// matched anything.
  static bool _isSoldOut(ProjectModel p) {
    final String status = p.salesStatusDisplay.toLowerCase();
    return status.contains('sold') || status.contains('out of stock');
  }

  List<ProjectModel> _applyFilterAndSort(List<ProjectModel> source) {
    Iterable<ProjectModel> result = source;
    if (_developerName != null) {
      result =
          result.where((ProjectModel p) => p.developer.name == _developerName);
    }
    final List<ProjectModel> list = result.toList();
    switch (_sort) {
      case ProjectSort.priceLowToHigh:
        list.sort((ProjectModel a, ProjectModel b) =>
            a.lowPrice.compareTo(b.lowPrice));
        break;
      case ProjectSort.priceHighToLow:
        list.sort((ProjectModel a, ProjectModel b) =>
            b.lowPrice.compareTo(a.lowPrice));
        break;
      case ProjectSort.recommended:
        break;
    }
    final List<ProjectModel> available =
        list.where((ProjectModel p) => !_isSoldOut(p)).toList();
    final List<ProjectModel> soldOut = list.where(_isSoldOut).toList();
    return <ProjectModel>[...available, ...soldOut];
  }

  void _openFilterSheet(List<ProjectModel> inArea) {
    final List<String> developers = inArea
        .map((ProjectModel p) => p.developer.name)
        .where((String name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    showModalBottomSheet<void>(
      context: context,
      // Above the tab shell, so the floating nav bar doesn't cover
      // the sheet or inflate its bottom safe-area padding.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // A long developer list (a busy area can have dozens) doesn't
            // fit a fixed-height sheet — DraggableScrollableSheet plus a
            // scrollable body (rather than a plain Column sized to its
            // content) is what avoids the bottom overflow that a tall
            // filter list would otherwise hit here.
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.92,
              expand: false,
              builder:
                  (BuildContext context, ScrollController scrollController) {
                final double bottomInset =
                    MediaQuery.of(context).padding.bottom;
                return Column(
                  children: <Widget>[
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                        children: <Widget>[
                          Text('Filters',
                              style: Theme.of(context).textTheme.headlineSmall),
                          const SizedBox(height: 16),
                          if (developers.isNotEmpty) ...<Widget>[
                            Text('Developer',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: developers.map((String name) {
                                final bool isSelected = _developerName == name;
                                return ChoiceChip(
                                  label: Text(name),
                                  selected: isSelected,
                                  onSelected: (bool value) => setSheetState(
                                      () =>
                                          _developerName = value ? name : null),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text('Sort By',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ProjectSort.values.map((ProjectSort sort) {
                              return ChoiceChip(
                                label: Text(_sortLabel(sort)),
                                selected: _sort == sort,
                                onSelected: (bool _) =>
                                    setSheetState(() => _sort = sort),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding:
                              EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {});
                                Navigator.of(sheetContext).pop();
                              },
                              child: const Text('Show Results'),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);

    return pageState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object e, StackTrace st) => const Scaffold(
        body: EmptyStateView(
            icon: Icons.error_outline,
            title: 'Area not found',
            message: 'Please go back and try again.'),
      ),
      data: (ProjectsPageState state) {
        final List<ProjectModel> allInArea = state.items
            .where((ProjectModel p) => p.district.id == widget.districtId)
            .toList();
        final List<ProjectModel> inArea = _applyFilterAndSort(allInArea);
        final String areaName = allInArea.isNotEmpty
            ? allInArea.first.district.name.display
            : 'Area';

        return Scaffold(
          appBar: AppBar(
            title: Text(areaName),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilterSheet(allInArea),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.read(projectsProvider.notifier).loadAll(),
            child: inArea.isEmpty
                ? (state.isSearchingDeeper
                    ? const PropertyGridShimmer()
                    : const EmptyStateView(
                        icon: Icons.map_outlined,
                        title: 'No projects found',
                        message: 'This area has no active listings right now.',
                      ))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: inArea.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ProjectModel project = inArea[index];
                      final Set<int> favIds = favorites.maybeWhen(
                          data: (Set<int> s) => s, orElse: () => <int>{});
                      return PropertyCard(
                        project: project,
                        isFavorite: favIds.contains(project.id),
                        onFavoriteTap: () async {
                          if (await requireAuth(context, ref)) {
                            ref
                                .read(favoritesProvider.notifier)
                                .toggle(project.id);
                          }
                        },
                        onTap: () => context
                            .push(RouteNames.propertyDetailsPath(project.id)),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
