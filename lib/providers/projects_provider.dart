import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paged_result.dart';
import '../models/project_model.dart';
import 'di_providers.dart';

/// State for the paginated property list: everything loaded so far, plus
/// enough bookkeeping to drive infinite scroll (whether another page
/// exists, and whether one is currently being fetched).
class ProjectsPageState {
  const ProjectsPageState({
    this.items = const <ProjectModel>[],
    this.nextPageUrl,
    this.isLoadingMore = false,
    this.totalCount = 0,
  });

  final List<ProjectModel> items;
  final String? nextPageUrl;
  final bool isLoadingMore;
  final int totalCount;

  bool get hasMore => nextPageUrl != null;

  ProjectsPageState copyWith({
    List<ProjectModel>? items,
    String? nextPageUrl,
    bool clearNextPage = false,
    bool? isLoadingMore,
    int? totalCount,
  }) {
    return ProjectsPageState(
      items: items ?? this.items,
      nextPageUrl: clearNextPage ? null : (nextPageUrl ?? this.nextPageUrl),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
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
  return ref.watch(projectsRepositoryProvider).getById(id, cached: cached);
});
