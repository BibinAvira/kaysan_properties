import '../models/paged_result.dart';
import '../models/project_model.dart';
import 'api_service.dart';

/// Data source for the live X-OPP Partner API property endpoints:
///   GET /properties/            — paginated list (summary fields only)
///   GET /properties/{id}/       — single record (summary + detail fields)
///   GET /properties/{id}/units/ — a project's individually listed units
///
/// Unlike the previous backend, these responses are flat — no
/// `{status, message, data}` wrapper — so the raw envelope is handed
/// straight to [PagedResult.fromJson] / [ProjectModel.fromDetailJson].
/// Authentication (the `X-API-Key` header) and error mapping (401/404/429
/// → [ApiException]) are handled by [ApiService].
class ProjectsService {
  ProjectsService(this._api);

  final ApiService _api;

  Future<PagedResult<ProjectModel>> fetchProjectsPage({int page = 1}) async {
    final Map<String, dynamic> envelope = await _api.get(
      '/properties/',
      queryParameters: <String, dynamic>{'page': page},
    );
    return PagedResult<ProjectModel>.fromJson(envelope, ProjectModel.fromListJson);
  }

  /// Follows a full `next` URL returned by a previous page — used by
  /// pagination controllers instead of reconstructing `?page=N` by hand,
  /// since the server-given URL is guaranteed correct.
  Future<PagedResult<ProjectModel>> fetchProjectsByUrl(String url) async {
    final Map<String, dynamic> envelope = await _api.getAbsolute(url);
    return PagedResult<ProjectModel>.fromJson(envelope, ProjectModel.fromListJson);
  }

  Future<ProjectModel> fetchProjectById(int id) async {
    final Map<String, dynamic> envelope = await _api.get('/properties/$id/');
    return ProjectModel.fromDetailJson(envelope);
  }

  /// A project's individually listed units (unit number, price, area,
  /// status, …). Fetched separately from the detail record since it's its
  /// own paginated endpoint; [pageSize] defaults to the API's max (100) so
  /// one call covers the vast majority of projects.
  Future<PagedResult<PropertyUnitModel>> fetchPropertyUnits(
    int id, {
    int page = 1,
    int pageSize = 100,
  }) async {
    final Map<String, dynamic> envelope = await _api.get(
      '/properties/$id/units/',
      queryParameters: <String, dynamic>{'page': page, 'page_size': pageSize},
    );
    return PagedResult<PropertyUnitModel>.fromJson(envelope, PropertyUnitModel.fromJson);
  }
}
