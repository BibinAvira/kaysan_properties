import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/guest_gate.dart';
import '../../../core/routes/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/project_model.dart';
import '../../../models/supporting_models.dart';
import '../../../providers/content_providers.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/projects_provider.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/loading_shimmer.dart';
import '../../../widgets/property_card.dart';
import 'home_header.dart';

/// Hero carousel — the newest live listings, most-recently-updated first.
/// (The API has no "featured" flag, so this uses the first page of the
/// live feed rather than a curated/editorial set.)
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
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.title.display,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('By ${project.developer.name}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 13)),
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

/// A single featured [PropertyCard] for a Home section, sourced from the
/// loaded [projectsProvider] page(s) — plus a "See all" action that opens
/// the full list. Mobile home screens show one hero item per section
/// rather than a horizontally-scrolling row, so people aren't left
/// wondering if there's more to swipe through.
class LatestProjectsSection extends ConsumerWidget {
  const LatestProjectsSection({super.key, required this.title, this.take = 10});

  final String title;
  final int take;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SectionHeader(
          title: title,
          actionLabel: 'See all',
          onActionTap: () => context.push(RouteNames.listings),
        ),
        pageState.when(
          loading: () => const FeaturedCardShimmer(),
          error: (Object e, StackTrace st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load projects.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          data: (ProjectsPageState state) {
            if (state.items.isEmpty) return const SizedBox.shrink();
            final ProjectModel project = state.items.first;
            final Set<int> favIds = favorites.maybeWhen(
                data: (Set<int> s) => s, orElse: () => <int>{});
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 320,
                child: PropertyCard(
                  project: project,
                  isFavorite: favIds.contains(project.id),
                  onFavoriteTap: () async {
                    if (await requireAuth(context, ref)) {
                      ref.read(favoritesProvider.notifier).toggle(project.id);
                    }
                  },
                  onTap: () => context
                      .push(RouteNames.propertyDetailsPath(project.id)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "Top Property" section for the redesigned Home — same underlying data
/// as [LatestProjectsSection] but respects the Ready/Off-Plan pill chips
/// above it (see [homeStatusFilterProvider]), and shows the single
/// best-matching property rather than a scrollable row.
class TopPropertySection extends ConsumerWidget {
  const TopPropertySection({super.key, this.title = 'Top Property', this.take = 10});

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
          onActionTap: () => context.push(RouteNames.listings),
        ),
        pageState.when(
          loading: () => const FeaturedCardShimmer(),
          error: (Object e, StackTrace st) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load projects.',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
          data: (ProjectsPageState state) {
            final List<ProjectModel> matches = statusFilter == null
                ? state.items
                : state.items
                    .where((ProjectModel p) => p.propertyStatusCode == statusFilter)
                    .toList();
            if (matches.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text('No properties match this filter yet.',
                    style: Theme.of(context).textTheme.bodyMedium),
              );
            }
            final ProjectModel project = matches.first;
            final Set<int> favIds = favorites.maybeWhen(
                data: (Set<int> s) => s, orElse: () => <int>{});
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 320,
                child: PropertyCard(
                  project: project,
                  isFavorite: favIds.contains(project.id),
                  onFavoriteTap: () async {
                    if (await requireAuth(context, ref)) {
                      ref.read(favoritesProvider.notifier).toggle(project.id);
                    }
                  },
                  onTap: () => context
                      .push(RouteNames.propertyDetailsPath(project.id)),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// "Developers We Work With" — derived from loaded projects, shown as a
/// wrapping grid of chips rather than a horizontal scroller so everything
/// is visible at a glance on a phone screen.
class DevelopersSection extends ConsumerWidget {
  const DevelopersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<DeveloperModel>> developers =
        ref.watch(developersProvider);
    return developers.maybeWhen(
      data: (List<DeveloperModel> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'Developers We Work With'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: list
                    .map((DeveloperModel developer) => Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            developer.name,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// "Explore Prime Locations" — derived areas (grouped by district) from
/// loaded projects.
class AreasSection extends ConsumerWidget {
  const AreasSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AreaModel>> areas = ref.watch(areasProvider);
    return areas.maybeWhen(
      data: (List<AreaModel> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: 'Explore Prime Locations',
              actionLabel: 'View more',
              onActionTap: () => context.push(RouteNames.areas),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => context
                    .push(RouteNames.areaDetailsPath(list.first.districtId)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        AppNetworkImage(url: list.first.coverImage),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: <Color>[
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.72)
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                list.first.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${list.first.projectCount} Projects',
                                style: const TextStyle(
                                    color: AppColors.goldLight, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// "Why Choose Us" three-point pitch — shown as stacked icon feature
/// cards (colored icon badge + title + description inside a rounded
/// card), the pattern mobile apps use instead of a website-style
/// checklist.
class WhyChooseSection extends StatelessWidget {
  const WhyChooseSection({super.key});

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String, String)> points = <(IconData, String, String)>[
      (
        Icons.insights_rounded,
        'Market Expertise',
        'In-depth knowledge of the Dubai real estate market, helping you find the ideal property.'
      ),
      (
        Icons.home_work_rounded,
        'Comprehensive Services',
        'From buying and selling to leasing and full property management.'
      ),
      (
        Icons.handshake_rounded,
        'Client-Centered Approach',
        'Transparent advice, personalized support, and exceptional service.'
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SectionHeader(title: 'Why Choose Us'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: points
                .map(((IconData, String, String) p) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.gold.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(p.$1, color: AppColors.gold, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(p.$2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(p.$3,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// "The Trust We've Earned" testimonials — a swipeable single-card
/// PageView with a page-dot indicator, the mobile-native pattern for
/// browsing a handful of reviews one at a time (mock-backed — no live
/// endpoint for reviews yet).
class TestimonialsSection extends ConsumerStatefulWidget {
  const TestimonialsSection({super.key});

  @override
  ConsumerState<TestimonialsSection> createState() => _TestimonialsSectionState();
}

class _TestimonialsSectionState extends ConsumerState<TestimonialsSection> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<TestimonialModel>> testimonials =
        ref.watch(testimonialsProvider);
    return testimonials.maybeWhen(
      data: (List<TestimonialModel> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SectionHeader(title: 'The Trust We\'ve Earned'),
            SizedBox(
              height: 176,
              child: PageView.builder(
                controller: _controller,
                itemCount: list.length,
                onPageChanged: (int index) => setState(() => _page = index),
                itemBuilder: (BuildContext context, int index) {
                  final TestimonialModel t = list[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.primaryNavy.withValues(alpha: 0.08),
                                child: Text(
                                  t.author.isNotEmpty ? t.author[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                      color: AppColors.primaryNavy,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(t.author,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(fontWeight: FontWeight.w700)),
                                    Row(
                                      children: List<Widget>.generate(
                                        t.rating,
                                        (int i) => const Icon(Icons.star,
                                            size: 13, color: AppColors.gold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(t.postedAgo,
                                  style: Theme.of(context).textTheme.labelSmall),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Text(
                              t.review,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (list.length > 1) ...<Widget>[
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(list.length, (int index) {
                    final bool active = index == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.gold
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// "Latest Blogs" preview section (mock-backed — no live endpoint yet) —
/// rounded card rows with a thumbnail, title, and a small read-time pill
/// instead of a plain default ListTile.
class BlogsSection extends ConsumerWidget {
  const BlogsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BlogModel>> blogs = ref.watch(blogsProvider);
    return blogs.maybeWhen(
      data: (List<BlogModel> list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SectionHeader(
              title: 'Latest Blogs',
              actionLabel: 'View all',
              onActionTap: () => context.push(RouteNames.blogs),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: list
                    .take(3)
                    .map((BlogModel blog) => _BlogCard(blog: blog))
                    .toList(),
              ),
            ),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.blog});
  final BlogModel blog;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(RouteNames.blogDetailsPath(blog.id)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AppNetworkImage(url: blog.coverImage),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      blog.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Icon(Icons.schedule_rounded,
                            size: 13, color: AppColors.textSecondaryLight),
                        const SizedBox(width: 4),
                        Text('${blog.readMinutes} Min Read',
                            style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            Formatters.fullDate(blog.publishedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
