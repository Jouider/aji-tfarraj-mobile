import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';

// Re-export the token-based auth state provider for router to use
export 'package:aji_tfarraj/app/auth/token_storage.dart' show authStateProvider;

/// Authentication repository for login, register, logout
class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository(this._dio, this._tokenStorage);

  /// Register a new user
  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      '/api/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.token);
    return authResponse;
  }

  /// Login with email and password
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/api/auth/login',
      data: {
        'email': email,
        'password': password,
      },
    );
    
    final authResponse = AuthResponse.fromJson(response.data);
    await _tokenStorage.saveToken(authResponse.token);
    return authResponse;
  }

  /// Get current authenticated user (GET /api/auth/me)
  /// Returns the user if authenticated, throws on 401 or network error
  Future<User> me() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/api/auth/me'),
        type: DioExceptionType.unknown,
        error: 'No token available',
      );
    }
    
    // Add token to request since authDio doesn't have interceptor
    final response = await _dio.get(
      '/api/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );
    return User.fromJson(response.data['data'] ?? response.data);
  }

  /// Get current authenticated user (alias for backward compatibility)
  Future<User> getCurrentUser() async {
    return me();
  }

  /// Logout and clear token
  /// Calls backend logout endpoint best-effort, but ALWAYS clears token locally
  Future<void> logout() async {
    final token = await _tokenStorage.readToken();
    
    // Best-effort backend logout call
    if (token != null && token.isNotEmpty) {
      try {
        await _dio.post(
          '/api/auth/logout',
          options: Options(
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
      } catch (_) {
        // Ignore errors on logout - always clear token locally
      }
    }
    
    // ALWAYS clear token locally regardless of backend response
    await _tokenStorage.clearToken();
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await _tokenStorage.readToken();
    return token != null;
  }
}

/// Dio provider for auth (without auth interceptor to avoid circular dependency)
final authDioProvider = Provider<Dio>((ref) {
  return Dio(BaseOptions(
    baseUrl: AppConfig.currentBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));
});

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(authDioProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthRepository(dio, tokenStorage);
});

/// Authentication state
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

/// Auth state notifier for managing authentication
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final Ref _ref;

  AuthNotifier(this._repository, this._tokenStorage, this._ref) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in on app start
  /// Validates token by calling GET /api/auth/me
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    try {
      final token = await _tokenStorage.readToken();
      if (token != null && token.isNotEmpty) {
        // Validate token by fetching current user
        final user = await _repository.me();
        
        // Sync with router's auth state provider
        await _ref.read(authStateProvider.notifier).setToken(token);
        
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } on DioException catch (e) {
      // Token invalid, expired, or network error
      if (e.response?.statusCode == 401) {
        // Token is invalid - clear it
        await _tokenStorage.clearToken();
        await _ref.read(authStateProvider.notifier).clearToken();
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      // Any other error - treat as unauthenticated
      await _tokenStorage.clearToken();
      await _ref.read(authStateProvider.notifier).clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Refresh session - can be called manually to re-validate token
  Future<void> refreshSession() async {
    await _checkAuthStatus();
  }

  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    
    try {
      final authResponse = await _repository.login(
        email: email,
        password: password,
      );
      
      // Notify the token-based auth provider that router listens to
      await _ref.read(authStateProvider.notifier).setToken(authResponse.token);
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on DioException catch (e) {
      String message;
      
      // Handle different error types with friendly messages
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        message = 'La connexion a expiré. Veuillez réessayer.';
      } else if (e.type == DioExceptionType.connectionError) {
        message = 'Impossible de se connecter. Vérifiez votre connexion internet.';
      } else if (e.response?.statusCode == 401) {
        message = 'Email ou mot de passe incorrect.';
      } else if (e.response?.statusCode == 422) {
        // Validation error
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'];
        } else {
          message = 'Veuillez vérifier vos informations.';
        }
      } else if (e.response?.statusCode != null && e.response!.statusCode! >= 500) {
        message = 'Erreur serveur. Veuillez réessayer plus tard.';
      } else if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      } else {
        message = 'Erreur de connexion. Veuillez réessayer.';
      }
      
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Register a new user
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    
    try {
      final authResponse = await _repository.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      
      // Notify the token-based auth provider that router listens to
      await _ref.read(authStateProvider.notifier).setToken(authResponse.token);
      
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on DioException catch (e) {
      String message = 'Erreur lors de l\'inscription';
      if (e.response?.data is Map) {
        final errors = e.response?.data['errors'] as Map<String, dynamic>?;
        if (errors != null && errors.isNotEmpty) {
          // Get first error message
          final firstError = errors.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        } else {
          message = e.response?.data['message'] ?? message;
        }
      }
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: message,
      );
      rethrow;
    }
  }

  /// Logout
  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    
    await _repository.logout();
    
    // Notify the token-based auth provider that router listens to
    await _ref.read(authStateProvider.notifier).clearToken();
    
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for auth state (login/register UI state)
final loginAuthStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage, ref);
});
