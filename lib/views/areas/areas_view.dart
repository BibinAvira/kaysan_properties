import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../core/theme/app_colors.dart';
import '../../models/project_model.dart';
import '../../models/supporting_models.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/projects_provider.dart';
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
            return const EmptyStateView(icon: Icons.map_outlined, title: 'No areas yet', message: 'Check back soon.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 14),
            itemBuilder: (BuildContext context, int index) {
              final AreaModel area = list[index];
              return GestureDetector(
                onTap: () => context.push(RouteNames.areaDetailsPath(area.districtId)),
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
                              colors: <Color>[Colors.transparent, Colors.black.withValues(alpha: 0.75)],
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
                              Text(area.name, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text('${area.projectCount} Projects', style: const TextStyle(color: AppColors.goldLight, fontSize: 12)),
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

  @override
  Widget build(BuildContext context) {
    final AsyncValue<ProjectsPageState> pageState = ref.watch(projectsProvider);
    final AsyncValue<Set<int>> favorites = ref.watch(favoritesProvider);

    return pageState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object e, StackTrace st) => const Scaffold(
        body: EmptyStateView(icon: Icons.error_outline, title: 'Area not found', message: 'Please go back and try again.'),
      ),
      data: (ProjectsPageState state) {
        final List<ProjectModel> inArea =
            state.items.where((ProjectModel p) => p.district.id == widget.districtId).toList();
        final String areaName = inArea.isNotEmpty ? inArea.first.district.name.display : 'Area';

        return Scaffold(
          appBar: AppBar(title: Text(areaName)),
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
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.66,
                    ),
                    itemCount: inArea.length,
                    itemBuilder: (BuildContext context, int index) {
                      final ProjectModel project = inArea[index];
                      final Set<int> favIds = favorites.maybeWhen(data: (Set<int> s) => s, orElse: () => <int>{});
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
                  ),
          ),
        );
      },
    );
  }
}
