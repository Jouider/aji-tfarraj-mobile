import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';

/// API Client using Dio with interceptors for auth and logging
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  /// Guards against multiple concurrent refresh calls
  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  ApiClient({required TokenStorage tokenStorage, required Ref ref})
      : _tokenStorage = tokenStorage,
        _ref = ref,
        _dio = Dio(BaseOptions(
          baseUrl: AppConfig.currentBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        )) {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Attach bearer token if available
        final token = await _tokenStorage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        // Debug logging
        if (kDebugMode) {
          print('┌─────────────────────────────────────────');
          print('│ 🌐 ${options.method} ${options.uri}');
          if (options.data != null) {
            print('│ 📦 Body: ${options.data}');
          }
          print('└─────────────────────────────────────────');
        }
        
        handler.next(options);
      },
      onResponse: (response, handler) {
        // Debug logging
        if (kDebugMode) {
          print('┌─────────────────────────────────────────');
          print('│ ✅ ${response.statusCode} ${response.requestOptions.uri}');
          print('└─────────────────────────────────────────');
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Debug logging
        if (kDebugMode) {
          print('┌─────────────────────────────────────────');
          print('│ ❌ ${error.response?.statusCode ?? 'Network Error'}');
          print('│ 🔗 ${error.requestOptions.uri}');
          print('│ 💬 ${error.message}');
          if (error.response?.data != null) {
            print('│ 📦 ${error.response?.data}');
          }
          print('└─────────────────────────────────────────');
        }

        // Retry transient errors (timeouts, connection drops, 5xx) with backoff
        if (_isRetryable(error)) {
          final retried = await _retryWithBackoff(error);
          if (retried != null) {
            handler.resolve(retried);
            return;
          }
        }

        // Handle 401 Unauthorized — try refresh first, then clear session
        if (error.response?.statusCode == 401 &&
            error.requestOptions.extra['skipRefresh'] != true) {
          final retried = await _tryRefreshAndRetry(error);
          if (retried != null) {
            handler.resolve(retried);
            return;
          }
        }

        handler.next(error);
      },
    ));
  }

  // ─── Retry logic ───────────────────────────────────────────────────────────

  static const _maxRetries = 3;
  static const _retryDelays = [
    Duration(milliseconds: 500),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 2000),
  ];

  /// Returns true for transient errors that are safe to retry:
  /// network timeouts, connection drops, and 5xx server errors.
  /// Never retries on 4xx (client errors) or refresh/retry-flagged requests.
  bool _isRetryable(DioException error) {
    if (error.requestOptions.extra['retryCount'] != null) {
      final count = error.requestOptions.extra['retryCount'] as int;
      if (count >= _maxRetries) return false;
    }
    if (error.requestOptions.extra['skipRefresh'] == true) return false;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }

  /// Waits with exponential backoff then re-fires the request.
  /// Increments `retryCount` in `extra` to prevent infinite loops.
  Future<Response?> _retryWithBackoff(DioException error) async {
    final opts = error.requestOptions;
    final attempt = (opts.extra['retryCount'] as int? ?? 0);
    final delay = _retryDelays[attempt];

    if (kDebugMode) {
      print('┌─────────────────────────────────────────');
      print('│ 🔁 Retry ${attempt + 1}/$_maxRetries after ${delay.inMilliseconds}ms');
      print('│ 🔗 ${opts.uri}');
      print('└─────────────────────────────────────────');
    }

    await Future<void>.delayed(delay);

    try {
      opts.extra['retryCount'] = attempt + 1;
      return await _dio.fetch(opts);
    } on DioException {
      return null;
    }
  }

  // ─── Token refresh logic ────────────────────────────────────────────────────

  /// Attempt a token refresh, then retry the original request.
  /// Returns the retried [Response] on success, null if refresh/retry failed.
  /// Uses a lock to prevent multiple concurrent refresh calls.
  Future<Response?> _tryRefreshAndRetry(DioException error) async {
    // If a refresh is already in flight, wait for it
    if (_isRefreshing) {
      final success = await _refreshCompleter!.future;
      if (!success) return null;
      return _retryRequest(error.requestOptions);
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        _refreshCompleter!.complete(false);
        await _clearSession();
        return null;
      }

      final refreshResponse = await _dio.post<Map<String, dynamic>>(
        AppConfig.authRefresh,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
          extra: {'skipRefresh': true},
        ),
      );

      final data = refreshResponse.data;
      final newToken = data?['token'] as String?;
      if (newToken == null) {
        _refreshCompleter!.complete(false);
        await _clearSession();
        return null;
      }

      await _tokenStorage.saveToken(newToken);
      final expiresAt = data?['expires_at'] as String?;
      if (expiresAt != null) await _tokenStorage.saveExpiresAt(expiresAt);
      await _ref.read(authStateProvider.notifier).setToken(newToken);

      _refreshCompleter!.complete(true);

      if (kDebugMode) {
        print('┌─────────────────────────────────────────');
        print('│ 🔄 Token refreshed — retrying request');
        print('└─────────────────────────────────────────');
      }

      return await _retryRequest(error.requestOptions);
    } on DioException catch (e) {
      _refreshCompleter!.complete(false);
      if (e.response?.statusCode == 401) {
        // Refresh token itself is invalid — full logout
        await _clearSession();
      }
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  /// Re-execute [opts] with the current stored token injected.
  Future<Response?> _retryRequest(RequestOptions opts) async {
    try {
      final token = await _tokenStorage.readToken();
      opts.headers['Authorization'] = 'Bearer $token';
      opts.extra['skipRefresh'] = true;
      return await _dio.fetch(opts);
    } catch (_) {
      return null;
    }
  }

  /// Clear token + auth state + show session-expired banner
  Future<void> _clearSession() async {
    await _tokenStorage.clearToken();
    await _ref.read(authStateProvider.notifier).clearToken();
    _ref.read(sessionExpiredProvider.notifier).state = true;

    if (kDebugMode) {
      print('┌─────────────────────────────────────────');
      print('│ 🔐 Session cleared — redirect to login');
      print('└─────────────────────────────────────────');
    }
  }

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.patch<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}

/// Provider for API Client
final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(tokenStorage: tokenStorage, ref: ref);
});

/// API Exception for handling errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'Une erreur est survenue';
    int? statusCode = error.response?.statusCode;
    String? code;
    Map<String, dynamic>? errors;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'La connexion a expiré. Veuillez réessayer.';
        break;
      case DioExceptionType.connectionError:
        message = 'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
        break;
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? message;
          code = data['code'] as String?;
          errors = (data['errors'] as Map?)?.cast<String, dynamic>();
        }
        break;
      default:
        message = error.message ?? message;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      code: code,
      errors: errors,
    );
  }

  bool get isUnauthenticated => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}
