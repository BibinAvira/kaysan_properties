/// Generic wrapper for the API's pagination envelope:
/// `{ count, next, previous, results: [...] }` (standard DRF-style
/// pagination, as returned by the X-OPP Partner API).
///
/// Kept generic (`PagedResult<T>`) so it can wrap any paginated resource,
/// not just properties, if the API grows more list endpoints later.
class PagedResult<T> {
  const PagedResult({
    required this.items,
    required this.count,
    required this.currentPage,
    required this.nextPageUrl,
  });

  final List<T> items;
  final int count;

  /// The API doesn't echo back a page number, only a `next`/`previous` URL
  /// pair, so this is a fixed placeholder rather than a real tracked value.
  /// Nothing currently reads it (pagination elsewhere follows [nextPageUrl]
  /// directly), but it's kept so the field doesn't disappear from under
  /// any future caller.
  final int currentPage;

  /// Full next-page URL as returned by the API (its `next` field), or null
  /// on the last page. We keep the server-given URL rather than
  /// reconstructing `?page=N+1` ourselves, since it's guaranteed correct
  /// regardless of query params the backend might attach.
  final String? nextPageUrl;

  bool get hasMore => nextPageUrl != null;

  factory PagedResult.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) itemFromJson,
  ) {
    return PagedResult<T>(
      items: (json['results'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => itemFromJson(e as Map<String, dynamic>))
          .toList(),
      count: json['count'] as int? ?? 0,
      currentPage: 1,
      nextPageUrl: json['next'] as String?,
    );
  }
}
