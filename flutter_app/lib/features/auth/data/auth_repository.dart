import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';

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

  /// Get current authenticated user
  Future<User> getCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    return User.fromJson(response.data);
  }

  /// Logout and clear token
  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (_) {
      // Ignore errors on logout, still clear token
    }
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

  AuthNotifier(this._repository, this._tokenStorage) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Check if user is already logged in on app start
  Future<void> _checkAuthStatus() async {
    try {
      final token = await _tokenStorage.readToken();
      if (token != null) {
        // Try to get current user to validate token
        final user = await _repository.getCurrentUser();
        state = AuthState(status: AuthStatus.authenticated, user: user);
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      // Token invalid or expired
      await _tokenStorage.clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
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
      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
      );
    } on DioException catch (e) {
      String message = 'Erreur de connexion';
      if (e.response?.statusCode == 401) {
        message = 'Email ou mot de passe incorrect';
      } else if (e.response?.data is Map) {
        message = e.response?.data['message'] ?? message;
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
    await _repository.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Provider for auth state
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage);
});
