import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/push/push_token_provider.dart';
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
    await _saveAuthResponse(authResponse);
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
    await _saveAuthResponse(authResponse);
    return authResponse;
  }

  /// Refresh the current token via POST /api/auth/refresh.
  /// Saves new token + expires_at on success.
  /// Throws on failure (caller handles 401 → full logout).
  Future<AuthResponse> refreshToken() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: AppConfig.authRefresh),
        type: DioExceptionType.unknown,
        error: 'No token to refresh',
      );
    }
    final response = await _dio.post(
      AppConfig.authRefresh,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveAuthResponse(authResponse);
    return authResponse;
  }

  /// Persist token + optional expires_at from an auth response
  Future<void> _saveAuthResponse(AuthResponse authResponse) async {
    await _tokenStorage.saveToken(authResponse.token);
    if (authResponse.expiresAt != null) {
      await _tokenStorage.saveExpiresAt(
        authResponse.expiresAt!.toIso8601String(),
      );
    }
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

  /// Google OAuth via Chrome Custom Tab — bypasses google_sign_in entirely.
  ///
  /// The `google_sign_in` plugin (all versions) triggers DEVELOPER_ERROR (10)
  /// on many Android devices due to GMS CredentialManager / requestIdToken bugs.
  /// This approach opens Google's OAuth2 authorization endpoint in a Chrome
  /// Custom Tab, which works on every Android device regardless of GMS version.
  ///
  /// Flow:
  /// 1. Open Google OAuth in Chrome Custom Tab → user picks account
  /// 2. Google redirects to our custom scheme with an access_token (implicit grant)
  /// 3. We send the access_token to our backend `/api/auth/social`
  /// 4. Backend verifies via Google userinfo API and returns a Sanctum token
  Future<AuthResponse> loginWithGoogle() async {
    // Web Client ID from Google Cloud Console (same project as Firebase)
    const webClientId =
        '600996591716-kptab77521aol0t2svaeq4ms24doh0if.apps.googleusercontent.com';

    // The backend hosts an OAuth relay page at /oauth/callback.
    // Google redirects there (https:// — accepted by Web client type).
    // That page reads the id_token from the URL fragment via JS and
    // redirects to our custom scheme, which flutter_web_auth_2 catches.
    // URL schemes must not contain underscores — use 'ajitfarraj' as the scheme.
    const redirectScheme = 'ajitfarraj';
    const redirectUri =
        'https://aji-tfarraj-backend-production.up.railway.app/oauth/callback';

    // PKCE-like nonce for CSRF protection
    final state = _generateRandomString(32);

    // Use a nonce for the OpenID Connect id_token flow (required by Google)
    final nonce = _generateRandomString(32);

    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': webClientId,
      'redirect_uri': redirectUri,
      'response_type': 'id_token',
      'scope': 'email profile openid',
      'state': state,
      'nonce': nonce,
      'prompt': 'select_account',
    });

    String resultUrl;
    try {
      resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: redirectScheme,
      );
    } on Exception catch (e) {
      if (e.toString().contains('CANCELED') ||
          e.toString().contains('cancelled')) {
        throw _cancelledError();
      }
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        error: e,
        message: 'Google Sign-In échoué : $e',
      );
    }

    // The relay page redirects to ajitfarraj://oauth?id_token=xxx&state=yyy
    // Params are in the query string (not fragment) after the relay redirect.
    final uri = Uri.parse(resultUrl);
    final params = uri.queryParameters;

    // Verify state matches to prevent CSRF
    if (params['state'] != state) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        message: 'Erreur de sécurité. Réessayez.',
      );
    }

    final idToken = params['id_token'];
    if (idToken == null || idToken.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.unknown,
        message: 'Impossible d\'obtenir le token Google. Réessayez.',
      );
    }

    // Send id_token (JWT) to backend — it verifies via Google's JWKS endpoint
    final response = await _dio.post('/api/auth/social', data: {
      'provider': 'google',
      'token': idToken,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveAuthResponse(authResponse);
    return authResponse;
  }

  /// Generate a random alphanumeric string for OAuth state parameter
  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  Future<AuthResponse> loginWithApple() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final identityToken = credential.identityToken;
    if (identityToken == null) throw _cancelledError();

    final response = await _dio.post('/api/auth/social', data: {
      'provider': 'apple',
      'token': identityToken,
      if (credential.givenName != null) 'first_name': credential.givenName,
      if (credential.familyName != null) 'last_name': credential.familyName,
    });
    final authResponse = AuthResponse.fromJson(response.data);
    await _saveAuthResponse(authResponse);
    return authResponse;
  }

  DioException _cancelledError() => DioException(
        requestOptions: RequestOptions(path: ''),
        type: DioExceptionType.cancel,
      );
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

  /// Check if user is already logged in on app start.
  /// Proactively refreshes the token if it expires within 1 day.
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);

    try {
      final token = await _tokenStorage.readToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }

      // Proactively refresh if token is expiring soon (within 1 day)
      if (await _tokenStorage.isExpiringSoon()) {
        try {
          final refreshed = await _repository.refreshToken();
          await _ref.read(authStateProvider.notifier).setToken(refreshed.token);
          state = AuthState(status: AuthStatus.authenticated, user: refreshed.user);
          _registerDeviceToken();
          return;
        } on DioException catch (e) {
          if (e.response?.statusCode == 401) {
            // Refresh rejected → session is truly expired
            await _tokenStorage.clearToken();
            await _ref.read(authStateProvider.notifier).clearToken();
            state = const AuthState(status: AuthStatus.unauthenticated);
            return;
          }
          // Network error during refresh — fall through to validate with /me
        }
      }

      // Validate token by fetching current user
      final user = await _repository.me();
      await _ref.read(authStateProvider.notifier).setToken(token);
      state = AuthState(status: AuthStatus.authenticated, user: user);
      _registerDeviceToken();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _tokenStorage.clearToken();
        await _ref.read(authStateProvider.notifier).clearToken();
      }
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (_) {
      await _tokenStorage.clearToken();
      await _ref.read(authStateProvider.notifier).clearToken();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// Register device token for push notifications
  /// Called after successful login, registration, or app start with valid session
  Future<void> _registerDeviceToken() async {
    try {
      await _ref.read(pushTokenProvider.notifier).initialize();
    } catch (e) {
      // Don't fail auth flow if push token registration fails
      // Push notifications are not critical for app functionality
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
      
      // Register device for push notifications after successful login
      _registerDeviceToken();
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
      } else if (e.response?.statusCode == 429) {
        final retryAfter = e.response?.headers.value('retry-after');
        final seconds = retryAfter != null ? int.tryParse(retryAfter) : null;
        message = seconds != null
            ? 'Trop de tentatives. Réessayez dans $seconds secondes.'
            : 'Trop de tentatives. Veuillez réessayer plus tard.';
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
      
      // Register device for push notifications after successful registration
      _registerDeviceToken();
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
    
    // Clear push token first (unregister from backend)
    try {
      await _ref.read(pushTokenProvider.notifier).clearToken();
    } catch (_) {
      // Don't fail logout if push token clearing fails
    }
    
    await _repository.logout();
    
    // Notify the token-based auth provider that router listens to
    await _ref.read(authStateProvider.notifier).clearToken();
    
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Sign in with Google — calls repository, updates auth state on success.
  Future<void> loginWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authResponse = await _repository.loginWithGoogle();
      await _ref.read(authStateProvider.notifier).setToken(authResponse.token);
      state = AuthState(status: AuthStatus.authenticated, user: authResponse.user);
      _registerDeviceToken();
      await refreshUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // User cancelled — restore previous state silently
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final message = (e.response?.data is Map)
          ? (e.response!.data as Map)['message'] as String? ??
              'Connexion Google échouée. Réessayez.'
          : e.message ?? 'Connexion Google échouée. Réessayez.';
      state = AuthState(
          status: AuthStatus.unauthenticated, errorMessage: message);
      rethrow;
    } catch (e) {
      // Catch-all — ensures state is ALWAYS reset so spinner never hangs.
      // Show raw error during debugging so we can diagnose.
      state = AuthState(
        status: AuthStatus.unauthenticated,
        errorMessage: 'Erreur Google: $e',
      );
      rethrow;
    }
  }

  /// Sign in with Apple — calls repository, updates auth state on success.
  Future<void> loginWithApple() async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final authResponse = await _repository.loginWithApple();
      await _ref.read(authStateProvider.notifier).setToken(authResponse.token);
      state = AuthState(status: AuthStatus.authenticated, user: authResponse.user);
      _registerDeviceToken();
      await refreshUser();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      final message = (e.response?.data is Map)
          ? (e.response!.data as Map)['message'] as String? ??
              'Erreur de connexion'
          : 'Erreur de connexion';
      state = AuthState(
          status: AuthStatus.unauthenticated, errorMessage: message);
      rethrow;
    }
  }

  /// Update cached user (called after profile edit)
  void updateUser(User user) {
    state = state.copyWith(user: user);
  }

  /// Re-fetch user from GET /api/auth/me and update cached state.
  /// Use this after profile edits where the mutation response may have stale
  /// or incorrect computed fields (e.g. profile_complete).
  Future<void> refreshUser() async {
    try {
      final user = await _repository.me();
      state = state.copyWith(user: user);
    } catch (_) {
      // Keep existing state on error — don't break the UI
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Set an explicit error message (used by the UI layer for unexpected errors).
  void setError(String message) {
    state = AuthState(status: AuthStatus.unauthenticated, errorMessage: message);
  }
}

/// Provider for auth state (login/register UI state)
final loginAuthStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(repository, tokenStorage, ref);
});
