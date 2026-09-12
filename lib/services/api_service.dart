import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import 'api_exception.dart';

/// Thin wrapper around [Dio] providing:
///  - base URL + timeout configuration
///  - debug-only request/response logging
///  - a bounded automatic retry for transient network/5xx failures
///  - translation of DioException into the app's own [ApiException]
///
/// Repositories depend on this service, never on Dio directly, so swapping
/// HTTP clients later doesn't ripple through the codebase.
class ApiService {
  ApiService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout:
                const Duration(seconds: AppConstants.apiTimeoutSeconds),
            receiveTimeout:
                const Duration(seconds: AppConstants.apiTimeoutSeconds),
            headers: <String, String>{
              'Accept': 'application/json',
              'X-API-Key': AppConfig.xoppApiKey,
            },
          ),
        ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (Object obj) => debugPrint('[API] $obj'),
        ),
      );
    }
  }

  final Dio _dio;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _withRetry(() async {
      final Response<dynamic> response =
          await _dio.get<dynamic>(path, queryParameters: queryParameters);
      return response.data as Map<String, dynamic>;
    });
  }

  /// Fetches a full absolute URL (e.g. a `next_page_url` returned by a
  /// paginated list endpoint) rather than a path relative to [baseUrl].
  /// Dio treats a scheme-qualified path as absolute and ignores baseUrl
  /// for it, so this is functionally the same call as [get] — kept as a
  /// separate named method purely so call sites are self-documenting
  /// about which kind of URL they're passing.
  Future<Map<String, dynamic>> getAbsolute(String url) {
    return _withRetry(() async {
      final Response<dynamic> response = await _dio.get<dynamic>(url);
      return response.data as Map<String, dynamic>;
    });
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) {
    return _withRetry(() async {
      final Response<dynamic> response =
          await _dio.post<dynamic>(path, data: data);
      return response.data as Map<String, dynamic>;
    });
  }

  Future<T> _withRetry<T>(Future<T> Function() action) async {
    int attempt = 0;
    while (true) {
      try {
        return await action();
      } on DioException catch (e) {
        final bool retriable = _isRetriable(e);
        if (!retriable || attempt >= AppConstants.apiRetryCount) {
          throw _mapError(e);
        }
        attempt++;
        await Future<void>.delayed(Duration(milliseconds: 400 * attempt));
      }
    }
  }

  bool _isRetriable(DioException e) {
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode != null && e.response!.statusCode! >= 500);
  }

  ApiException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          ApiExceptionType.timeout,
          'The request timed out. Please try again.',
        );

      case DioExceptionType.connectionError:
        return const ApiException(
          ApiExceptionType.network,
          'No internet connection.',
        );

      case DioExceptionType.cancel:
        return const ApiException(
          ApiExceptionType.cancelled,
          'Request cancelled.',
        );

      case DioExceptionType.badResponse:
        final int? status = e.response?.statusCode;

        if (status == 400) {
          return ApiException(
            ApiExceptionType.badRequest,
            'Invalid request.',
            statusCode: status,
          );
        }

        if (status == 401 || status == 403) {
          return ApiException(
            ApiExceptionType.unauthorized,
            'Not authorized.',
            statusCode: status,
          );
        }

        if (status == 404) {
          return ApiException(
            ApiExceptionType.notFound,
            'Not found.',
            statusCode: status,
          );
        }

        return ApiException(
          ApiExceptionType.server,
          'Something went wrong on our end. Please try again later.',
          statusCode: status,
        );

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const ApiException(
          ApiExceptionType.unknown,
          'An unexpected error occurred.',
        );
    }
  }
}
