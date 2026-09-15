import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paged_result.dart';
import '../models/project_model.dart';
import 'di_providers.dart';
import 'guest_session_provider.dart';

/// State for the paginated property list: everything loaded so far, plus
/// enough bookkeeping to drive infinite scroll (whether another page
/// exists, and whether one is currently being fetched).
class ProjectsPageState {
  const ProjectsPageState({
    this.items = const <ProjectModel>[],
    this.nextPageUrl,
    this.isLoadingMore = false,
    this.isSearchingDeeper = false,
    this.totalCount = 0,
  });

  final List<ProjectModel> items;
  final String? nextPageUrl;
  final bool isLoadingMore;

  /// True while [ProjectsController.loadUntilMatch] is fetching additional
  /// pages on the caller's behalf (e.g. a search/filter that found nothing
  /// in what's loaded so far) — distinct from [isLoadingMore] so the UI can
  /// show "still searching…" rather than the plain scroll-pagination
  /// footer, or an empty state, while this is happening.
  final bool isSearchingDeeper;
  final int totalCount;

  bool get hasMore => nextPageUrl != null;

  ProjectsPageState copyWith({
    List<ProjectModel>? items,
    String? nextPageUrl,
    bool clearNextPage = false,
    bool? isLoadingMore,
    bool? isSearchingDeeper,
    int? totalCount,
  }) {
    return ProjectsPageState(
      items: items ?? this.items,
      nextPageUrl: clearNextPage ? null : (nextPageUrl ?? this.nextPageUrl),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSearchingDeeper: isSearchingDeeper ?? this.isSearchingDeeper,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

/// Drives the Listings/Home screens: loads page 1 on build, and appends
/// further pages via [loadMore] as the user scrolls — following the API's
/// own `next_page_url` rather than guessing query params.
class ProjectsController extends AsyncNotifier<ProjectsPageState> {
  @override
  Future<ProjectsPageState> build() async {
    final PagedResult<ProjectModel> page = await ref.watch(projectsRepositoryProvider).getFirstPage();
    return ProjectsPageState(items: page.items, nextPageUrl: page.nextPageUrl, totalCount: page.count);
  }

  Future<void> loadMore() async {
    final ProjectsPageState? current = state.valueOrNull;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncValue<ProjectsPageState>.data(current.copyWith(isLoadingMore: true));
    try {
      final PagedResult<ProjectModel> page =
          await ref.read(projectsRepositoryProvider).getNextPage(current.nextPageUrl!);
      state = AsyncValue<ProjectsPageState>.data(
        current.copyWith(
          items: <ProjectModel>[...current.items, ...page.items],
          nextPageUrl: page.nextPageUrl,
          clearNextPage: page.nextPageUrl == null,
          isLoadingMore: false,
          totalCount: page.count,
        ),
      );
    } catch (_) {
      // Keep existing items visible; just stop showing the loading footer.
      // The user can retry by scrolling again (loadMore is idempotent).
      state = AsyncValue<ProjectsPageState>.data(current.copyWith(isLoadingMore: false));
    }
  }

  /// Keeps fetching further pages — via the same [loadMore] used for
  /// scroll-driven pagination — until [hasMatch] is true against the items
  /// loaded so far, or the catalog is exhausted (or [maxPages] extra pages
  /// have been fetched, as a safety cap against a search term that matches
  /// nothing anywhere in a ~1800-property catalog).
  ///
  /// This exists because the X-OPP API has no free-text search of its own
  /// (only `city`/`property_type`/`min_price`/`max_price`) — search and
  /// most filtering only ever run client-side over whatever pages have
  /// already been fetched, so without this, a real match sitting on page 5
  /// looks identical to "no such property" if only page 1 has loaded.
  Future<void> loadUntilMatch(
    bool Function(List<ProjectModel> items) hasMatch, {
    int maxPages = 40,
  }) async {
    if (hasMatch(state.valueOrNull?.items ?? const <ProjectModel>[])) return;

    final ProjectsPageState? initial = state.valueOrNull;
    if (initial != null) {
      state = AsyncValue<ProjectsPageState>.data(initial.copyWith(isSearchingDeeper: true));
    }
    try {
      for (int i = 0; i < maxPages; i++) {
        final ProjectsPageState? current = state.valueOrNull;
        if (current == null || hasMatch(current.items) || !current.hasMore) return;
        await loadMore();
      }
    } finally {
      final ProjectsPageState? finalState = state.valueOrNull;
      if (finalState != null) {
        state = AsyncValue<ProjectsPageState>.data(finalState.copyWith(isSearchingDeeper: false));
      }
    }
  }

  /// Fetches every remaining page (bounded by [maxPages] as a safety cap)
  /// rather than stopping at the first match — used by the Developer
  /// Details page, which needs to show *all* of that developer's projects,
  /// not just whichever one happened to be loaded first.
  Future<void> loadAll({int maxPages = 40}) async {
    final ProjectsPageState? initial = state.valueOrNull;
    if (initial == null) return;
    state = AsyncValue<ProjectsPageState>.data(initial.copyWith(isSearchingDeeper: true));
    try {
      for (int i = 0; i < maxPages; i++) {
        final ProjectsPageState? current = state.valueOrNull;
        if (current == null || !current.hasMore) return;
        await loadMore();
      }
    } finally {
      final ProjectsPageState? finalState = state.valueOrNull;
      if (finalState != null) {
        state = AsyncValue<ProjectsPageState>.data(finalState.copyWith(isSearchingDeeper: false));
      }
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue<ProjectsPageState>.loading();
    state = await AsyncValue.guard(() async {
      final PagedResult<ProjectModel> page = await ref.read(projectsRepositoryProvider).getFirstPage();
      return ProjectsPageState(items: page.items, nextPageUrl: page.nextPageUrl, totalCount: page.count);
    });
  }
}

final AsyncNotifierProvider<ProjectsController, ProjectsPageState> projectsProvider =
    AsyncNotifierProvider<ProjectsController, ProjectsPageState>(ProjectsController.new);

/// Single project lookup for the Property Details screen, keyed by id.
/// Merges with a cached list-summary (if one is available in the already
/// loaded [projectsProvider] state) so nothing known from the list view —
/// like the fuller developer profile — is lost.
final FutureProviderFamily<ProjectModel, int> projectDetailsProvider =
    FutureProvider.family<ProjectModel, int>((Ref ref, int id) async {
  final ProjectsPageState? loaded = ref.watch(projectsProvider).valueOrNull;
  ProjectModel? cached;
  if (loaded != null) {
    for (final ProjectModel p in loaded.items) {
      if (p.id == id) {
        cached = p;
        break;
      }
    }
  }
  final ProjectModel project =
      await ref.watch(projectsRepositoryProvider).getById(id, cached: cached);
  // Guest-access data plumbing: keep a local "recently viewed" trail
  // regardless of login state (see guest_session_provider.dart).
  ref.read(guestActivityProvider.notifier).recordViewed(id);
  return project;
});
