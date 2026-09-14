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
        return TimeoutFailure(details: _debugDetails(e));
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return NetworkFailure(details: _debugDetails(e));
      case DioExceptionType.badResponse:
        final int? status = e.response?.statusCode;
        final data = e.response?.data;
        final serverMessage = extractServerMessage(data);
        final fieldMessages = extractFieldMessages(data);
        final details = _failureDetails(
          status: status,
          message: serverMessage,
          path: e.requestOptions.path,
        );
        if (fieldMessages.isNotEmpty) {
          return ValidationFailure(
            fieldMessages: fieldMessages,
            details: details,
          );
        }
        if (status == 422 || status == 400) {
          return ValidationFailure(
            fieldMessages: const {},
            details: details,
          );
        }
        if (status == 401) return UnauthorizedFailure(details: details);
        if (status == 403) {
          return PermissionDeniedFailure(details: details);
        }
        if (status == 404) return NotFoundFailure(details: details);
        return ServerFailure(details: details);
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

/// Best-effort extraction of a human-readable backend message.
///
/// Handles `{message}`, `{error}`, `{data: {message}}`, plain strings,
/// and Fastify/Zod `{issues: [{message}]}` shapes. Returns null when
/// nothing usable is found so callers fall back to localized text.
String? extractServerMessage(dynamic data) {
  if (data == null) return null;
  if (data is String) {
    final v = data.trim();
    return v.isEmpty ? null : v;
  }
  if (data is Map) {
    for (final key in const ['message', 'error', 'msg', 'detail', 'details']) {
      final v = data[key];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      if (v is Map && v['message'] is String) {
        final nested = (v['message'] as String).trim();
        if (nested.isNotEmpty) return nested;
      }
    }
    final inner = data['data'];
    if (inner is Map) {
      final nested = extractServerMessage(inner);
      if (nested != null) return nested;
    }
    final issues = data['issues'];
    if (issues is List && issues.isNotEmpty) {
      final first = issues.first;
      if (first is Map && first['message'] is String) {
        return (first['message'] as String).trim();
      }
    }
  }
  return null;
}

/// Extracts per-field errors from common backend shapes:
/// `{errors: {field: msg|[msg]}}`, `{fields: {...}}`, `{data: {errors}}`.
Map<String, String> extractFieldMessages(dynamic data) {
  Map<String, dynamic>? raw;
  if (data is Map) {
    if (data['errors'] is Map) {
      raw = Map<String, dynamic>.from(data['errors'] as Map);
    } else if (data['fields'] is Map) {
      raw = Map<String, dynamic>.from(data['fields'] as Map);
    } else if (data['data'] is Map &&
        (data['data'] as Map)['errors'] is Map) {
      raw = Map<String, dynamic>.from(
        (data['data'] as Map)['errors'] as Map,
      );
    }
  }
  if (raw == null) return const {};
  return raw.map((k, v) {
    if (v is List) {
      return MapEntry(k, v.map((e) => e.toString()).join('\n'));
    }
    return MapEntry(k, v.toString());
  });
}

/// Packs status + message + endpoint into [AppFailure.details] so the UI
/// layer can identify and display the exact backend error.
String? _failureDetails({int? status, String? message, String? path}) {
  final parts = <String>[];
  if (status != null) parts.add('HTTP $status');
  if (path != null && path.isNotEmpty) parts.add(path);
  if (message != null && message.isNotEmpty) parts.add(message);
  if (parts.isEmpty) return null;
  return parts.join(' | ');
}

String? _debugDetails(DioException e) {
  final path = e.requestOptions.path;
  final msg = e.message;
  final parts = <String>[];
  if (path.isNotEmpty) parts.add(path);
  if (msg != null && msg.isNotEmpty) parts.add(msg);
  if (parts.isEmpty) return null;
  return parts.join(' | ');
}