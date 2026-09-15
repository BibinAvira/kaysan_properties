import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
import '../../providers/search_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';
import 'widgets/filter_sheet.dart';

/// Property Listings screen — the full catalog with search bar, filter
/// sheet, and an infinite-scrolling grid of [PropertyCard]s. Scrolling
/// near the bottom triggers [ProjectsController.loadMore], which follows
/// the API's own `next_page_url` rather than guessing page numbers.
class ListingsView extends ConsumerStatefulWidget {
  const ListingsView({super.key});

  @override
  ConsumerState<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends ConsumerState<ListingsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final double threshold = _scrollController.position.maxScrollExtent - 400;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(projectsProvider.notifier).loadMore();
    }
  }

  /// Refreshes both the general feed and — since [FilteredProjectsController]
  /// doesn't watch [projectsProvider] at all while a search/developer/
  /// district filter is active (it queries the server directly instead) —
  /// the filtered result set too. Refreshing only [projectsProvider] would
  /// silently do nothing visible whenever a filter/search is applied.
  Future<void> _refresh() async {
    await ref.read(projectsProvider.notifier).refresh();
    ref.invalidate(filteredProjectsProvider);
    try {
      // Awaited only so the pull-to-refresh spinner stays visible until the
      // re-fetch actually finishes; any failure already surfaces through
      // `filtered.when`'s error branch once the provider rebuilds, so it's
      // swallowed here rather than crashing the refresh gesture.
      await ref.read(filteredProjectsProvider.future);
    } catch (_) {
      // Ignored — see above.
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProjectModel>> filtered =
        ref.watch(filteredProjectsProvider);
    final ProjectFilter filter = ref.watch(projectFilterProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);
    final bool isLoadingMore =
        ref.watch(projectsProvider).valueOrNull?.isLoadingMore ?? false;
    final bool hasMore =
        ref.watch(projectsProvider).valueOrNull?.hasMore ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Off-Plan Projects')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by project, area or developer',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (String v) =>
                        ref.read(projectFilterProvider.notifier).setQuery(v),
                  ),
                ),
                const SizedBox(width: 8),
                Badge(
                  isLabelVisible: filter.hasActiveFilters,
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.tune),
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (BuildContext context) => const FilterSheet(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: filtered.when(
                loading: () => const PropertyGridShimmer(),
                error: (Object e, StackTrace st) => _scrollableEmptyState(
                  EmptyStateView(
                    icon: Icons.error_outline,
                    title: 'Something went wrong',
                    message:
                        'We could not load the listings. Pull down to try again.',
                    actionLabel: 'Retry',
                    onActionTap: _refresh,
                  ),
                ),
                data: (List<ProjectModel> list) {
                  if (list.isEmpty) {
                    // Pull-to-refresh needs a Scrollable descendant to
                    // detect the drag — a bare EmptyStateView (just a
                    // Center/Column) doesn't provide one, which is why
                    // refresh silently did nothing whenever the list (or
                    // a search/filter) came back empty.
                    return _scrollableEmptyState(
                      const EmptyStateView(
                        icon: Icons.search_off,
                        title: 'No properties found',
                        message:
                            'Try adjusting your search or filters, or keep scrolling to load more.',
                      ),
                    );
                  }
                  final Set<int> favIds = favorites.maybeWhen(
                      data: (Set<int> s) => s, orElse: () => <int>{});
                  return CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: <Widget>[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.66,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (BuildContext context, int index) {
                              final ProjectModel project = list[index];
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
                                onTap: () => context.push(
                                    RouteNames.propertyDetailsPath(project.id)),
                              );
                            },
                            childCount: list.length,
                          ),
                        ),
                      ),
                      if (isLoadingMore)
                        const SliverToBoxAdapter(
                            child: PaginationFooterLoader())
                      else if (!hasMore)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                'You\'ve reached the end of the list',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps an [EmptyStateView] (or any non-scrolling widget) in an
  /// always-scrollable list so the enclosing [RefreshIndicator] has a
  /// Scrollable to detect the pull gesture on — without this, pulling down
  /// while the empty/error state is showing does nothing at all.
  Widget _scrollableEmptyState(Widget child) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
            SizedBox(height: constraints.maxHeight, child: child),
          ],
        );
      },
    );
  }
}
