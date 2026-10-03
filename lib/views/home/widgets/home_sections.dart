import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/guest_gate.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/project_model.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/projects_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/developer_tile.dart';
import '../../../widgets/loading_shimmer.dart';
import 'home_header.dart';
import 'top_property_card.dart';

/// Hero carousel — the top six Best Match listings (see [RankingEngine]).
/// The API has no editorial "featured" flag, so this is the ranking's
/// pick rather than a hand-curated set.
class HeroCarousel extends ConsumerWidget {
  const HeroCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);

    return pageState.when(
      loading: () => const SizedBox(
          height: 220, child: Center(child: CircularProgressIndicator())),
      error: (Object e, StackTrace st) => const SizedBox.shrink(),
      data: (ProjectsPageState state) {
        final List<ProjectModel> projects = state.items.take(6).toList();
        if (projects.isEmpty) return const SizedBox.shrink();
        return CarouselSlider.builder(
          itemCount: projects.length,
          itemBuilder: (BuildContext context, int index, int realIndex) {
            final ProjectModel project = projects[index];
            return GestureDetector(
              onTap: () =>
                  context.push(RouteNames.propertyDetailsPath(project.id)),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: AppNetworkImage(url: project.cover),
                  ),
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
                    left: 20,
                    right: 20,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          project.district.name.display,
                          style: const TextStyle(
                              color: AppColors.goldLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.title.display,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('By ${project.developer.name}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
          options: CarouselOptions(
            height: 260,
            viewportFraction: 1,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 5),
          ),
        );
      },
    );
  }
}

/// Opens Listings filtered (server-side) to one of the Home area shortcuts.
void _openHomeArea(BuildContext context, WidgetRef ref, HomeArea area) {
  ref
      .read(projectFilterProvider.notifier)
      .showArea(area.districtId, area.districtName);
  context.push(RouteNames.listings);
}

/// "Explore by Area" — a horizontal row of photo cards for [homeAreas].
/// Each photo is a real project in that area ([areaCoverProvider]).
class ExploreByAreaSection extends ConsumerWidget {
  const ExploreByAreaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Explore by Area',
          actionLabel: 'View All',
          onActionTap: () => context.push(RouteNames.areas),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: homeAreas.length,
            separatorBuilder: (BuildContext context, int index) =>
                const SizedBox(width: 10),
            itemBuilder: (BuildContext context, int index) {
              final HomeArea area = homeAreas[index];
              final String cover =
                  ref.watch(areaCoverProvider(area.districtId)).valueOrNull ??
                      '';
              return GestureDetector(
                onTap: () => _openHomeArea(context, ref, area),
                child: SizedBox(
                  width: 104,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 104,
                          height: 96,
                          child: AppNetworkImage(url: cover),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(area.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.color)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// "Popular Areas" — the first four [homeAreas] as outlined pin chips, two
/// per row.
class PopularAreasSection extends ConsumerWidget {
  const PopularAreasSection({super.key});

  static const List<String> _labels = <String>[
    'Dubai Marina',
    'Downtown Dubai',
    'JVC',
    'Business Bay',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<HomeArea> areas = homeAreas
        .where((HomeArea a) => _labels.contains(a.label))
        .toList()
      ..sort((HomeArea a, HomeArea b) =>
          _labels.indexOf(a.label).compareTo(_labels.indexOf(b.label)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: 'Popular Areas',
          actionLabel: 'View All',
          onActionTap: () => context.push(RouteNames.areas),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3.8,
          children: areas
              .map((HomeArea area) => Material(
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: theme.dividerColor),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => _openHomeArea(context, ref, area),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.location_on_outlined,
                                size: 18, color: AppColors.gold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(area.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme
                                          .textTheme.titleMedium?.color)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

/// "Top Property" — respects the All / Off-Plan / Ready tabs above it (see
/// [homeStatusFilterProvider]) and shows the single best-matching property
/// as a [TopPropertyCard] (Home-only design).
/// The API has no curated "featured" flag: this is the top Best Match
/// (see [RankingEngine]) for the selected tab.
class TopPropertySection extends ConsumerWidget {
  const TopPropertySection(
      {super.key, this.title = 'Top Property', this.take = 10});

  final String title;
  final int take;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);
    final int? statusFilter = ref.watch(homeStatusFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: title,
          actionLabel: 'View All',
          // Respects whichever Ready/Off-Plan pill is active above this
          // section — otherwise "View All" would land on the general All
          // Properties catalog regardless of the pill.
          // Opens the Projects tab on the matching All / Off-Plan / Ready tab.
          onActionTap: () {
            ref.read(projectFilterProvider.notifier).setStatus(statusFilter);
            context.go(RouteNames.listings);
          },
        ),
        pageState.when(
          loading: () => const FeaturedCardShimmer(),
          error: (Object e, StackTrace st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load projects.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          data: (ProjectsPageState state) {
            // Already in Best Match order — see [RankingEngine].
            final List<ProjectModel> matches = statusFilter == null
                ? state.items
                : state.items
                    .where((ProjectModel p) =>
                        p.propertyStatusCode == statusFilter)
                    .toList();
            if (matches.isEmpty) {
              // A status filter was just picked and nothing loaded so far
              // matches — HomeStatusFilterController.set already kicked
              // off fetching further pages; show that instead of a flat
              // "nothing here", since a match will very likely show up.
              if (state.isLoadingCatalog) return const FeaturedCardShimmer();
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('No properties match this filter yet.',
                    style: Theme.of(context).textTheme.bodyMedium),
              );
            }
            final ProjectModel project = matches.first;
            final Set<int> favIds = favorites.maybeWhen(
                data: (Set<int> s) => s, orElse: () => <int>{});
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TopPropertyCard(
                project: project,
                isFavorite: favIds.contains(project.id),
                onFavoriteTap: () async {
                  if (await requireAuth(context, ref)) {
                    ref.read(favoritesProvider.notifier).toggle(project.id);
                  }
                },
                onTap: () =>
                    context.push(RouteNames.propertyDetailsPath(project.id)),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "Developers We Work With" — a 4-column grid of logo + name cards from
/// the `/developers` directory (the client's featured developers first —
/// see [featuredDeveloperIds]). Tapping one opens that developer's page.
/// Home shows the first [_homeCount]; "See All" opens the full, searchable
/// [DevelopersView] (the directory runs to ~800 developers).
class DevelopersSection extends ConsumerStatefulWidget {
  const DevelopersSection({super.key});

  @override
  ConsumerState<DevelopersSection> createState() => _DevelopersSectionState();
}

class _DevelopersSectionState extends ConsumerState<DevelopersSection> {
  static const int _homeCount = 12;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<DeveloperModel>> developers =
        ref.watch(developersProvider);
    return developers.maybeWhen(
      data: (List<DeveloperModel> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: 'Developers We Work With',
              actionLabel: list.length > _homeCount ? 'See All' : null,
              onActionTap: list.length > _homeCount
                  ? () => context.push(RouteNames.developers)
                  : null,
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.0,
              children: list
                  .take(_homeCount)
                  .map((DeveloperModel developer) => DeveloperTile(
                        developer: developer,
                        onTap: () => context.push(
                            RouteNames.developerDetailsPath(developer.id)),
                      ))
                  .toList(),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
