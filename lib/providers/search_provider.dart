import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/paged_result.dart';
import '../models/project_model.dart';
import '../repositories/projects_repository.dart';
import 'di_providers.dart';
import 'guest_session_provider.dart';
import 'projects_provider.dart';

/// Search State: holds the current [ProjectFilter] the user has configured
/// via the search bar / filter sheet.
class ProjectFilterController extends Notifier<ProjectFilter> {
  Timer? _searchDebounce;

  @override
  ProjectFilter build() {
    ref.onDispose(() => _searchDebounce?.cancel());
    return const ProjectFilter();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
    // Guest-access data plumbing: keep the last search locally regardless
    // of login state (see guest_session_provider.dart).
    ref.read(guestActivityProvider.notifier).recordSearchQuery(query);
    // [ProjectFilter.debouncedQuery] is what actually drives the server
    // search (see FilteredProjectsController) — settling it 500ms after
    // typing stops means a network call fires once per pause, not once per
    // keystroke. Clearing the box clears it immediately, so results don't
    // linger from a delay that never gets a chance to fire.
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      state = state.copyWith(debouncedQuery: '');
      return;
    }
    _searchDebounce = Timer(
      const Duration(milliseconds: 500),
      () => state = state.copyWith(debouncedQuery: query),
    );
  }

  /// [name] is the district's exact display name — Reelly has no reliable
  /// server-side district filter (see [FilteredProjectsController]), so
  /// this is matched client-side via [ProjectsRepository.applyFilter]
  /// instead, over the full catalog once [FilteredProjectsController]
  /// loads it.
  void setDistrict(int? districtId, {String? name}) {
    state = state.copyWith(
      districtId: districtId,
      districtName: name,
      clearDistrict: districtId == null,
    );
  }

  /// [name] is the developer's exact display name — same client-side
  /// matching as [setDistrict].
  void setDeveloper(int? developerId, {String? name}) {
    state = state.copyWith(
      developerId: developerId,
      developerName: name,
      clearDeveloper: developerId == null,
    );
  }

  /// [region] is one of [regionOptions], or null for all regions.
  void setRegion(String? region) {
    state = state.copyWith(region: region, clearRegion: region == null);
  }

  /// Filters to one Reelly `/districts` area ([areaId]) server-side — the
  /// Home area shortcuts. Clears every other filter first, since tapping
  /// "Dubai Marina" should show Dubai Marina, not Dubai Marina ∩ whatever
  /// was picked last time.
  void showArea(int areaId, String name) {
    state = ProjectFilter(areaId: areaId, areaName: name);
  }

  void clearArea() => state = state.copyWith(clearArea: true);

  /// One Reelly `/districts` area (server-side), or null for any — the
  /// filter sheet's Area picker. Unlike [showArea], keeps other filters.
  void setArea(int? areaId, {String? name}) => state = state.copyWith(
      areaId: areaId, areaName: name, clearArea: areaId == null);

  /// The Projects page tab: 1 = Ready, 2 = Off-Plan, null = All.
  void setStatus(int? statusCode) => state = state.copyWith(
      statusCode: statusCode, clearStatus: statusCode == null);

  /// "Clear all" in the filter sheet: every filter off, but the search
  /// text and the Projects page tab (neither lives in the sheet) stay.
  void clearSheetFilters() => state = ProjectFilter(
        query: state.query,
        debouncedQuery: state.debouncedQuery,
        statusCode: state.statusCode,
      );

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(
        minPrice: min, maxPrice: max, clearPrice: min == null && max == null);
  }

  void setSort(ProjectSort sort) => state = state.copyWith(sort: sort);

  void clearAll() => state =
      ProjectFilter(query: state.query, debouncedQuery: state.debouncedQuery);
  void reset() => state = const ProjectFilter();
}

final NotifierProvider<ProjectFilterController, ProjectFilter>
    projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(
        ProjectFilterController.new);

/// Drives the Listings/Search screens' result list.
///
/// When [ProjectFilter.hasServerSearch] is true (free text entered), this
/// calls [ProjectsRepository.searchProjects] directly — the server matches
/// against its *entire* catalog, not just whatever pages of the general
/// feed happen to be loaded.
///
/// A district/developer pick has no reliable server-side equivalent on
/// this API (see [ProjectsRepository]'s class doc), so it instead triggers
/// [ProjectsController.loadAll] to pull in the rest of the catalog first —
/// otherwise picking e.g. a district whose projects are scattered past
/// page 1 would only ever show whichever one happened to already be
/// loaded — then narrows the now-complete feed locally via
/// [ProjectsRepository.applyFilter], same as plain price/sort filtering.
///
/// A region or Home area pick *is* filtered server-side (`region=` /
/// `districts=`, plus `developer=` if one is also picked), and paged: [loadMore] fetches the next page as
/// the list scrolls, since e.g. Dubai alone is ~1,500 projects — see
/// [isServerPaged].
class FilteredProjectsController extends AsyncNotifier<List<ProjectModel>> {
  List<ProjectModel> _serverItems = <ProjectModel>[];
  String? _serverNextUrl;
  int _serverTotal = 0;
  bool _serverLoadingMore = false;
  bool _serverPaged = false;

  /// Bumped on every [build], so a [loadMore] that finishes after the
  /// filter changed can tell its page is stale.
  int _generation = 0;

  /// Whether the current results come from a server-side region/area filter,
  /// paged via [loadMore] rather than [ProjectsController.loadMore].
  bool get isServerPaged => _serverPaged;
  bool get serverHasMore => _serverNextUrl != null;
  bool get serverIsLoadingMore => _serverLoadingMore;

  /// The server's total match count for the region/area (+ developer) filter —
  /// not capped at whatever pages have loaded so far.
  int get serverTotalCount => _serverTotal;

  @override
  Future<List<ProjectModel>> build() async {
    final ProjectFilter filter = ref.watch(projectFilterProvider);
    final ProjectsRepository repo = ref.watch(projectsRepositoryProvider);
    _generation++;
    _serverPaged = false;
    _serverNextUrl = null;
    _serverLoadingMore = false;

    if (filter.hasServerSearch) {
      // Name, developer and area matches, fetched with the active tab and
      // filters — see [ProjectsRepository.searchCatalog].
      final List<ProjectModel> found =
          await repo.searchCatalog(filter.debouncedQuery, filter);
      return repo.applyFilter(found, filter);
    }

    if (filter.hasServerFacet) {
      PagedResult<ProjectModel> page = await repo.getServerFilteredFirstPage(
          region: filter.region,
          districtId: filter.areaId,
          developerId: filter.developerId,
          minPrice: filter.minPrice,
          maxPrice: filter.maxPrice,
          statusCode: filter.statusCode,
          sort: filter.sort);
      final List<ProjectModel> items = <ProjectModel>[...page.items];
      // A district is matched client-side, so it needs the region's
      // whole result set — same reasoning as the loadAll() below.
      while (filter.districtId != null && page.nextPageUrl != null) {
        page = await repo.getNextPage(page.nextPageUrl!);
        items.addAll(page.items);
      }
      _serverItems = items;
      _serverNextUrl = page.nextPageUrl;
      _serverTotal = page.count;
      _serverPaged = true;
      return repo.applyFilter(items, filter);
    }

    if (filter.districtId != null || filter.developerId != null) {
      await ref.read(projectsProvider.notifier).loadAll();
    }

    final ProjectsPageState pageState =
        await ref.watch(projectsProvider.future);
    return repo.applyFilter(pageState.items, filter);
  }

  /// Appends the next server page of region/area results. No-op outside
  /// [isServerPaged] mode, or while a page is already loading.
  Future<void> loadMore() async {
    final String? next = _serverNextUrl;
    if (!_serverPaged || next == null || _serverLoadingMore) return;
    final int generation = _generation;
    final ProjectsRepository repo = ref.read(projectsRepositoryProvider);
    final ProjectFilter filter = ref.read(projectFilterProvider);
    _serverLoadingMore = true;
    // New list instance so listeners rebuild and show the footer loader.
    state = AsyncValue<List<ProjectModel>>.data(
        <ProjectModel>[...state.valueOrNull ?? <ProjectModel>[]]);
    PagedResult<ProjectModel>? page;
    try {
      page = await repo.getNextPage(next);
    } catch (_) {
      // Keep what's loaded; the next scroll retries this same page.
    }
    // The filter changed (build() re-ran) while this page loaded — its
    // results, and the loading flag, belong to that newer build now.
    if (generation != _generation) return;
    if (page != null) {
      _serverItems = <ProjectModel>[..._serverItems, ...page.items];
      _serverNextUrl = page.nextPageUrl;
    }
    _serverLoadingMore = false;
    state = AsyncValue<List<ProjectModel>>.data(
        repo.applyFilter(_serverItems, filter));
  }
}

final AsyncNotifierProvider<FilteredProjectsController, List<ProjectModel>>
    filteredProjectsProvider =
    AsyncNotifierProvider<FilteredProjectsController, List<ProjectModel>>(
        FilteredProjectsController.new);
