import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';

/// API Client using Dio with interceptors for auth and logging
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  ApiClient({required TokenStorage tokenStorage})
      : _tokenStorage = tokenStorage,
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
      onError: (error, handler) {
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
        handler.next(error);
      },
    ));
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
  return ApiClient(tokenStorage: tokenStorage);
});

/// API Exception for handling errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    this.statusCode,
    this.errors,
  });

  factory ApiException.fromDioError(DioException error) {
    String message = 'Une erreur est survenue';
    int? statusCode = error.response?.statusCode;
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
          errors = data['errors'] as Map<String, dynamic>?;
        }
        break;
      default:
        message = error.message ?? message;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
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
