import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/guest_gate.dart';
import '../../core/routes/route_names.dart';
import '../../models/project_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/glass/liquid_glass.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/property_card.dart';

/// Favorites tab — every project the user has bookmarked, persisted
/// locally via `FavoritesRepository` and hydrated to full [ProjectModel]s
/// (with individual fetches for any not already loaded elsewhere) via
/// [favoriteProjectsProvider].
///
/// Saving is now an account-dependent action (see the guest-access spec),
/// so a guest's list here is always empty by construction — rather than
/// show the ordinary "no favorites yet" empty state, guests get a sign-in
/// invitation instead, per "restricted tabs should trigger authentication
/// instead of showing empty screens".
class FavoritesView extends ConsumerWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ProjectModel>> favoritesAsync = ref.watch(favoriteProjectsProvider);
    final bool loggedIn = ref.watch(isLoggedInProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: !loggedIn
          ? _GuestFavoritesPrompt(onAuthenticated: () => ref.invalidate(favoriteProjectsProvider))
          : favoritesAsync.when(
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
                onFavoriteTap: () async {
                  if (await requireAuth(context, ref)) {
                    ref.read(favoritesProvider.notifier).toggle(project.id);
                  }
                },
                onTap: () => context.push(RouteNames.propertyDetailsPath(project.id)),
              );
            },
          );
        },
      ),
    );
  }
}

/// Sign-in invitation shown in place of the Favorites tab's content for
/// guests — tapping through and successfully authenticating refreshes the
/// list immediately via [onAuthenticated].
class _GuestFavoritesPrompt extends ConsumerWidget {
  const _GuestFavoritesPrompt({required this.onAuthenticated});

  final VoidCallback onAuthenticated;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassDarkCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Center(
                child: GlassIconBadge(icon: Icons.favorite_rounded, glow: true),
              ),
              const SizedBox(height: 18),
              const Text('Sign in to see your favorites',
                  style: TextStyle(
                      color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Create an account to save properties and pick up right where you left off.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              LiquidGlassButton(
                label: 'Login / Create Account',
                icon: Icons.login_rounded,
                onTap: () async {
                  if (await requireAuth(context, ref)) onAuthenticated();
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.push(RouteNames.listings),
                style: TextButton.styleFrom(foregroundColor: Colors.white60),
                child: const Text('Continue Browsing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
