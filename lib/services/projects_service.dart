import '../models/paged_result.dart';
import '../models/project_model.dart';
import 'api_exception.dart';
import 'api_service.dart';

/// Data source for the live property list/detail endpoints:
///   GET /properties/       — paginated list (summary fields only)
///   GET /property/{id}/    — single record (summary + detail fields)
///
/// Both endpoints wrap their payload in `{status, message, data, errors}`
/// (list) or `{status, message, data, error}` (detail — singular key, an
/// API inconsistency handled defensively here rather than assumed away).
class ProjectsService {
  ProjectsService(this._api);

  final ApiService _api;

  Future<PagedResult<ProjectModel>> fetchProjectsPage({int page = 1}) async {
    final Map<String, dynamic> envelope = await _api.get(
      '/properties/',
      queryParameters: <String, dynamic>{'page': page},
    );
    final Map<String, dynamic> data = _unwrap(envelope);
    return PagedResult<ProjectModel>.fromJson(data, ProjectModel.fromListJson);
  }

  /// Follows a full `next_page_url` returned by a previous page — used by
  /// pagination controllers instead of reconstructing `?page=N` by hand,
  /// since the server-given URL is guaranteed correct.
  Future<PagedResult<ProjectModel>> fetchProjectsByUrl(String url) async {
    final Map<String, dynamic> envelope = await _api.getAbsolute(url);
    final Map<String, dynamic> data = _unwrap(envelope);
    return PagedResult<ProjectModel>.fromJson(data, ProjectModel.fromListJson);
  }

  Future<ProjectModel> fetchProjectById(int id) async {
    final Map<String, dynamic> envelope = await _api.get('/property/$id/');
    final Map<String, dynamic> data = _unwrap(envelope);
    return ProjectModel.fromDetailJson(data);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> envelope) {
    final bool ok = envelope['status'] as bool? ?? true;
    if (!ok) {
      final String message = envelope['message'] as String? ?? 'The request was not successful.';
      throw ApiException(ApiExceptionType.server, message);
    }
    return envelope['data'] as Map<String, dynamic>? ?? <String, dynamic>{};
  }
}
