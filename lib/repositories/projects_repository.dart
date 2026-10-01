import 'package:flutter/foundation.dart';
import '../models/paged_result.dart';
import '../models/project_model.dart';
import '../services/api_exception.dart';
import '../services/projects_service.dart';

/// Search/filter criteria for the Listings/Search screens.
///
/// [query] is sent to the server as a real `search=` param (see
/// [ProjectsRepository.searchProjects]) so results aren't limited to
/// whatever pages of the general feed happen to already be loaded — Reelly
/// doesn't document reliable server-side filtering by district/developer
/// (live testing showed those params being silently ignored), so
/// [districtId]/[developerId]/[minPrice]/[maxPrice] all narrow down
/// whatever set of projects was fetched via [applyFilter] instead;
/// [FilteredProjectsController] loads the full catalog first whenever one
/// of those facets is set, so picking a district/developer still searches
/// everything rather than just the first loaded page.
class ProjectFilter {
  const ProjectFilter({
    this.query = '',
    this.debouncedQuery = '',
    this.districtId,
    this.districtName,
    this.developerId,
    this.developerName,
    this.region,
    this.areaId,
    this.areaName,
    this.statusCode,
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
  final String? districtName;
  final int? developerId;
  final String? developerName;

  /// One of [uaeRegions]. Filtered server-side (`region=`), unlike
  /// district/price — see [FilteredProjectsController].
  final String? region;

  /// A Reelly `/districts` id (e.g. 187 = Business Bay), picked from Home's
  /// area shortcuts. Filtered server-side (`districts=`) — unlike
  /// [districtId], which is the filter sheet's client-side area pick.
  final int? areaId;
  final String? areaName;

  /// The Projects page's All / Off-Plan / Ready tab, as
  /// [ProjectModel.propertyStatusCode]: 1 = Ready, 2 = Off-Plan, null = all.
  /// Filtered server-side (`status=`).
  final int? statusCode;
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
    String? region,
    int? areaId,
    String? areaName,
    int? statusCode,
    double? minPrice,
    double? maxPrice,
    ProjectSort? sort,
    bool clearDistrict = false,
    bool clearDeveloper = false,
    bool clearRegion = false,
    bool clearArea = false,
    bool clearStatus = false,
    bool clearPrice = false,
  }) {
    return ProjectFilter(
      query: query ?? this.query,
      debouncedQuery: debouncedQuery ?? this.debouncedQuery,
      districtId: clearDistrict ? null : (districtId ?? this.districtId),
      districtName: clearDistrict ? null : (districtName ?? this.districtName),
      developerId: clearDeveloper ? null : (developerId ?? this.developerId),
      developerName: clearDeveloper ? null : (developerName ?? this.developerName),
      region: clearRegion ? null : (region ?? this.region),
      areaId: clearArea ? null : (areaId ?? this.areaId),
      areaName: clearArea ? null : (areaName ?? this.areaName),
      statusCode: clearStatus ? null : (statusCode ?? this.statusCode),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters =>
      districtId != null ||
      developerId != null ||
      region != null ||
      areaId != null ||
      minPrice != null ||
      maxPrice != null;

  /// Whether [debouncedQuery] should be resolved against the server (via
  /// [ProjectsRepository.searchProjects]) rather than just the general
  /// feed already loaded into [ProjectsController].
  bool get hasServerSearch => debouncedQuery.trim().isNotEmpty;

  /// Whether a facet the server itself filters on ([region], [areaId]) is
  /// set — see [FilteredProjectsController.isServerPaged].
  bool get hasServerFacet =>
      region != null ||
      areaId != null ||
      developerId != null ||
      sort != ProjectSort.recommended ||
      statusCode != null ||
      minPrice != null ||
      maxPrice != null;
}

/// No handover-date sort: Reelly can't order by handover, so it could only
/// sort the pages already loaded (and put long-past dates first).
enum ProjectSort { recommended, priceLowToHigh, priceHighToLow }

/// Region filter options — the seven UAE emirates, spelled the way Reelly's
/// `region=` param matches them (e.g. "Fujairah", not `/regions`' own
/// "Al Fujairah", which matches nothing).
const List<String> uaeRegions = <String>[
  'Dubai',
  'Abu Dhabi',
  'Sharjah',
  'Ras Al Khaimah',
  'Ajman',
  'Umm Al Quwain',
  'Fujairah',
];

/// The last Region chip: every project outside the UAE (Bali, Oman,
/// Saudi Arabia, …). Sent as `countries=` — see [ProjectsService].
const String internationalRegion = 'International';

/// Region chips in display order: the emirates, then [internationalRegion].
const List<String> regionOptions = <String>[...uaeRegions, internationalRegion];

/// Reelly's country id for the United Arab Emirates.
const int uaeCountryId = 219;

class ProjectsRepository {
  ProjectsRepository(this._service);

  final ProjectsService _service;

  /// Cached name→[DeveloperModel] directory, fetched once from
  /// `/developers` (a single unpaginated ~800-entry array) and reused for
  /// every project parsed afterwards, so each project can resolve a real
  /// developer id/logo/contact-info instead of a name-only placeholder —
  /// see [DeveloperModel.placeholder]. Refreshed only on cold start/explicit
  /// [refreshDeveloperDirectory]; the directory changes rarely enough that
  /// re-fetching it on every project page would be wasted requests.
  Future<Map<String, DeveloperModel>>? _developerDirectory;

  Future<Map<String, DeveloperModel>> _developers() {
    return _developerDirectory ??= _service.fetchAllDevelopers().then(
        (List<DeveloperModel> list) => <String, DeveloperModel>{
              for (final DeveloperModel d in list) d.name: d,
            });
  }

  Future<List<AreaRef>>? _areaDirectory;

  /// Reelly's full area list, fetched once and cached — the filter sheet's
  /// Area picker.
  Future<List<AreaRef>> getAllAreas() =>
      _areaDirectory ??= _service.fetchDistricts();

  /// The full developer directory, backing the Home "Developers" row and
  /// the Listings filter sheet's developer chips.
  Future<List<DeveloperModel>> getAllDevelopers() async =>
      (await _developers()).values.toList();

  void refreshDeveloperDirectory() {
    _developerDirectory = null;
  }

  Future<PagedResult<ProjectModel>> getFirstPage() async =>
      _withoutStaleOffPlan(await _fetchPage(offset: 0));

  Future<PagedResult<ProjectModel>> getNextPage(String nextPageUrl) async {
    final Map<String, DeveloperModel> developers = await _developers();
    final Map<String, dynamic> envelope =
        await _service.fetchProjectsByUrlRaw(nextPageUrl);
    return _withoutStaleOffPlan(_parsePage(envelope, developers));
  }

  /// The search box: "project, area or developer". Reelly's own `search=`
  /// matches project *names* only ("Emaar" finds 2 of Emaar's 156
  /// projects), so this also looks the text up in the developer and area
  /// directories and fetches the best matches' projects directly, merging
  /// everything without duplicates. Every request carries [filter]'s
  /// server-side facets (tab, region, area, developer, price), so e.g.
  /// "Marina" on the Ready tab only fetches Ready projects. Each source is
  /// capped at [maxPagesPerSource] pages of 100.
  Future<List<ProjectModel>> searchCatalog(
    String query,
    ProjectFilter filter, {
    int maxMatchesPerKind = 5,
    int maxPagesPerSource = 3,
  }) async {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return <ProjectModel>[];

    // Exact names first, then names starting with the text, then shortest.
    int rank(String name) {
      final String n = name.toLowerCase();
      if (n == q) return 0;
      if (n.startsWith(q)) return 1;
      return 2;
    }

    int byRelevance(String a, String b) {
      final int r = rank(a).compareTo(rank(b));
      return r != 0 ? r : a.length.compareTo(b.length);
    }

    final List<DeveloperModel> developers = (await _developers())
        .values
        .where((DeveloperModel d) => d.name.toLowerCase().contains(q))
        .toList()
      ..sort((DeveloperModel a, DeveloperModel b) => byRelevance(a.name, b.name));
    final List<AreaRef> areas = (await getAllAreas())
        .where((AreaRef a) => a.name.toLowerCase().contains(q))
        .toList()
      ..sort((AreaRef a, AreaRef b) => byRelevance(a.name, b.name));

    Future<List<ProjectModel>> collect({
      String? search,
      int? developerId,
      int? districtId,
    }) async {
      try {
        PagedResult<ProjectModel> page = await getServerFilteredFirstPage(
          search: search,
          region: filter.region,
          districtId: districtId ?? filter.areaId,
          developerId: developerId ?? filter.developerId,
          minPrice: filter.minPrice,
          maxPrice: filter.maxPrice,
          statusCode: filter.statusCode,
          sort: filter.sort,
        );
        final List<ProjectModel> items = <ProjectModel>[...page.items];
        for (int i = 1; i < maxPagesPerSource && page.nextPageUrl != null; i++) {
          page = await getNextPage(page.nextPageUrl!);
          items.addAll(page.items);
        }
        return items;
      } on Exception {
        // One failed source shouldn't sink the whole search.
        return <ProjectModel>[];
      }
    }

    final List<List<ProjectModel>> sources =
        await Future.wait(<Future<List<ProjectModel>>>[
      collect(search: query.trim()),
      // A developer/area already picked in the filter wins over a
      // text match of a different one.
      if (filter.developerId == null)
        for (final DeveloperModel d in developers.take(maxMatchesPerKind))
          collect(developerId: d.id),
      if (filter.areaId == null)
        for (final AreaRef a in areas.take(maxMatchesPerKind))
          collect(districtId: a.id),
    ]);
    final Map<int, ProjectModel> merged = <int, ProjectModel>{};
    for (final List<ProjectModel> source in sources) {
      for (final ProjectModel p in source) {
        merged.putIfAbsent(p.id, () => p);
      }
    }
    return merged.values.toList();
  }

  /// Server-side free-text search — used instead of paging through (and
  /// stopping at the first match within) the general feed, so a match
  /// anywhere in the ~2000-project catalog is found regardless of paging.
  /// [pageSize] is generous enough to cover the vast majority of single
  /// search results in one request.
  Future<PagedResult<ProjectModel>> searchProjects({
    String? query,
    int pageSize = 100,
  }) async =>
      _withoutStaleOffPlan(await _fetchPage(offset: 0, limit: pageSize, search: query));

  /// Every project by one developer, filtered server-side — a page or two
  /// even for the largest developers, instead of paging through the whole
  /// ~2000-project catalog and filtering on-device.
  Future<List<ProjectModel>> getProjectsByDeveloper(int developerId) async {
    final List<ProjectModel> all = <ProjectModel>[];
    PagedResult<ProjectModel> page =
        await _fetchPage(offset: 0, developerId: developerId);
    all.addAll(page.items);
    while (page.nextPageUrl != null) {
      page = await getNextPage(page.nextPageUrl!);
      all.addAll(page.items);
    }
    return all.where((ProjectModel p) => !p.isStaleOffPlan).toList();
  }

  /// First page of projects filtered server-side by [region] and/or
  /// [districtId] (and optionally [developerId]); further pages via
  /// [getNextPage].
  ///
  /// [statusCode] 1 (Ready) sends `status=completed`. 2 (Off-Plan) is two
  /// Reelly statuses and the API takes one per request, so it pages
  /// `under_construction` (all but a handful) and adds the few `presale`
  /// projects to the first page.
  Future<PagedResult<ProjectModel>> getServerFilteredFirstPage({
    String? region,
    int? districtId,
    int? developerId,
    double? minPrice,
    double? maxPrice,
    int? statusCode,
    String? search,
    ProjectSort sort = ProjectSort.recommended,
  }) async {
    // Price sorts run on the server so they cover every page, not just the
    // loaded ones. Low→High skips unpriced ("On Request") projects: the
    // server would list hundreds of them first, as price 0.
    final String? ordering = switch (sort) {
      ProjectSort.priceLowToHigh => 'min_price',
      ProjectSort.priceHighToLow => '-min_price',
      ProjectSort.recommended => null,
    };
    final double? priceFloor =
        sort == ProjectSort.priceLowToHigh ? (minPrice ?? 1) : minPrice;
    Future<PagedResult<ProjectModel>> fetch(String? status) => _fetchPage(
        offset: 0,
        search: search,
        ordering: ordering,
        region: region,
        districtId: districtId,
        developerId: developerId,
        minPrice: priceFloor,
        maxPrice: maxPrice,
        status: status);
    if (statusCode != 2) {
      return _withoutStaleOffPlan(
          await fetch(statusCode == 1 ? 'completed' : null));
    }
    final List<PagedResult<ProjectModel>> pages =
        await Future.wait(<Future<PagedResult<ProjectModel>>>[
      fetch('under_construction'),
      fetch('presale'),
    ]);
    final PagedResult<ProjectModel> main = pages[0];
    final PagedResult<ProjectModel> presale = pages[1];
    return _withoutStaleOffPlan(PagedResult<ProjectModel>(
      items: <ProjectModel>[...presale.items, ...main.items],
      count: main.count + presale.count,
      currentPage: 1,
      nextPageUrl: main.nextPageUrl,
    ));
  }

  /// A cover photo for one `/districts` area — the first of that area's
  /// projects that has one. A handful of items is plenty for this; the
  /// default 100-item page would be ~500 KB per area.
  Future<String> getAreaCover(int districtId) async {
    final PagedResult<ProjectModel> page =
        await _fetchPage(offset: 0, limit: 5, districtId: districtId);
    for (final ProjectModel p in page.items) {
      if (p.cover.isNotEmpty) return p.cover;
    }
    return '';
  }

  Future<PagedResult<ProjectModel>> _fetchPage({
    required int offset,
    int limit = 100,
    String? search,
    int? developerId,
    String? region,
    int? districtId,
    double? minPrice,
    double? maxPrice,
    String? status,
    String? ordering,
  }) async {
    final Map<String, DeveloperModel> developers = await _developers();
    final Map<String, dynamic> envelope = await _service.fetchProjectsPageRaw(
      limit: limit,
      offset: offset,
      search: search,
      developerId: developerId,
      region: region,
      districtId: districtId,
      minPrice: minPrice,
      maxPrice: maxPrice,
      status: status,
      ordering: ordering,
    );
    return _parsePage(envelope, developers);
  }

  PagedResult<ProjectModel> _parsePage(
      Map<String, dynamic> envelope, Map<String, DeveloperModel> developers) {
    final List<ProjectModel> items = <ProjectModel>[];
    for (final dynamic raw in envelope['results'] as List<dynamic>? ?? <dynamic>[]) {
      // One malformed project skips just itself — it used to throw away
      // the whole page of 100 (and stall pagination at that page).
      try {
        items.add(ProjectModel.fromListJson(raw as Map<String, dynamic>,
            developers: developers));
      } catch (e) {
        debugPrint('Skipped unparsable project ${(raw as Map?)?['id']}: $e');
      }
    }
    return PagedResult<ProjectModel>(
      items: items,
      count: envelope['count'] as int? ?? 0,
      currentPage: 1,
      nextPageUrl: envelope['next'] as String?,
    );
  }

  /// Drops any [ProjectModel.isStaleOffPlan] item from a fetched page —
  /// applied at this single choke point so Home, Listings, Search, and the
  /// client-derived Areas lists never see one, rather than re-filtering in
  /// every screen that reads [items].
  static String _regionKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

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
  /// endpoint and attaches them — a failure there (e.g. no Enterprise-tier
  /// access to `/projects/{id}/units`) doesn't fail the whole detail load,
  /// since units are supplementary to the rest of the page.
  Future<ProjectModel> getById(int id, {ProjectModel? cached}) async {
    final Map<String, DeveloperModel> developers = await _developers();
    final Map<String, dynamic> json = await _service.fetchProjectByIdRaw(id);
    final ProjectModel detail =
        ProjectModel.fromDetailJson(json, developers: developers);
    final ProjectModel merged = cached != null ? cached.mergeDetail(detail) : detail;
    try {
      final List<PropertyUnitModel> units = await _service.fetchPropertyUnits(id);
      return merged.withPropertyUnits(units);
    } on ApiException {
      return merged;
    }
  }

  /// Applies search text, facet filters and sort order over an
  /// already-fetched (partial) list. Pure/synchronous so providers can
  /// re-run it on every UI-driven filter change without a network call.
  ///
  /// [skipQueryMatch] lets a caller bypass this narrower text check
  /// entirely for a [source] it already trusts is correctly matched.
  /// [FilteredProjectsController] does *not* set it for server search
  /// results — the server's `search=` also matches free-text description
  /// content, which produces irrelevant results, so this title/city/
  /// district/developer-only check is re-run on top to drop anything that
  /// only matched on description.
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
          p.city.name.display.toLowerCase().contains(q) ||
          p.district.name.display.toLowerCase().contains(q) ||
          p.developer.name.toLowerCase().contains(q));
    }
    if (filter.districtId != null) {
      result = result.where((ProjectModel p) => p.district.id == filter.districtId);
    }
    if (filter.statusCode != null) {
      result = result
          .where((ProjectModel p) => p.propertyStatusCode == filter.statusCode);
    }
    if (filter.areaName != null) {
      final String key = _regionKey(filter.areaName!);
      result = result
          .where((ProjectModel p) => _regionKey(p.district.name.display) == key);
    }
    if (filter.region == internationalRegion) {
      result = result.where((ProjectModel p) =>
          p.countryId != null && p.countryId != uaeCountryId);
    } else if (filter.region != null) {
      // Same loose match as the server's: [ProjectModel.city] holds
      // `location.region`, spelled e.g. "Ras al-Khaimah Emirate".
      final String key = _regionKey(filter.region!);
      result = result.where(
          (ProjectModel p) => _regionKey(p.city.name.display).contains(key));
    }
    if (filter.developerId != null) {
      result = result.where((ProjectModel p) => p.developer.id == filter.developerId);
    }
    // Same rule as the server's unit_price_from/to: keep a project if any
    // of its units falls in range (its [lowPrice]–[highPrice] span overlaps
    // the filter); unpriced ("On Request") projects drop out.
    if (filter.minPrice != null || filter.maxPrice != null) {
      result = result.where((ProjectModel p) {
        if (p.lowPrice <= 0) return false;
        final double high = p.highPrice > 0 ? p.highPrice : p.lowPrice;
        return (filter.minPrice == null || high >= filter.minPrice!) &&
            (filter.maxPrice == null || p.lowPrice <= filter.maxPrice!);
      });
    }

    final List<ProjectModel> list = result.toList();
    switch (filter.sort) {
      case ProjectSort.priceLowToHigh:
        // Unpriced ("On Request", 0) last, not first.
        list.sort((ProjectModel a, ProjectModel b) {
          if ((a.lowPrice <= 0) != (b.lowPrice <= 0)) {
            return a.lowPrice <= 0 ? 1 : -1;
          }
          return a.lowPrice.compareTo(b.lowPrice);
        });
        break;
      case ProjectSort.priceHighToLow:
        list.sort((ProjectModel a, ProjectModel b) => b.lowPrice.compareTo(a.lowPrice));
        break;
      case ProjectSort.recommended:
        break;
    }
    return list;
  }
}
