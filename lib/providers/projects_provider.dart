import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../repositories/projects_repository.dart';
import '../repositories/ranking_engine.dart';
import 'di_providers.dart';
import 'guest_session_provider.dart';

/// The browsable catalogue: every listable project in Best Match order
/// (see [RankingEngine]), and the [engine] that ranked it.
class ProjectsPageState {
  const ProjectsPageState({
    required this.items,
    required this.engine,
    this.isLoadingCatalog = false,
  });

  final List<ProjectModel> items;
  final RankingEngine engine;

  /// True while only the first-launch preview page is shown and the full
  /// catalogue is still downloading — screens show a "loading more" state
  /// instead of a final "nothing found".
  final bool isLoadingCatalog;

  int get totalCount => items.length;
}

/// Loads the ranked catalogue, cache-first:
///  * a saved catalogue is shown immediately, and re-downloaded in the
///    background once older than [CatalogCache.maxAge];
///  * with none (first launch), a quick preview page is shown while the
///    full catalogue downloads, then swapped for it.
class ProjectsController extends AsyncNotifier<ProjectsPageState> {
  bool _downloading = false;

  @override
  Future<ProjectsPageState> build() async {
    final ProjectsRepository repo = ref.watch(projectsRepositoryProvider);
    final ({RankedCatalog catalog, bool isStale})? cached =
        await repo.readCachedCatalog();
    if (cached != null) {
      if (cached.isStale) unawaited(_downloadInBackground());
      return _stateOf(cached.catalog);
    }
    unawaited(_downloadInBackground());
    return _stateOf(await repo.getPreviewPage(), loading: true);
  }

  ProjectsPageState _stateOf(RankedCatalog c, {bool loading = false}) =>
      ProjectsPageState(
          items: c.items, engine: c.engine, isLoadingCatalog: loading);

  Future<void> _downloadInBackground() async {
    if (_downloading) return;
    _downloading = true;
    try {
      final RankedCatalog full =
          await ref.read(projectsRepositoryProvider).downloadCatalog();
      state = AsyncValue<ProjectsPageState>.data(_stateOf(full));
    } catch (e) {
      // Keep whatever is shown (cache or preview); the next launch or
      // pull-to-refresh retries.
      debugPrint('Catalogue download failed: $e');
      final ProjectsPageState? current = state.valueOrNull;
      if (current != null && current.isLoadingCatalog) {
        state = AsyncValue<ProjectsPageState>.data(ProjectsPageState(
            items: current.items, engine: current.engine));
      }
    } finally {
      _downloading = false;
    }
  }

  /// Pull-to-refresh: re-downloads the catalogue, keeping the current list
  /// on screen until it arrives.
  Future<void> refresh() async {
    final ProjectsPageState? current = state.valueOrNull;
    try {
      final RankedCatalog full =
          await ref.read(projectsRepositoryProvider).downloadCatalog();
      state = AsyncValue<ProjectsPageState>.data(_stateOf(full));
    } catch (e, st) {
      if (current == null) state = AsyncValue<ProjectsPageState>.error(e, st);
    }
  }
}

final AsyncNotifierProvider<ProjectsController, ProjectsPageState> projectsProvider =
    AsyncNotifierProvider<ProjectsController, ProjectsPageState>(ProjectsController.new);

/// Single project lookup for the Property Details screen, keyed by id.
/// Merges with the catalogue's list summary (if loaded) so nothing known
/// from the list view — like the fuller developer profile — is lost.
final FutureProviderFamily<ProjectModel, int> projectDetailsProvider =
    FutureProvider.family<ProjectModel, int>((Ref ref, int id) async {
  final ProjectsPageState? loaded = ref.watch(projectsProvider).valueOrNull;
  final ProjectModel? cached =
      loaded?.items.where((ProjectModel p) => p.id == id).firstOrNull;
  final ProjectModel project =
      await ref.watch(projectsRepositoryProvider).getById(id, cached: cached);
  // Guest-access data plumbing: keep a local "recently viewed" trail
  // regardless of login state (see guest_session_provider.dart).
  ref.read(guestActivityProvider.notifier).recordViewed(id);
  return project;
});

/// All of one developer's listable projects, in Best Match order — from
/// the catalogue once it's fully loaded, or the API's server-side
/// `developer` filter while it's still downloading.
final FutureProviderFamily<List<ProjectModel>, int> developerProjectsProvider =
    FutureProvider.family<List<ProjectModel>, int>((Ref ref, int developerId) async {
  final ProjectsPageState state = await ref.watch(projectsProvider.future);
  if (!state.isLoadingCatalog) {
    return state.items
        .where((ProjectModel p) => p.developer.id == developerId)
        .toList();
  }
  final List<ProjectModel> fetched = await ref
      .watch(projectsRepositoryProvider)
      .getProjectsByDeveloper(developerId);
  return state.engine.rank(fetched);
});
