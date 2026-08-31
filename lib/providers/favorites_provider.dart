import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_models.dart';
import '../models/project_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/favorites_repository.dart';
import 'auth_provider.dart';
import 'di_providers.dart';
import 'projects_provider.dart';

/// Favorite state: the set of favorited project IDs. Local storage
/// (SharedPreferences via [FavoritesRepository]) is always the source of
/// truth the UI reads from, so favoriting works instantly and identically
/// whether or not anyone is logged in.
///
/// When a person is logged in, saves/unsaves are additionally mirrored to
/// the account via `/auth/saved-properties/` in the background (confirmed
/// live and working), and the server's list is merged in once per login.
/// Every server call stays best-effort regardless: a failure (e.g. the
/// server 500s if asked to re-save something already saved — a known
/// backend edge case) is swallowed and never affects local state or
/// surfaces to the UI, since local storage is already the source of truth
/// the person's screen reflects.
class FavoritesController extends AsyncNotifier<Set<int>> {
  int? _syncedForUserId;

  @override
  Future<Set<int>> build() async {
    final Set<int> local = await ref.watch(favoritesRepositoryProvider).getFavoriteIds();
    final UserModel? user = ref.watch(authControllerProvider).valueOrNull;

    if (user == null) {
      _syncedForUserId = null;
      return local;
    }
    if (_syncedForUserId != user.id) {
      _syncedForUserId = user.id;
      unawaited(_mergeFromServer());
    }
    return local;
  }

  bool isFavorite(int projectId) {
    return state.maybeWhen(data: (Set<int> ids) => ids.contains(projectId), orElse: () => false);
  }

  Future<void> toggle(int projectId) async {
    final FavoritesRepository repo = ref.read(favoritesRepositoryProvider);
    final Set<int> updated = await repo.toggle(projectId);
    state = AsyncValue<Set<int>>.data(updated);

    if (ref.read(authControllerProvider).valueOrNull == null) return;
    final bool nowFavorited = updated.contains(projectId);
    unawaited(_syncToServer(projectId, favorited: nowFavorited));
  }

  /// Pulls the account's server-side saved properties and folds any not
  /// already favorited locally into the local set, so favorites carry over
  /// to a new device on login. Runs once per login; errors are swallowed.
  Future<void> _mergeFromServer() async {
    try {
      final Set<int> serverIds = await ref.read(authRepositoryProvider).getSavedPropertyIds();
      if (serverIds.isEmpty) return;
      final Set<int> merged = await ref.read(favoritesRepositoryProvider).addAll(serverIds);
      state = AsyncValue<Set<int>>.data(merged);
    } catch (_) {
      // Server sync unavailable — local favorites are already the source
      // of truth, so there's nothing to recover.
    }
  }

  Future<void> _syncToServer(int projectId, {required bool favorited}) async {
    try {
      final AuthRepository repo = ref.read(authRepositoryProvider);
      if (favorited) {
        await repo.saveProperty(projectId);
      } else {
        await repo.unsaveProperty(projectId);
      }
    } catch (_) {
      // Best-effort mirror only — local state already reflects the tap.
    }
  }
}

final AsyncNotifierProvider<FavoritesController, Set<int>> favoritesProvider =
    AsyncNotifierProvider<FavoritesController, Set<int>>(FavoritesController.new);

/// Full [ProjectModel]s for every favorited ID.
///
/// Because the live property list is paginated (1700+ properties, ~10 per
/// page), a favorited project won't necessarily be among whatever pages
/// happen to be loaded elsewhere in the app. This fills the gap: anything
/// already loaded is reused as-is; anything missing is fetched
/// individually via `/property/{id}/` so the Favorites tab is always
/// complete, not just "whatever happened to be cached".
final FutureProvider<List<ProjectModel>> favoriteProjectsProvider = FutureProvider<List<ProjectModel>>((Ref ref) async {
  final Set<int> favIds = ref.watch(favoritesProvider).valueOrNull ?? <int>{};
  if (favIds.isEmpty) return <ProjectModel>[];

  final List<ProjectModel> loaded = ref.watch(projectsProvider).valueOrNull?.items ?? <ProjectModel>[];
  final Map<int, ProjectModel> byId = <int, ProjectModel>{for (final ProjectModel p in loaded) p.id: p};

  final List<int> missingIds = favIds.where((int id) => !byId.containsKey(id)).toList();
  if (missingIds.isNotEmpty) {
    final List<ProjectModel> fetched = await Future.wait(
      missingIds.map((int id) => ref.watch(projectsRepositoryProvider).getById(id)),
    );
    for (final ProjectModel p in fetched) {
      byId[p.id] = p;
    }
  }

  return favIds.map((int id) => byId[id]).whereType<ProjectModel>().toList();
});
