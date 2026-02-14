// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/push_token_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aji_tfarraj/app/push/device_repository.dart';

/// Push Token Provider - Manages FCM token state and backend registration
/// 
/// Backend endpoint (PRODUCTION):
/// POST /api/devices/register
/// 
/// This provider MUST be initialized:
/// - After successful login
/// - After successful registration
/// - FCM token refresh is handled automatically

/// State for FCM token
class PushTokenState {
  final String? token;
  final bool isLoading;
  final String? error;
  final bool isRegisteredWithBackend;

  const PushTokenState({
    this.token,
    this.isLoading = false,
    this.error,
    this.isRegisteredWithBackend = false,
  });

  PushTokenState copyWith({
    String? token,
    bool? isLoading,
    String? error,
    bool? isRegisteredWithBackend,
  }) {
    return PushTokenState(
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isRegisteredWithBackend: isRegisteredWithBackend ?? this.isRegisteredWithBackend,
    );
  }

  bool get hasToken => token != null && token!.isNotEmpty;
}

/// Push Token Notifier
class PushTokenNotifier extends StateNotifier<PushTokenState> {
  final DeviceRepository _deviceRepository;
  StreamSubscription<String>? _tokenRefreshSubscription;
  
  PushTokenNotifier(this._deviceRepository) : super(const PushTokenState());

  /// Initialize and get FCM token
  /// Call this after user logs in or registers
  Future<void> initialize() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      String? token;

      // On iOS, APNs token must be available before getting FCM token
      // The APNs token takes a moment to be set after app launch
      if (Platform.isIOS) {
        token = await _getTokenWithApnsRetry();
      } else {
        token = await FirebaseMessaging.instance.getToken();
      }
      
      if (token != null) {
        _debugLog('FCM Token obtained: ${token.substring(0, 20)}...');
      } else {
        _debugLog('FCM Token is null - push notifications may not work');
      }
      
      state = state.copyWith(
        token: token,
        isLoading: false,
      );

      // Register with backend if we have a token
      if (token != null) {
        await registerTokenWithBackend(token);
      }

      // Listen for token refresh
      _setupTokenRefreshListener();
    } catch (e) {
      _debugLog('Error getting FCM token: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la récupération du token',
      );
    }
  }

  /// Get FCM token on iOS with APNs retry logic
  /// APNs token needs time to be set after app launch
  Future<String?> _getTokenWithApnsRetry({int maxRetries = 5}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        // Check if APNs token is available
        final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        
        if (apnsToken != null) {
          _debugLog('APNs token available (attempt $attempt)');
          return await FirebaseMessaging.instance.getToken();
        }
        
        _debugLog('APNs token not yet available (attempt $attempt/$maxRetries), waiting...');
        
        // Wait before retrying (increasing delay)
        await Future.delayed(Duration(seconds: attempt));
      } catch (e) {
        _debugLog('Error getting token (attempt $attempt): $e');
        if (attempt == maxRetries) rethrow;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    
    // Final attempt without APNs check
    _debugLog('Final attempt to get FCM token without APNs check');
    return await FirebaseMessaging.instance.getToken();
  }

  /// Setup listener for FCM token refresh
  void _setupTokenRefreshListener() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        _debugLog('FCM Token refreshed');
        state = state.copyWith(token: newToken, isRegisteredWithBackend: false);
        await registerTokenWithBackend(newToken);
      },
      onError: (error) {
        _debugLog('Token refresh error: $error');
      },
    );
  }

  /// Register token with backend
  /// Public method to allow manual registration (e.g., after login)
  Future<bool> registerTokenWithBackend(String token) async {
    try {
      _debugLog('Registering token with backend...');
      final success = await _deviceRepository.registerDevice(token);
      state = state.copyWith(isRegisteredWithBackend: success);
      _debugLog('Backend registration: ${success ? 'success' : 'failed'}');
      return success;
    } catch (e) {
      _debugLog('Error registering with backend: $e');
      state = state.copyWith(isRegisteredWithBackend: false);
      return false;
    }
  }

  /// Register current token with backend
  /// Use this after login when token is already available
  Future<bool> registerCurrentToken() async {
    final currentToken = state.token;
    if (currentToken == null) {
      _debugLog('No token available to register');
      // Try to get a new token
      await initialize();
      return state.isRegisteredWithBackend;
    }
    return registerTokenWithBackend(currentToken);
  }

  /// Refresh token manually
  Future<void> refreshToken() async {
    try {
      // Delete existing token and get a new one
      await FirebaseMessaging.instance.deleteToken();
      final newToken = await FirebaseMessaging.instance.getToken();
      
      _debugLog('FCM Token refreshed manually');
      state = state.copyWith(token: newToken, isRegisteredWithBackend: false);
      
      // Re-register with backend
      if (newToken != null) {
        await registerTokenWithBackend(newToken);
      }
    } catch (e) {
      _debugLog('Error refreshing FCM token: $e');
    }
  }

  /// Clear token (e.g., on logout)
  Future<void> clearToken() async {
    try {
      final currentToken = state.token;
      
      // Unregister from backend first
      if (currentToken != null) {
        await _deviceRepository.unregisterDevice(currentToken);
      }
      
      // Cancel token refresh listener
      _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = null;
      
      // Then delete FCM token
      await FirebaseMessaging.instance.deleteToken();
      state = const PushTokenState();
      
      _debugLog('Token cleared and unregistered');
    } catch (e) {
      _debugLog('Error clearing FCM token: $e');
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[PushTokenNotifier] $message');
    }
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }
}

/// Provider for push token state
final pushTokenProvider =
    StateNotifierProvider<PushTokenNotifier, PushTokenState>((ref) {
  final deviceRepository = ref.watch(deviceRepositoryProvider);
  return PushTokenNotifier(deviceRepository);
});

/// Provider for current FCM token only
final fcmTokenProvider = Provider<String?>((ref) {
  return ref.watch(pushTokenProvider).token;
});

/// Provider for checking if token is registered with backend
final isTokenRegisteredProvider = Provider<bool>((ref) {
  return ref.watch(pushTokenProvider).isRegisteredWithBackend;
});
