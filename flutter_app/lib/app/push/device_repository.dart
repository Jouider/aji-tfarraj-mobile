// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/device_repository.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';

/// Device registration data for push notifications
class DeviceRegistration {
  final String token;
  final String platform;
  final String? deviceName;

  DeviceRegistration({
    required this.token,
    required this.platform,
    this.deviceName,
  });

  Map<String, dynamic> toJson() => {
    'token': token,
    'platform': platform,
    if (deviceName != null) 'device_name': deviceName,
  };
}

/// Repository for device registration with backend
/// 
/// TODO BACKEND (Abdellah):
/// Implement the following endpoints:
/// 
/// POST /api/devices/register
/// Headers: Authorization: Bearer {token}
/// Body: {
///   "token": "fcm_token_string",
///   "platform": "ios" | "android",
///   "device_name": "optional_device_name"
/// }
/// Response: { "success": true, "device_id": "uuid" }
/// 
/// DELETE /api/devices/unregister
/// Headers: Authorization: Bearer {token}
/// Body: { "token": "fcm_token_string" }
/// Response: { "success": true }
/// 
/// The backend should:
/// 1. Store device tokens per user (one user can have multiple devices)
/// 2. Handle token updates (same device, new token)
/// 3. Remove stale tokens when push fails
/// 4. Use tokens to send targeted push notifications
class DeviceRepository {
  // ignore: unused_field - Will be used when backend endpoint is ready
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  /// Register device token with backend
  /// Call this after login and when FCM token refreshes
  Future<bool> registerDevice(String fcmToken, {String? deviceName}) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';
      
      // Prepared for backend integration
      final registrationData = {
        'token': fcmToken,
        'platform': platform,
        if (deviceName != null) 'device_name': deviceName,
      };

      _debugLog('Registering device: platform=$platform, data=$registrationData');

      // TODO BACKEND (Abdellah): Uncomment when endpoint is ready
      // final response = await _apiClient.post(
      //   '/api/devices/register',
      //   data: registrationData,
      // );
      // return response.statusCode == 200 || response.statusCode == 201;

      // Placeholder until backend is ready
      _debugLog('Device registration endpoint not yet implemented on backend');
      return true;
    } catch (e) {
      _debugLog('Error registering device: $e');
      return false;
    }
  }

  /// Unregister device token from backend
  /// Call this on logout
  Future<bool> unregisterDevice(String fcmToken) async {
    try {
      _debugLog('Unregistering device');

      // TODO BACKEND (Abdellah): Uncomment when endpoint is ready
      // final response = await _apiClient.delete(
      //   '/api/devices/unregister',
      //   data: {'token': fcmToken},
      // );
      // return response.statusCode == 200;

      // Placeholder until backend is ready
      _debugLog('Device unregistration endpoint not yet implemented on backend');
      return true;
    } catch (e) {
      _debugLog('Error unregistering device: $e');
      return false;
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[DeviceRepository] $message');
    }
  }
}

/// Provider for DeviceRepository
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRepository(apiClient);
});
