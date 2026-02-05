// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/features/notifications/data/notification_repository.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/features/notifications/domain/app_notification.dart';

/// Repository for storing and retrieving notifications locally
/// Uses SharedPreferences for persistence
class NotificationRepository {
  static const String _storageKey = 'app_notifications';
  static const int _maxStoredNotifications = 100;

  final SharedPreferences _prefs;

  NotificationRepository(this._prefs);

  /// Load all stored notifications
  /// Returns notifications sorted by receivedAt (newest first)
  Future<List<AppNotification>> loadAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List<dynamic>;
      final notifications = jsonList
          .map((item) {
            try {
              return AppNotification.fromJson(item as Map<String, dynamic>);
            } catch (e) {
              _debugLog('Error parsing notification: $e');
              return null;
            }
          })
          .whereType<AppNotification>()
          .toList();

      // Sort by receivedAt descending (newest first)
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
      return notifications;
    } catch (e) {
      _debugLog('Error loading notifications: $e');
      return [];
    }
  }

  /// Save a new notification
  /// Automatically maintains the max limit and sorts by newest first
  Future<void> save(AppNotification notification) async {
    try {
      final notifications = await loadAll();
      
      // Check if notification already exists (by ID)
      final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
      if (existingIndex >= 0) {
        // Update existing notification
        notifications[existingIndex] = notification;
      } else {
        // Add new notification at the beginning
        notifications.insert(0, notification);
      }

      // Trim to max limit (keep newest)
      final trimmedList = notifications.take(_maxStoredNotifications).toList();
      
      await _saveAll(trimmedList);
    } catch (e) {
      _debugLog('Error saving notification: $e');
    }
  }

  /// Save multiple notifications at once
  Future<void> saveAll(List<AppNotification> newNotifications) async {
    try {
      final notifications = await loadAll();
      
      for (final notification in newNotifications) {
        final existingIndex = notifications.indexWhere((n) => n.id == notification.id);
        if (existingIndex >= 0) {
          notifications[existingIndex] = notification;
        } else {
          notifications.insert(0, notification);
        }
      }

      // Sort by receivedAt descending
      notifications.sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
      
      // Trim to max limit
      final trimmedList = notifications.take(_maxStoredNotifications).toList();
      
      await _saveAll(trimmedList);
    } catch (e) {
      _debugLog('Error saving notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await loadAll();
      final index = notifications.indexWhere((n) => n.id == notificationId);
      
      if (index >= 0) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await _saveAll(notifications);
      }
    } catch (e) {
      _debugLog('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notifications = await loadAll();
      final updatedNotifications = notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      await _saveAll(updatedNotifications);
    } catch (e) {
      _debugLog('Error marking all notifications as read: $e');
    }
  }

  /// Delete a specific notification
  Future<void> delete(String notificationId) async {
    try {
      final notifications = await loadAll();
      notifications.removeWhere((n) => n.id == notificationId);
      await _saveAll(notifications);
    } catch (e) {
      _debugLog('Error deleting notification: $e');
    }
  }

  /// Clear all stored notifications
  Future<void> clearAll() async {
    try {
      await _prefs.remove(_storageKey);
    } catch (e) {
      _debugLog('Error clearing notifications: $e');
    }
  }

  /// Get count of unread notifications
  Future<int> getUnreadCount() async {
    final notifications = await loadAll();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Internal method to save all notifications
  Future<void> _saveAll(List<AppNotification> notifications) async {
    final jsonList = notifications.map((n) => n.toJson()).toList();
    final jsonString = json.encode(jsonList);
    await _prefs.setString(_storageKey, jsonString);
  }

  /// Debug logging (only in debug mode)
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationRepository] $message');
    }
  }
}

/// Provider for SharedPreferences instance
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden in ProviderScope',
  );
});

/// Provider for NotificationRepository
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return NotificationRepository(prefs);
});
