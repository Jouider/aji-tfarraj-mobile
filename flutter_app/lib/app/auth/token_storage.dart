import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Secure token storage service using flutter_secure_storage
class TokenStorage {
  static const _tokenKey = 'auth_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Read the stored auth token
  Future<String?> readToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Save auth token securely
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Clear the stored auth token
  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }
}

/// Provider for TokenStorage instance
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage();
});

/// Provider for current auth token
final tokenProvider = FutureProvider<String?>((ref) async {
  final storage = ref.watch(tokenStorageProvider);
  return await storage.readToken();
});

/// Provider to check if user is authenticated
final isAuthenticatedProvider = FutureProvider<bool>((ref) async {
  final token = await ref.watch(tokenProvider.future);
  return token != null && token.isNotEmpty;
});

/// Auth state notifier for managing authentication
class AuthStateNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async {
    final storage = ref.read(tokenStorageProvider);
    return await storage.readToken();
  }

  Future<void> setToken(String token) async {
    final storage = ref.read(tokenStorageProvider);
    await storage.saveToken(token);
    state = AsyncData(token);
  }

  Future<void> clearToken() async {
    final storage = ref.read(tokenStorageProvider);
    await storage.clearToken();
    state = const AsyncData(null);
  }

  bool get isAuthenticated {
    return state.valueOrNull != null && state.valueOrNull!.isNotEmpty;
  }
}

/// Provider for auth state management
final authStateProvider = AsyncNotifierProvider<AuthStateNotifier, String?>(() {
  return AuthStateNotifier();
});

/// Signals that the user's session was terminated by a 401 response.
/// Set to true by ApiClient on 401; reset to false after the user sees the message.
final sessionExpiredProvider = StateProvider<bool>((ref) => false);
