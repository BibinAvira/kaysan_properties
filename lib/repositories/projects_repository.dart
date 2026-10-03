import 'package:flutter/foundation.dart';
import '../models/paged_result.dart';
import '../models/project_model.dart';
import '../services/api_exception.dart';
import '../services/catalog_cache.dart';
import '../services/projects_service.dart';
import 'ranking_engine.dart';

/// Search/filter criteria for the Listings/Search screens, applied
/// on-device over the full cached catalogue by
/// [ProjectsRepository.applyFilter] — every facet, the search text and the
/// sort run locally, so results always cover every project and stay in
/// [RankingEngine] order.
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
    this.handoverFrom,
    this.handoverTo,
    this.sort = ProjectSort.bestMatch,
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

  /// Handover date range (inclusive, month precision — see
  /// [ProjectModel.handoverDate]). Reelly can't filter by handover, so
  /// this is matched client-side over the full catalog — see
  /// [FilteredProjectsController].
  final DateTime? handoverFrom;
  final DateTime? handoverTo;
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
    DateTime? handoverFrom,
    DateTime? handoverTo,
    ProjectSort? sort,
    bool clearDistrict = false,
    bool clearDeveloper = false,
    bool clearRegion = false,
    bool clearArea = false,
    bool clearStatus = false,
    bool clearPrice = false,
    bool clearHandover = false,
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
      handoverFrom: clearHandover ? null : (handoverFrom ?? this.handoverFrom),
      handoverTo: clearHandover ? null : (handoverTo ?? this.handoverTo),
      sort: sort ?? this.sort,
    );
  }

  bool get hasActiveFilters =>
      districtId != null ||
      developerId != null ||
      region != null ||
      areaId != null ||
      minPrice != null ||
      maxPrice != null ||
      hasHandoverFilter;

  bool get hasHandoverFilter => handoverFrom != null || handoverTo != null;
}

/// List orders. [bestMatch] — [RankingEngine]'s composite score — is the
/// default everywhere; the rest are explicit user choices, each falling
/// back to Best Match for ties. (No "Most Popular": Reelly has no views,
/// favourites or enquiry data to base it on.)
enum ProjectSort {
  bestMatch,
  newest,
  recentlyUpdated,
  priceLowToHigh,
  priceHighToLow,
  handoverSoonest,
  handoverLatest,
  largestArea,
  bedrooms,
  readyToMove,
  featured,
}

extension ProjectSortLabel on ProjectSort {
  String get label => switch (this) {
        ProjectSort.bestMatch => 'Best Match',
        ProjectSort.newest => 'Newest launches',
        ProjectSort.recentlyUpdated => 'Recently updated',
        ProjectSort.priceLowToHigh => 'Price: Low to High',
        ProjectSort.priceHighToLow => 'Price: High to Low',
        ProjectSort.handoverSoonest => 'Handover: Soonest',
        ProjectSort.handoverLatest => 'Handover: Latest',
        ProjectSort.largestArea => 'Largest area',
        ProjectSort.bedrooms => 'Most bedrooms',
        ProjectSort.readyToMove => 'Ready to move first',
        ProjectSort.featured => 'Featured developers first',
      };
}

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

/// Reelly `/developers` ids the client wants shown first: Emaar, DAMAC,
/// Sobha, Nakheel, Meraas, Ellington, Binghatti, Azizi, Danube, ALDAR.
/// A Best Match signal — see [RankingWeights.featuredDeveloper].
/// Server ordering for the first-launch preview page (see
/// [ProjectsRepository.getPreviewPage]): latest handover first, the
/// closest single-field proxy for "newest launches" Reelly can sort by.
const String previewOrdering = '-construction_end_date';

const List<int> featuredDeveloperIds = <int>[
  72, 12, 56, 75, 68, 44, 80, 38, 32, 46,
];

/// A ranked catalogue: every listable project in Best Match order, plus
/// the [engine] that scored it (reused for every later sort).
class RankedCatalog {
  const RankedCatalog({
    required this.items,
    required this.engine,
    required this.isComplete,
  });

  final List<ProjectModel> items;
  final RankingEngine engine;

  /// False for the first-launch preview page, shown while the full
  /// catalogue downloads.
  final bool isComplete;
}

class ProjectsRepository {
  ProjectsRepository(this._service, {CatalogCache? cache})
      : _cache = cache ?? CatalogCache();

  final ProjectsService _service;
  final CatalogCache _cache;

  /// Cached name→[DeveloperModel] directory, fetched once from
  /// `/developers` (a single unpaginated ~800-entry array) and reused for
  /// every project parsed afterwards, so each project can resolve a real
  /// developer id/logo/contact-info instead of a name-only placeholder —
  /// see [DeveloperModel.placeholder].
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

  /// The catalogue saved on-device by the last [downloadCatalog], ranked,
  /// or null if there is none. [isStale] tells the caller to refresh it.
  Future<({RankedCatalog catalog, bool isStale})?> readCachedCatalog() async {
    final CachedCatalog? cached = await _cache.read();
    if (cached == null || cached.projects.isEmpty) return null;
    return (
      catalog: await _rankRaw(cached.projects, isComplete: true),
      isStale: cached.isStale,
    );
  }

  /// Downloads the whole catalogue, saves it on-device and ranks it.
  Future<RankedCatalog> downloadCatalog() async {
    final List<Map<String, dynamic>> raw = await _service.fetchAllProjectsRaw();
    await _cache.write(raw);
    return _rankRaw(raw, isComplete: true);
  }

  /// One quick page (latest handover first, ranked on-device), shown on a
  /// first launch while [downloadCatalog] runs.
  Future<RankedCatalog> getPreviewPage() async {
    final Map<String, dynamic> page =
        await _service.fetchProjectsPageRaw(ordering: previewOrdering);
    final List<Map<String, dynamic>> raw =
        (page['results'] as List<dynamic>? ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
    return _rankRaw(raw, isComplete: false);
  }

  Future<RankedCatalog> _rankRaw(List<Map<String, dynamic>> raw,
      {required bool isComplete}) async {
    final Map<String, DeveloperModel> developers = await _developers();
    final Map<int, ProjectModel> byId = <int, ProjectModel>{};
    for (final Map<String, dynamic> json in raw) {
      // One malformed project skips just itself.
      try {
        final ProjectModel p =
            ProjectModel.fromListJson(json, developers: developers);
        byId[p.id] = p;
      } catch (e) {
        debugPrint('Skipped unparsable project ${json['id']}: $e');
      }
    }
    final RankingEngine engine = RankingEngine(byId.values);
    return RankedCatalog(
      items: engine.rank(byId.values),
      engine: engine,
      isComplete: isComplete,
    );
  }

  /// Every listable project by one developer, filtered server-side — used
  /// by Developer Details only until the full catalogue has loaded.
  Future<List<ProjectModel>> getProjectsByDeveloper(int developerId) async {
    final List<ProjectModel> all = <ProjectModel>[];
    PagedResult<ProjectModel> page =
        await _fetchPage(offset: 0, developerId: developerId);
    all.addAll(page.items);
    int offset = 0;
    while (page.nextPageUrl != null) {
      offset += 100;
      page = await _fetchPage(offset: offset, developerId: developerId);
      all.addAll(page.items);
    }
    return all.where(RankingEngine.isListable).toList();
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
    int? developerId,
    int? districtId,
  }) async {
    final Map<String, DeveloperModel> developers = await _developers();
    final Map<String, dynamic> envelope = await _service.fetchProjectsPageRaw(
      limit: limit,
      offset: offset,
      developerIds: developerId == null ? null : <int>[developerId],
      districtId: districtId,
    );
    final List<ProjectModel> items = <ProjectModel>[];
    for (final dynamic raw in envelope['results'] as List<dynamic>? ?? <dynamic>[]) {
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

  static String _regionKey(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');

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

  /// Narrows [source] (already Best Match ordered) by [filter]'s search
  /// text and facets, then orders it by [filter]'s sort via [engine].
  /// Pure and synchronous: it re-runs on every filter change without a
  /// network call.
  List<ProjectModel> applyFilter(
    List<ProjectModel> source,
    ProjectFilter filter,
    RankingEngine engine,
  ) {
    Iterable<ProjectModel> result = source;

    if (filter.query.trim().isNotEmpty) {
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

    // Month precision, both ends inclusive; undated projects drop out.
    if (filter.hasHandoverFilter) {
      final DateTime? from = filter.handoverFrom == null
          ? null
          : DateTime(filter.handoverFrom!.year, filter.handoverFrom!.month);
      final DateTime? to = filter.handoverTo == null
          ? null
          : DateTime(filter.handoverTo!.year, filter.handoverTo!.month);
      result = result.where((ProjectModel p) {
        final DateTime? handover = p.handoverDate;
        if (handover == null) return false;
        return (from == null || !handover.isBefore(from)) &&
            (to == null || !handover.isAfter(to));
      });
    }

    if (filter.sort == ProjectSort.bestMatch) return result.toList();
    return engine.sort(result, filter.sort);
  }
}
