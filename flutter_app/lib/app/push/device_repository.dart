// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/device_repository.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';

/// Repository for device registration with backend
///
/// POST /api/devices/register  (auth:sanctum)
/// Body: { token, platform, locale, device_name? }
///
/// The `locale` field tells the backend which language to use for push
/// notifications sent to this device. It is sent on first registration and
/// re-sent automatically every time the user switches language in the app.
class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  /// Register device token with backend
  /// Call this after login, after registration, and when FCM token refreshes
  Future<bool> registerDevice(
    String fcmToken, {
    required String locale,
    String? deviceName,
  }) async {
    try {
      final platform = Platform.isIOS ? 'ios' : 'android';

      final registrationData = {
        'token': fcmToken,
        'platform': platform,
        'locale': locale,
        if (deviceName != null) 'device_name': deviceName,
      };

      _debugLog('Registering device with backend: platform=$platform, locale=$locale');

      final response = await _apiClient.post(
        '/api/devices/register',
        data: registrationData,
      );

      final success = response.statusCode == 200 || response.statusCode == 201;
      
      if (success) {
        _debugLog('Device registered successfully with backend');
      } else {
        _debugLog('Device registration failed: ${response.statusCode}');
      }
      
      return success;
    } catch (e) {
      _debugLog('Error registering device: $e');
      // Don't throw - device registration failure shouldn't break the app
      return false;
    }
  }

  /// Unregister device token from backend
  /// Call this on logout to stop receiving push notifications
  Future<bool> unregisterDevice(String fcmToken) async {
    try {
      _debugLog('Unregistering device from backend');

      final response = await _apiClient.delete(
        '/api/devices/unregister',
        data: {'token': fcmToken},
      );

      final success = response.statusCode == 200;
      
      if (success) {
        _debugLog('Device unregistered successfully');
      } else {
        _debugLog('Device unregistration failed: ${response.statusCode}');
      }
      
      return success;
    } catch (e) {
      _debugLog('Error unregistering device: $e');
      // Don't throw - unregistration failure shouldn't block logout
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
