// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/features/notifications/presentation/providers/notifications_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/features/notifications/domain/app_notification.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

/// State for notifications
class NotificationsState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationsState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  NotificationsState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get unread count
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  /// Check if there are any notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Check if there are unread notifications
  bool get hasUnread => unreadCount > 0;
}

/// Notifications state notifier
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final NotificationRepository _repository;

  NotificationsNotifier(this._repository) : super(const NotificationsState()) {
    _loadNotifications();
  }

  /// Load notifications from repository
  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _repository.loadAll();
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
      );
    } catch (e) {
      _debugLog('Error loading notifications: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement des notifications',
      );
    }
  }

  /// Refresh notifications from repository
  Future<void> refresh() async {
    await _loadNotifications();
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    try {
      // Save to repository
      await _repository.save(notification);
      
      // Update state (add at beginning)
      final updatedList = [notification, ...state.notifications];
      
      // Remove duplicates by ID
      final uniqueList = <String, AppNotification>{};
      for (final n in updatedList) {
        uniqueList[n.id] = n;
      }
      
      state = state.copyWith(
        notifications: uniqueList.values.toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt)),
      );
    } catch (e) {
      _debugLog('Error adding notification: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _repository.markAsRead(notificationId);
      
      final updatedList = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      _debugLog('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _repository.markAllAsRead();
      
      final updatedList = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      _debugLog('Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _repository.delete(notificationId);
      
      final updatedList = state.notifications
          .where((n) => n.id != notificationId)
          .toList();
      
      state = state.copyWith(notifications: updatedList);
    } catch (e) {
      _debugLog('Error deleting notification: $e');
    }
  }

  /// Clear all notifications
  Future<void> clearAll() async {
    try {
      await _repository.clearAll();
      state = state.copyWith(notifications: []);
    } catch (e) {
      _debugLog('Error clearing notifications: $e');
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[NotificationsNotifier] $message');
    }
  }
}

/// Provider for notifications state
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repository = ref.watch(notificationRepositoryProvider);
  return NotificationsNotifier(repository);
});

/// Provider for unread count only (for badges)
final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider).unreadCount;
});

/// Provider for checking if there are unread notifications
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  return ref.watch(notificationsProvider).hasUnread;
});
