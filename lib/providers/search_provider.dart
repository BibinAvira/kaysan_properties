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

  /// [name] is the district's exact display name, sent to the server as
  /// its `district=` filter (see [ProjectsRepository.searchProjects]) —
  /// required whenever [districtId] is non-null.
  void setDistrict(int? districtId, {String? name}) {
    state = state.copyWith(
      districtId: districtId,
      districtName: name,
      clearDistrict: districtId == null,
    );
  }

  /// [name] is the developer's exact display name, sent to the server as
  /// its `developer=` filter (see [ProjectsRepository.searchProjects]) —
  /// required whenever [developerId] is non-null.
  void setDeveloper(int? developerId, {String? name}) {
    state = state.copyWith(
      developerId: developerId,
      developerName: name,
      clearDeveloper: developerId == null,
    );
  }

  void setPriceRange(double? min, double? max) {
    state = state.copyWith(minPrice: min, maxPrice: max, clearPrice: min == null && max == null);
  }

  void setSort(ProjectSort sort) => state = state.copyWith(sort: sort);

  void clearAll() => state = ProjectFilter(query: state.query, debouncedQuery: state.debouncedQuery);
  void reset() => state = const ProjectFilter();
}

final NotifierProvider<ProjectFilterController, ProjectFilter> projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(ProjectFilterController.new);

/// Drives the Listings/Search screens' result list.
///
/// When [ProjectFilter.hasServerSearch] is true (free text, a developer, or
/// a district picked), this calls [ProjectsRepository.searchProjects]
/// directly — the server matches against its *entire* catalog, not just
/// whatever pages of the general feed happen to be loaded — so e.g. a
/// district whose projects are scattered past page 1 shows all of them, not
/// just whichever one the old page-by-page scan happened to hit first.
///
/// With no active search, this falls back to the general [projectsProvider]
/// feed (so plain browsing/infinite-scroll is unaffected), narrowed by
/// whatever local-only facets (price/sort) are set via
/// [ProjectsRepository.applyFilter].
class FilteredProjectsController extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() async {
    final ProjectFilter filter = ref.watch(projectFilterProvider);
    final ProjectsRepository repo = ref.watch(projectsRepositoryProvider);

    if (filter.hasServerSearch) {
      final String query = filter.debouncedQuery.trim();
      final PagedResult<ProjectModel> page = await repo.searchProjects(
        developer: filter.developerName,
        district: filter.districtName,
        query: query.isEmpty ? null : query,
      );
      return repo.applyFilter(page.items, filter, skipQueryMatch: true);
    }

    final ProjectsPageState pageState = await ref.watch(projectsProvider.future);
    return repo.applyFilter(pageState.items, filter);
  }
}

final AsyncNotifierProvider<FilteredProjectsController, List<ProjectModel>> filteredProjectsProvider =
    AsyncNotifierProvider<FilteredProjectsController, List<ProjectModel>>(FilteredProjectsController.new);
