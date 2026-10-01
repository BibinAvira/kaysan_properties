import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Developer profile screen: everything the API actually gives us about
/// this developer, plus every one of their projects.
///
/// Projects come from [developerProjectsProvider] (the API's server-side
/// `developer` filter — one or two requests), not by paging the whole
/// catalog. The logo/phone/overview come from the cached
/// `/developers` directory ([developersProvider]), so they show even
/// before — or without — any projects.
class DeveloperDetailsView extends ConsumerWidget {
  const DeveloperDetailsView({super.key, required this.developerId});
  final int developerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectModel>> projectsAsync =
        ref.watch(developerProjectsProvider(developerId));
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);
    final DeveloperModel? fromDirectory = ref
        .watch(developersProvider)
        .valueOrNull
        ?.where((DeveloperModel d) => d.id == developerId)
        .firstOrNull;

    return projectsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(fromDirectory?.name ?? 'Developer')),
        body: const PropertyGridShimmer(),
      ),
      error: (Object e, StackTrace st) => Scaffold(
        appBar: AppBar(title: Text(fromDirectory?.name ?? 'Developer')),
        body: const EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load projects',
          message: 'Please go back and try again.',
        ),
      ),
      data: (List<ProjectModel> projects) {
        final DeveloperModel? developer = fromDirectory ??
            (projects.isNotEmpty ? projects.first.developer : null);
        final String name = developer?.name ?? 'Developer';

        return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: RefreshIndicator(
            onRefresh: () =>
                ref.refresh(developerProjectsProvider(developerId).future),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (developer != null && developer.logo.isNotEmpty) ...<Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: AppNetworkImage(
                                  url: developer.logo, fit: BoxFit.contain),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(name, style: Theme.of(context).textTheme.displayMedium),
                        const SizedBox(height: 4),
                        Text(
                          '${projects.length} project${projects.length == 1 ? '' : 's'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        // Shown only if this API's developer object is ever
                        // enriched beyond a bare name — see class doc.
                        if (developer != null && developer.overview != null && developer.overview!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(developer.overview!, style: Theme.of(context).textTheme.bodyLarge),
                        ],
                        // No developer website/email here: enquiries go
                        // through Kaysan, not straight to the developer.
                        if (developer != null && developer.phone.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(developer.phone,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ],
                    ),
                  ),
                ),
                if (projects.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyStateView(
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
              ],
            ),
          ),
        );
      },
    );
  }
}
