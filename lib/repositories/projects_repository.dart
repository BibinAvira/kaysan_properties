import '../models/paged_result.dart';
import '../models/project_model.dart';
import '../services/api_exception.dart';
import '../services/projects_service.dart';

/// Search/filter criteria for the Listings/Search screens.
///
/// [query] (free text), [developerId]/[developerName] and
/// [districtId]/[districtName] are sent to the server as real
/// `search=`/`developer=`/`district=` params (see
/// [ProjectsRepository.searchProjects]) so results aren't limited to
/// whatever pages of the general feed happen to already be loaded.
/// [minPrice]/[maxPrice] still only narrow down whatever set of projects
/// was fetched (the server-searched set when a query/developer/district is
/// active, otherwise the general feed) via [applyFilter] — the live
/// `/properties/` endpoint also supports server-side `min_price=`/
/// `max_price=`, just not wired up here yet.
class ProjectFilter {
  const ProjectFilter({
    this.query = '',
    this.debouncedQuery = '',
    this.districtId,
    this.districtName,
    this.developerId,
    this.developerName,
    this.minPrice,
    this.maxPrice,
    this.sort = ProjectSort.recommended,
  });

  final String query;

  /// [query], settled ~500ms after typing stops — see
  /// [ProjectFilterController.setQuery]. This, not [query], is what
  /// actually drives the server search, so a network call fires once per
  /// pause rather than once per keystroke.
  final String debouncedQuery;
  final int? districtId;

  /// The district's display name, exactly as returned by the API — kept
  /// alongside the synthetic [districtId] (see [ProjectModel._namedRef])
  /// specifically so it can be sent as the server's `district=` filter.
  final String? districtName;
  final int? developerId;

  /// The developer's display name, exactly as returned by the API — kept
  /// alongside the synthetic [developerId] (see [ProjectModel._developer])
  /// specifically so it can be sent as the server's `developer=` filter.
  final String? developerName;
  final double? minPrice;
  final double? maxPrice;
  final ProjectSort sort;

  ProjectFilter copyWith({
    String? query,
    String? debouncedQuery,
    int? districtId,
    String? districtName,
    int? developerId,
    String? developerName,
    double? minPrice,
    double? maxPrice,
    ProjectSort? sort,
    bool clearDistrict = false,
    bool clearDeveloper = false,
    bool clearPrice = false,
  }) {
    return ProjectFilter(
      query: query ?? this.query,
      debouncedQuery: debouncedQuery ?? this.debouncedQuery,
      districtId: clearDistrict ? null : (districtId ?? this.districtId),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      developerId: clearDeveloper ? null : (developerId ?? this.developerId),
      developerName: clearDeveloper ? null : (developerName ?? this.developerName),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters => districtId != null || developerId != null || minPrice != null || maxPrice != null;

  /// Whether [debouncedQuery]/[developerName]/[districtName] should be
  /// resolved against the server (via [ProjectsRepository.searchProjects])
  /// rather than just the general feed already loaded into
  /// [ProjectsController].
  bool get hasServerSearch =>
      debouncedQuery.trim().isNotEmpty ||
      (developerName?.isNotEmpty ?? false) ||
      (districtName?.isNotEmpty ?? false);
}

enum ProjectSort { recommended, priceLowToHigh, priceHighToLow, handoverSoonest }

class ProjectsRepository {
  ProjectsRepository(this._service);

  final ProjectsService _service;

  Future<PagedResult<ProjectModel>> getFirstPage() async =>
      _withoutStaleOffPlan(await _service.fetchProjectsPage(page: 1));

  Future<PagedResult<ProjectModel>> getNextPage(String nextPageUrl) async =>
      _withoutStaleOffPlan(await _service.fetchProjectsByUrl(nextPageUrl));

  /// Server-side search/developer/district lookup — used instead of paging
  /// through (and stopping at the first match within) the general feed, so
  /// e.g. picking a district with projects scattered past page 1 doesn't
  /// show only whichever one happened to already be loaded. [pageSize] is
  /// the API's max (100), enough to cover any single developer's or
  /// district's catalog in one request in practice (~1700 properties across
  /// ~325 developers / ~190 districts).
  Future<PagedResult<ProjectModel>> searchProjects({
    String? developer,
    String? district,
    String? query,
    int page = 1,
    int pageSize = 100,
  }) async =>
      _withoutStaleOffPlan(await _service.fetchProjectsPage(
        page: page,
        pageSize: pageSize,
        developer: developer,
        district: district,
        search: query,
      ));

  /// Drops any [ProjectModel.isStaleOffPlan] item from a fetched page —
  /// applied at this single choke point so Home, Listings, Search, and the
  /// client-derived Areas/Developers lists never see one, rather than
  /// re-filtering in every screen that reads [items].
  PagedResult<ProjectModel> _withoutStaleOffPlan(PagedResult<ProjectModel> page) {
    return PagedResult<ProjectModel>(
      items: page.items.where((ProjectModel p) => !p.isStaleOffPlan).toList(),
      count: page.count,
      currentPage: page.currentPage,
      nextPageUrl: page.nextPageUrl,
    );
  }

  /// Fetches full detail for [id]. If [cached] (a summary from the already
  /// loaded list) is supplied, the two are merged so nothing already known
  /// is lost. Also fetches the project's individual units from their own
  /// endpoint and attaches them — a failure there (e.g. an inactive
  /// project with no unit-level data) doesn't fail the whole detail load,
  /// since units are supplementary to the rest of the page.
  Future<ProjectModel> getById(int id, {ProjectModel? cached}) async {
    final ProjectModel detail = await _service.fetchProjectById(id);
    final ProjectModel merged = cached != null ? cached.mergeDetail(detail) : detail;
    try {
      final PagedResult<PropertyUnitModel> units = await _service.fetchPropertyUnits(id);
      return merged.withPropertyUnits(units.items);
    } on ApiException {
      return merged;
    }
  }

  /// Applies search text, facet filters and sort order over an
  /// already-fetched (partial) list. Pure/synchronous so providers can
  /// re-run it on every UI-driven filter change without a network call.
  ///
  /// [skipQueryMatch] is set by [FilteredProjectsController] when [source]
  /// already came back from the server's own `search=`/`developer=`
  /// filters (see [searchProjects]) — the server matches title, city,
  /// district, developer *and description*, so re-running this narrower
  /// title/district/developer-only text check on top would incorrectly drop
  /// results that only matched on city or description.
  List<ProjectModel> applyFilter(
    List<ProjectModel> source,
    ProjectFilter filter, {
    bool skipQueryMatch = false,
  }) {
    Iterable<ProjectModel> result = source;

    if (!skipQueryMatch && filter.query.trim().isNotEmpty) {
      final String q = filter.query.trim().toLowerCase();
      result = result.where((ProjectModel p) =>
          p.title.display.toLowerCase().contains(q) ||
          p.district.name.display.toLowerCase().contains(q) ||
          p.developer.name.toLowerCase().contains(q));
    }
    if (filter.districtId != null) {
      result = result.where((ProjectModel p) => p.district.id == filter.districtId);
    }
    if (filter.developerId != null) {
      result = result.where((ProjectModel p) => p.developer.id == filter.developerId);
    }
    if (filter.minPrice != null) {
      result = result.where((ProjectModel p) => p.lowPrice >= filter.minPrice!);
    }
    if (filter.maxPrice != null) {
      result = result.where((ProjectModel p) => p.lowPrice <= filter.maxPrice!);
    }

    final List<ProjectModel> list = result.toList();
    switch (filter.sort) {
      case ProjectSort.priceLowToHigh:
        list.sort((ProjectModel a, ProjectModel b) => a.lowPrice.compareTo(b.lowPrice));
        break;
      case ProjectSort.priceHighToLow:
        list.sort((ProjectModel a, ProjectModel b) => b.lowPrice.compareTo(a.lowPrice));
        break;
      case ProjectSort.handoverSoonest:
        list.sort(ProjectModel.compareHandoverSoonest);
        break;
      case ProjectSort.recommended:
        break;
    }
    return list;
  }
}
