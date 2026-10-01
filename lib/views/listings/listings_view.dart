import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kaysan_properties/repositories/projects_repository.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
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
///
/// All / Off-Plan / Ready tabs under the search bar narrow it by status
/// (server-side — see [ProjectFilter.statusCode]); the title follows the
/// tab. Opened with [propertyStatusCode], it starts on that tab.
class ListingsView extends ConsumerStatefulWidget {
  const ListingsView({super.key, this.propertyStatusCode});

  /// Tab to start on: `null` leaves the current one; `1` Ready; `2` Off-Plan.
  final int? propertyStatusCode;

  @override
  ConsumerState<ListingsView> createState() => _ListingsViewState();
}

class _ListingsViewState extends ConsumerState<ListingsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final int? start = widget.propertyStatusCode;
    if (start != null) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => ref.read(projectFilterProvider.notifier).setStatus(start));
    }
  }

  static String _titleFor(int? statusCode) => switch (statusCode) {
        1 => 'Ready Properties',
        2 => 'Off-Plan Projects',
        _ => 'All Properties',
      };

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
      final FilteredProjectsController filtered =
          ref.read(filteredProjectsProvider.notifier);
      // A region/area filter pages its own server-filtered results rather than
      // the general feed — see FilteredProjectsController.isServerPaged.
      if (filtered.isServerPaged) {
        filtered.loadMore();
      } else {
        ref.read(projectsProvider.notifier).loadMore();
      }
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
    final ProjectsPageState? pageState =
        ref.watch(projectsProvider).valueOrNull;
    final FilteredProjectsController filteredController =
        ref.read(filteredProjectsProvider.notifier);
    final bool serverPaged = filteredController.isServerPaged;
    final bool isLoadingMore = serverPaged
        ? filteredController.serverIsLoadingMore
        : pageState?.isLoadingMore ?? false;
    final bool hasMore = serverPaged
        ? filteredController.serverHasMore
        : pageState?.hasMore ?? false;

    // Only the unscoped "All Properties" catalog shows a headline count —
    // the API's own reported total while browsing unfiltered (so it isn't
    // capped at whatever page has loaded so far), or the live match count
    // once a search/filter narrows it down.
    final bool isUnfiltered =
        !filter.hasActiveFilters && filter.debouncedQuery.trim().isEmpty;
    // Region/area (+ developer) alone is filtered entirely server-side, so the
    // server's total is the real count even before every page has loaded.
    final bool serverOnly = serverPaged && filter.districtId == null;
    final int? count = isUnfiltered
            ? pageState?.totalCount
            : serverOnly
                ? filteredController.serverTotalCount
                : filtered.valueOrNull?.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(filter.statusCode)),
        // bottom: count == null
        //     ? null
        //     : PreferredSize(
        //         preferredSize: const Size.fromHeight(22),
        //         child: Padding(
        //           padding: const EdgeInsets.only(bottom: 8),
        //           child: Text(
        //             '$count ${count == 1 ? 'Property' : 'Properties'}',
        //             style: Theme.of(context).textTheme.labelSmall,
        //           ),
        //         ),
        //       ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            // Same look as the Home search bar: a white pill with a soft
            // shadow, and a round white filter button beside it.
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Material(
                    color: Theme.of(context).cardColor,
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: TextField(
                          style: const TextStyle(fontSize: 12),
                          textAlignVertical: TextAlignVertical.center,
                          decoration: const InputDecoration(
                            hintText: 'Search by project, area or developer',
                            hintStyle: TextStyle(fontSize: 12),
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(left: 15, right: 2),
                              child: Icon(Icons.search,
                                  size: 22,
                                  color: AppColors.textSecondaryLight),
                            ),
                            prefixIconConstraints:
                                BoxConstraints(minWidth: 0, minHeight: 0),
                          ),
                          onChanged: (String v) => ref
                              .read(projectFilterProvider.notifier)
                              .setQuery(v),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Badge(
                  isLabelVisible: filter.hasActiveFilters,
                  backgroundColor: AppColors.gold,
                  child: RoundIconButton(
                    icon: Icons.tune_rounded,
                    size: 52,
                    onTap: () => showModalBottomSheet<void>(
                      context: context,
                      // Above the tab shell, so the floating nav bar doesn't cover
                      // the sheet or inflate its bottom safe-area padding.
                      useRootNavigator: true,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (BuildContext context) => const FilterSheet(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          StatusTabs(
            selected: filter.statusCode,
            onChanged: (int? status) {
              ref.read(projectFilterProvider.notifier).setStatus(status);
              if (_scrollController.hasClients) _scrollController.jumpTo(0);
            },
          ),
          const SizedBox(height: 12),
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
                data: (List<ProjectModel> rawList) {
                  final List<ProjectModel> list = rawList;
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
