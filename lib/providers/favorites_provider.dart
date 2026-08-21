import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../repositories/favorites_repository.dart';
import 'di_providers.dart';
import 'projects_provider.dart';

/// Favorite State: the set of favorited project IDs, persisted locally.
class FavoritesController extends AsyncNotifier<Set<int>> {
  @override
  Future<Set<int>> build() {
    return ref.watch(favoritesRepositoryProvider).getFavoriteIds();
  }

  bool isFavorite(int projectId) {
    return state.maybeWhen(data: (Set<int> ids) => ids.contains(projectId), orElse: () => false);
  }

  Future<void> toggle(int projectId) async {
    final FavoritesRepository repo = ref.read(favoritesRepositoryProvider);
    final Set<int> updated = await repo.toggle(projectId);
    state = AsyncValue<Set<int>>.data(updated);
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
