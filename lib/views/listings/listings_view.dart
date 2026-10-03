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

/// Property Listings screen — the full ranked catalogue (Best Match order
/// by default) with search bar, filter sheet, and a grid of
/// [PropertyCard]s. Everything is filtered on-device — see
/// [filteredProjectsProvider].
///
/// All / Off-Plan / Ready tabs under the search bar narrow it by status;
/// the title follows the tab. Opened with [propertyStatusCode], it starts on that tab.
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
    _scrollController.dispose();
    super.dispose();
  }

  /// Pull-to-refresh: re-downloads the catalogue; [filteredProjectsProvider]
  /// re-derives from it.
  Future<void> _refresh() async {
    await ref.read(projectsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<ProjectModel>> filtered =
        ref.watch(filteredProjectsProvider);
    final ProjectFilter filter = ref.watch(projectFilterProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);
    // On a first launch only a preview page is shown while the full
    // catalogue downloads — say so instead of "end of the list".
    final bool isLoadingCatalog =
        ref.watch(projectsProvider).valueOrNull?.isLoadingCatalog ?? false;

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
                    if (isLoadingCatalog) return const PropertyGridShimmer();
                    return _scrollableEmptyState(
                      const EmptyStateView(
                        icon: Icons.search_off,
                        title: 'No properties found',
                        message: 'Try adjusting your search or filters.',
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
                      if (isLoadingCatalog)
                        const SliverToBoxAdapter(
                            child: PaginationFooterLoader())
                      else
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
