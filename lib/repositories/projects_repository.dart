import '../models/paged_result.dart';
import '../models/project_model.dart';
import '../services/api_exception.dart';
import '../services/projects_service.dart';

/// Search/filter criteria applied over the project pages loaded so far.
///
/// Note: the live `/properties/` list endpoint doesn't return bedroom
/// count or a unit-type facet (those only appear per-project in
/// `grouped_apartments` on the detail endpoint), so — unlike an
/// API that returns full facets up front — this filter only covers what's
/// actually queryable from list data: free-text search, area (district),
/// developer, and price range.
class ProjectFilter {
  const ProjectFilter({
    this.query = '',
    this.districtId,
    this.developerId,
    this.minPrice,
    this.maxPrice,
    this.sort = ProjectSort.recommended,
  });

  final String query;
  final int? districtId;
  final int? developerId;
  final double? minPrice;
  final double? maxPrice;
  final ProjectSort sort;

  ProjectFilter copyWith({
    String? query,
    int? districtId,
    int? developerId,
    double? minPrice,
    double? maxPrice,
    ProjectSort? sort,
    bool clearDistrict = false,
    bool clearDeveloper = false,
    bool clearPrice = false,
  }) {
    return ProjectFilter(
      query: query ?? this.query,
      districtId: clearDistrict ? null : (districtId ?? this.districtId),
      developerId: clearDeveloper ? null : (developerId ?? this.developerId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters => districtId != null || developerId != null || minPrice != null || maxPrice != null;
}

enum ProjectSort { recommended, priceLowToHigh, priceHighToLow, handoverSoonest }

class ProjectsRepository {
  ProjectsRepository(this._service);

  final ProjectsService _service;

  Future<PagedResult<ProjectModel>> getFirstPage() => _service.fetchProjectsPage(page: 1);

  Future<PagedResult<ProjectModel>> getNextPage(String nextPageUrl) =>
      _service.fetchProjectsByUrl(nextPageUrl);

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
  List<ProjectModel> applyFilter(List<ProjectModel> source, ProjectFilter filter) {
    Iterable<ProjectModel> result = source;

    if (filter.query.trim().isNotEmpty) {
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
