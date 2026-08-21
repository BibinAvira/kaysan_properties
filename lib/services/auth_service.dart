import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../models/auth_models.dart';
import 'auth_exception.dart';
import 'token_storage.dart';

/// Client for the auth microservice (`AppConfig.authBaseUrl`).
///
/// Kept as its own [Dio] instance — separate from [ApiService], which talks
/// to the unrelated properties microservice — because auth needs behaviour
/// [ApiService] intentionally doesn't have: an `Authorization: Bearer`
/// header attached per-request, and a queued "refresh the access token,
/// then retry" step on a 401 from `/profile/`.
///
/// Requests that need the bearer header are marked with
/// `Options(extra: {'requiresAuth': true})`; `/register/`, `/login/` and
/// `/token/refresh/` never carry that flag, so they're never retried
/// through the refresh flow themselves.
class AuthService {
  AuthService(this._tokenStorage)
      : _dio = Dio(
          BaseOptions(
            baseUrl: AppConfig.authBaseUrl,
            connectTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
            receiveTimeout: const Duration(seconds: AppConstants.apiTimeoutSeconds),
            headers: <String, String>{'Accept': 'application/json'},
          ),
        ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          logPrint: (Object obj) => debugPrint('[Auth] $obj'),
        ),
      );
    }

    // QueuedInterceptorsWrapper so concurrent 401s (e.g. profile fetched
    // twice at once) don't each kick off their own refresh call — they
    // queue behind the first one.
    _dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          if (options.extra['requiresAuth'] == true) {
            final String? token = await _tokenStorage.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          final RequestOptions requestOptions = error.requestOptions;
          final bool requiresAuth = requestOptions.extra['requiresAuth'] == true;
          final bool alreadyRetried = requestOptions.extra['retried'] == true;

          if (!requiresAuth || error.response?.statusCode != 401 || alreadyRetried) {
            return handler.next(error);
          }

          try {
            final String? refreshToken = await _tokenStorage.getRefreshToken();
            if (refreshToken == null) {
              return handler.next(error);
            }
            final String newAccess = await _refreshAccessToken(refreshToken);
            await _tokenStorage.saveAccessToken(newAccess);

            final RequestOptions retryOptions = requestOptions.copyWith(
              extra: <String, dynamic>{...requestOptions.extra, 'retried': true},
            );
            retryOptions.headers['Authorization'] = 'Bearer $newAccess';

            final Response<dynamic> response = await _dio.fetch<dynamic>(retryOptions);
            return handler.resolve(response);
          } catch (_) {
            // Refresh token is expired/invalid too — the session is over.
            await _tokenStorage.clear();
            return handler.next(error);
          }
        },
      ),
    );
  }

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<UserModel> register({
    required String username,
    required String password,
    String? email,
    String? phone,
    String? fullName,
  }) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/register/',
        data: <String, dynamic>{
          'username': username,
          'password': password,
          if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (fullName != null && fullName.trim().isNotEmpty) 'full_name': fullName.trim(),
        },
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Logs in, and persists both tokens to secure storage on success.
  Future<UserModel> login({required String username, required String password}) async {
    try {
      final Response<dynamic> response = await _dio.post<dynamic>(
        '/login/',
        data: <String, dynamic>{'username': username, 'password': password},
      );
      final Map<String, dynamic> data = response.data as Map<String, dynamic>;
      final String access = data['access'] as String;
      final String refresh = data['refresh'] as String;
      await _tokenStorage.saveTokens(access: access, refresh: refresh);
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<String> _refreshAccessToken(String refreshToken) async {
    final Response<dynamic> response = await _dio.post<dynamic>(
      '/token/refresh/',
      data: <String, dynamic>{'refresh': refreshToken},
    );
    return (response.data as Map<String, dynamic>)['access'] as String;
  }

  Future<UserModel> fetchProfile() async {
    try {
      final Response<dynamic> response = await _dio.get<dynamic>(
        '/profile/',
        options: Options(extra: <String, dynamic>{'requiresAuth': true}),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Partial update (only the fields supplied are changed) — `PATCH`.
  Future<UserModel> updateProfile(Map<String, dynamic> fields) async {
    try {
      final Response<dynamic> response = await _dio.patch<dynamic>(
        '/profile/',
        data: fields,
        options: Options(extra: <String, dynamic>{'requiresAuth': true}),
      );
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> logout() => _tokenStorage.clear();

  /// Whether an access token is on-device. This is a cheap presence check,
  /// not a validity check — an expired token still returns true here, and
  /// the first authenticated call that fails will trigger the refresh flow
  /// (or clear storage if the refresh token has also expired).
  Future<bool> hasStoredSession() async => await _tokenStorage.getAccessToken() != null;

  AuthException _mapError(DioException e) {
    final int? status = e.response?.statusCode;
    final Object? data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final Object? detail = data['detail'];
      if (detail is String) {
        return AuthException(detail, statusCode: status);
      }

      // DRF-style field validation errors: {"username": ["..."], ...}
      final Map<String, List<String>> fieldErrors = <String, List<String>>{};
      data.forEach((String key, Object? value) {
        if (value is List) {
          fieldErrors[key] = value.map((Object? e) => e.toString()).toList();
        }
      });
      if (fieldErrors.isNotEmpty) {
        return AuthException(
          fieldErrors.values.first.first,
          fieldErrors: fieldErrors,
          statusCode: status,
        );
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const AuthException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const AuthException('No internet connection.');
      case DioExceptionType.cancel:
        return const AuthException('Request cancelled.');
      case DioExceptionType.badResponse:
        if (status == 401) {
          return const AuthException('Invalid username or password.', statusCode: 401);
        }
        return AuthException('Something went wrong. Please try again.', statusCode: status);
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const AuthException('An unexpected error occurred.');
    }
  }
}
