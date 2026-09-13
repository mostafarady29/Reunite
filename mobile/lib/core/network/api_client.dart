import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';
import '../errors/failures.dart';
import 'api_config.dart';

/// Centralized Dio HTTP client.
///
/// Injects authentication headers, retries on refresh, logs in debug
/// builds only, and exposes typed [AppFailure] results via [run].
class ApiClient {
  ApiClient._(this._dio);

  final Dio _dio;

  /// Raw Dio for repositories. Prefer [run] so errors map to [AppFailure].
  Dio get dio => _dio;

  static String get effectiveBaseUrl {
    if (kApiBaseUrlOverride.isNotEmpty) return kApiBaseUrlOverride;
    if (kDebugMode) {
      if (kIsWeb) return 'http://localhost:8000';
      if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8000';
      }
      return 'http://localhost:8000';
    }
    return AppConstants.apiBaseUrl;
  }

  static ApiClient instance = ApiClient._(Dio(
    BaseOptions(
      baseUrl: effectiveBaseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeoutMs),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeoutMs),
      headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    ),
  )..interceptors.addAll([
      _AuthInterceptor(),
      if (kDebugMode) LogInterceptor(requestBody: true, responseBody: false),
    ]));

  /// Runs a Dio request and converts raw exceptions into typed failures.
  Future<Response<T>> run<T>(Future<Response<T>> Function(Dio dio) request) async {
    try {
      return await request(_dio);
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  AppFailure _map(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutFailure();
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final int? status = e.response?.statusCode;
        if (status == 401) return const UnauthorizedFailure();
        if (status == 404) return const NotFoundFailure();
        if (status != null && status >= 400 && status < 500) {
          final data = e.response?.data;
          if (data is Map<String, dynamic>) {
            if (data['errors'] is Map) {
              final errors = data['errors'] as Map<String, dynamic>;
              final fieldMessages = errors.map((k, v) => MapEntry(k, v.toString()));
              return ValidationFailure(fieldMessages: fieldMessages);
            }
            final msg = (data['message'] is String)
                ? data['message'] as String
                : (data['error'] is Map && data['error']['message'] is String)
                    ? data['error']['message'] as String
                    : (data['error'] is String)
                        ? data['error'] as String
                        : null;
            if (msg != null) {
              return ServerFailure(details: msg);
            }
          }
        }
        return const ServerFailure();
      case DioExceptionType.cancel:
        throw const CanceledFailure();
    }
  }
}

class _AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = _readToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

// Lazy accessor to avoid a circular import with the auth store at load time.
String? _readToken() => _tokenReader?.call();

/// Set once during DI wiring so the interceptor can read the current token.
typedef TokenReader = String? Function();

TokenReader? _tokenReader;
void setTokenReader(TokenReader reader) => _tokenReader = reader;