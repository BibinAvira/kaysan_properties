/// Uniform exception surface for the whole networking stack. Repositories
/// and providers catch this single type rather than raw DioException, so
/// the UI layer only ever needs to branch on [ApiExceptionType].
class ApiException implements Exception {
  const ApiException(this.type, this.message, {this.statusCode});

  final ApiExceptionType type;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($type, $message)';
}

enum ApiExceptionType {
  network,
  timeout,
  server,
  badRequest,
  unauthorized,
  notFound,
  cancelled,
  unknown,
}
