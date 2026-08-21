import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Favorites tab — every project the user has bookmarked, persisted
/// locally via `FavoritesRepository` and hydrated to full [ProjectModel]s
/// (with individual fetches for any not already loaded elsewhere) via
/// [favoriteProjectsProvider].
class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectModel>> favoritesAsync = ref.watch(favoriteProjectsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: favoritesAsync.when(
        loading: () => const PropertyGridShimmer(itemCount: 4),
        error: (Object e, StackTrace st) => EmptyStateView(
          icon: Icons.error_outline,
          title: 'Could not load favorites',
          message: 'Please check your connection and try again.',
          actionLabel: 'Retry',
          onActionTap: () => ref.invalidate(favoriteProjectsProvider),
        ),
        data: (List<ProjectModel> favProjects) {
          if (favProjects.isEmpty) {
            return EmptyStateView(
              icon: Icons.favorite_border,
              title: 'No favorites yet',
              message: 'Tap the heart icon on any property to save it here.',
              actionLabel: 'Browse Listings',
              onActionTap: () => context.push(RouteNames.listings),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.66,
            ),
            itemCount: favProjects.length,
            itemBuilder: (BuildContext context, int index) {
              final ProjectModel project = favProjects[index];
              return PropertyCard(
                project: project,
                isFavorite: true,
                onFavoriteTap: () => ref.read(favoritesProvider.notifier).toggle(project.id),
                onTap: () => context.push(RouteNames.propertyDetailsPath(project.id)),
              );
            },
          );
        },
      ),
    );
  }
}
