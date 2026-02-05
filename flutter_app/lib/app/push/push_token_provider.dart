// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/push_token_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:aji_tfarraj/app/push/device_repository.dart';

/// Push Token Provider - Manages FCM token state
/// 
/// TODO BACKEND (Abdellah):
/// Send token to backend after login using:
/// POST /api/devices/register
/// Body:
/// {
///   "token": string,
///   "platform": "ios" | "android",
///   "device_name": optional string
/// }

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
  
  PushTokenNotifier(this._deviceRepository) : super(const PushTokenState());

  /// Initialize and get FCM token
  Future<void> initialize() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final token = await FirebaseMessaging.instance.getToken();
      _debugLog('FCM Token obtained: ${token?.substring(0, 20)}...');
      
      state = state.copyWith(
        token: token,
        isLoading: false,
      );

      // Register with backend
      if (token != null) {
        await _registerWithBackend(token);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        _debugLog('FCM Token refreshed');
        state = state.copyWith(token: newToken, isRegisteredWithBackend: false);
        await _registerWithBackend(newToken);
      });
    } catch (e) {
      _debugLog('Error getting FCM token: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors de la récupération du token',
      );
    }
  }

  /// Register token with backend
  Future<void> _registerWithBackend(String token) async {
    try {
      final success = await _deviceRepository.registerDevice(token);
      state = state.copyWith(isRegisteredWithBackend: success);
      _debugLog('Backend registration: ${success ? 'success' : 'failed'}');
    } catch (e) {
      _debugLog('Error registering with backend: $e');
    }
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
        await _registerWithBackend(newToken);
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
      
      // Then delete FCM token
      await FirebaseMessaging.instance.deleteToken();
      state = const PushTokenState();
    } catch (e) {
      _debugLog('Error clearing FCM token: $e');
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[PushTokenNotifier] $message');
    }
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
