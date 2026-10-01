import '../models/project_model.dart';
import '../repositories/projects_repository.dart'
    show internationalRegion, uaeCountryId;
import 'api_service.dart';

/// Data source for the live Reelly API property/developer endpoints:
///   GET /projects            — paginated list (summary fields only)
///   GET /projects/{id}       — single record (summary + detail fields)
///   GET /projects/{id}/units — a project's individually listed units
///                              (Enterprise-tier gated — see
///                              [ProjectsRepository.getById])
///   GET /developers          — the full developer directory, a single
///                              unpaginated array (not the `{count,
///                              results}` envelope every other list
///                              endpoint uses)
///
/// List/detail responses are returned as raw JSON rather than parsed
/// models — [ProjectModel.fromListJson]/[fromDetailJson] need the cached
/// developer directory to resolve a project's developer name into a real
/// id/logo (see [ProjectsRepository]), which only the repository holds, so
/// parsing happens there instead of here.
///
/// `preferred_currency=AED`/`preferred_area_unit=sqft` are pinned on every
/// `/projects` call so price/size values stay in the units the rest of the
/// app already assumes (Formatters, "sq.ft" labels, …) regardless of the
/// viewer's locale — Reelly supports switching these, but nothing in the
/// UI is wired to let a user actually choose yet.
class ProjectsService {
  ProjectsService(this._api);

  final ApiService _api;

  static const Map<String, String> _localeParams = <String, String>{
    'preferred_currency': 'AED',
    'preferred_area_unit': 'sqft',
  };

  /// [limit] defaults to the API's practical max page size for this
  /// catalog (100) so scrolling through the general (unfiltered) feed
  /// means far fewer round trips.
  Future<Map<String, dynamic>> fetchProjectsPageRaw({
    int limit = 100,
    int offset = 0,
    String? search,
    int? developerId,
    String? region,
    int? districtId,
    double? minPrice,
    double? maxPrice,
    String? status,
    String? ordering,
  }) {
    return _api.get(
      '/projects',
      queryParameters: <String, dynamic>{
        'limit': limit,
        'offset': offset,
        if (search != null && search.isNotEmpty) 'search': search,
        // Undocumented, but honoured server-side: takes the numeric id
        // from the `/developers` directory (not the name).
        if (developerId != null) 'developer': developerId,
        // Also undocumented: a case-insensitive name match on
        // `location.region` ("Dubai" also covers "Dubai Emirate").
        if (region != null &&
            region.isNotEmpty &&
            region != internationalRegion)
          'region': region,
        // "International": Reelly has no "not this country" filter, but
        // `countries=` takes a comma list of ids, so ask for every id but
        // the UAE's. (Ids beyond this range don't exist today.)
        if (region == internationalRegion)
          'countries': <int>[
            for (int id = 1; id <= 300; id++)
              if (id != uaeCountryId) id,
          ].join(','),
        // Also undocumented: note the plural — singular `district=` is
        // silently ignored. Takes a `/districts` directory id.
        if (districtId != null) 'districts': districtId,
        // Also undocumented: matches projects with *any* unit in range —
        // max_price >= from and min_price <= to. Unpriced projects drop out.
        if (minPrice != null) 'unit_price_from': minPrice.round(),
        if (maxPrice != null) 'unit_price_to': maxPrice.round(),
        // Also undocumented: one `construction_status` value per request
        // (completed / under_construction / presale); lists aren't accepted.
        if (status != null) 'status': status,
        // Also undocumented: `min_price` / `-min_price` sort the whole
        // result set (handover date isn't sortable).
        if (ordering != null) 'ordering': ordering,
        ..._localeParams,
      },
    );
  }

  /// Follows a full `next` URL returned by a previous page — used by
  /// pagination controllers instead of reconstructing `?offset=N` by hand,
  /// since the server-given URL is guaranteed correct.
  Future<Map<String, dynamic>> fetchProjectsByUrlRaw(String url) =>
      _api.getAbsolute(url);

  Future<Map<String, dynamic>> fetchProjectByIdRaw(int id) =>
      _api.get('/projects/$id', queryParameters: _localeParams);

  /// A project's individually listed units (unit number, price, area,
  /// status, …). Requires an Enterprise-tier Reelly subscription — a
  /// caller without that access gets a 403, mapped to
  /// [ApiExceptionType.unauthorized] by [ApiService].
  Future<List<PropertyUnitModel>> fetchPropertyUnits(int id) async {
    final Map<String, dynamic> envelope =
        await _api.get('/projects/$id/units', queryParameters: _localeParams);
    final List<dynamic> results = (envelope['results'] as List<dynamic>?) ??
        (envelope['units'] as List<dynamic>?) ??
        <dynamic>[];
    return results
        .map((dynamic e) => PropertyUnitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The full developer directory in one call — Reelly returns this as a
  /// bare JSON array (not the paginated `{count, results}` envelope every
  /// other list endpoint uses), and doesn't paginate it regardless of
  /// `limit`/`search`, so there's nothing to page through.
  /// Reelly's full area directory (`/districts`, one unpaginated array of
  /// `{id, name, description}`) — the ids `districts=` filters by.
  Future<List<AreaRef>> fetchDistricts() async {
    final List<dynamic> raw = await _api.getRawList('/districts');
    return raw
        .map((dynamic e) => e as Map<String, dynamic>)
        .where((Map<String, dynamic> j) => j['id'] is int && j['name'] is String)
        .map((Map<String, dynamic> j) => AreaRef(
              j['id'] as int,
              // Some names use a non-breaking space ("Downtown\u00a0Dubai").
              (j['name'] as String).replaceAll('\u00a0', ' ').trim(),
            ))
        .toList();
  }

  Future<List<DeveloperModel>> fetchAllDevelopers() async {
    final List<dynamic> raw = await _api.getRawList('/developers');
    return raw
        .map((dynamic e) => DeveloperModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

/// One `/districts` entry: an area's Reelly id and display name.
class AreaRef {
  const AreaRef(this.id, this.name);
  final int id;
  final String name;
}
