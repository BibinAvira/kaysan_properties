import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Developer profile screen: everything the API actually gives us about
/// this developer, plus every one of their projects — not just whatever
/// happened to already be loaded from the main feed's pagination.
///
/// The X-OPP API only ever returns a developer as a plain `developer_name`
/// string on each property (no logo, bio, website or contact endpoint of
/// its own), so this page is only as rich as that: a name, a project
/// count, and the full project list. If the API ever starts returning
/// more (see [DeveloperModel]'s logo/website/email/phone/overview fields,
/// already modeled and just always blank today), this page shows it.
class DeveloperDetailsView extends ConsumerStatefulWidget {
  const DeveloperDetailsView({super.key, required this.developerId});
  final int developerId;

  @override
  ConsumerState<DeveloperDetailsView> createState() => _DeveloperDetailsViewState();
}

class _DeveloperDetailsViewState extends ConsumerState<DeveloperDetailsView> {
  @override
  void initState() {
    super.initState();
    // "All the developer's off-plan projects" means all of them — not just
    // whichever page happened to load first — so pull in the rest of the
    // catalog once, in the background, past whatever's already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);

    return pageState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object e, StackTrace st) => const Scaffold(
        body: EmptyStateView(
          icon: Icons.error_outline,
          title: 'Developer not found',
          message: 'Please go back and try again.',
        ),
      ),
      data: (ProjectsPageState state) {
        final List<ProjectModel> projects =
            state.items.where((ProjectModel p) => p.developer.id == widget.developerId).toList();
        final String name =
            projects.isNotEmpty ? projects.first.developer.name : 'Developer';
        final DeveloperModel? developer = projects.isNotEmpty ? projects.first.developer : null;

        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: RefreshIndicator(
            onRefresh: () => ref.read(projectsProvider.notifier).loadAll(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(name, style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text(
                          state.isSearchingDeeper
                              ? '${projects.length}+ projects · still loading…'
                              : '${projects.length} project${projects.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // Shown only if this API's developer object is ever
                        // enriched beyond a bare name — see class doc.
                        if (developer != null && developer.overview != null && developer.overview!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(developer.overview!, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                        if (developer != null && developer.website.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(developer.website, style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
                if (projects.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: state.isSearchingDeeper
                        ? const PropertyGridShimmer()
                        : const EmptyStateView(
                            icon: Icons.apartment_outlined,
                            title: 'No projects found',
                            message: 'This developer has no active listings right now.',
                          ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.66,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final ProjectModel project = projects[index];
                          final Set<int> favIds =
                              favorites.maybeWhen(data: (Set<int> s) => s, orElse: () => <int>{});
                          return PropertyCard(
                            project: project,
                            isFavorite: favIds.contains(project.id),
                            onFavoriteTap: () async {
                              if (await requireAuth(context, ref)) {
                                ref.read(favoritesProvider.notifier).toggle(project.id);
                              }
                            },
                            onTap: () => context.push(RouteNames.propertyDetailsPath(project.id)),
                          );
                        },
                        childCount: projects.length,
                      ),
                    ),
                  ),
                if (state.isSearchingDeeper && projects.isNotEmpty)
                  const SliverToBoxAdapter(child: PaginationFooterLoader()),
              ],
            ),
          ),
        );
      },
    );
  }
}
