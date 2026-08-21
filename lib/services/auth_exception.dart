/// Error surface for the auth microservice. Unlike the generic
/// [ApiException] used by [ApiService] (which discards the response body),
/// this preserves per-field validation errors — e.g. register's
/// `{"username": ["A user with that username already exists."]}` — so a
/// form can highlight the exact field that failed, while [message] gives a
/// single human-readable string good enough for a snackbar on its own.
class AuthException implements Exception {
  const AuthException(this.message, {this.fieldErrors, this.statusCode});

  final String message;
  final Map<String, List<String>>? fieldErrors;
  final int? statusCode;

  /// First error message for a given field (e.g. 'username'), if the
  /// backend flagged that field specifically.
  String? errorFor(String field) => fieldErrors?[field]?.first;

  @override
  String toString() => message;
}
