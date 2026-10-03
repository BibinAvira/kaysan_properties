import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Handover date range from the filter sheet; both null clears it.
  void setHandoverRange(DateTime? from, DateTime? to) => state = state.copyWith(
      handoverFrom: from,
      handoverTo: to,
      clearHandover: from == null && to == null);

  void clearAll() => state =
      ProjectFilter(query: state.query, debouncedQuery: state.debouncedQuery);
  void reset() => state = const ProjectFilter();
}

final NotifierProvider<ProjectFilterController, ProjectFilter>
    projectFilterProvider =
    NotifierProvider<ProjectFilterController, ProjectFilter>(
        ProjectFilterController.new);

/// The Listings/Search result list: the ranked catalogue narrowed and
/// ordered by [projectFilterProvider], entirely on-device (see
/// [ProjectsRepository.applyFilter]) — so every filter covers every
/// project and re-runs instantly.
final FutureProvider<List<ProjectModel>> filteredProjectsProvider =
    FutureProvider<List<ProjectModel>>((Ref ref) async {
  final ProjectFilter filter = ref.watch(projectFilterProvider);
  final ProjectsPageState catalog = await ref.watch(projectsProvider.future);
  return ref
      .watch(projectsRepositoryProvider)
      .applyFilter(catalog.items, filter, catalog.engine);
});
