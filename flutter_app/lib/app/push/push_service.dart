// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/push_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/features/notifications/domain/app_notification.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';

/// Background message handler - must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background handling
  await Firebase.initializeApp();
  
  if (kDebugMode) {
    debugPrint('[PushService] Background message received: ${message.messageId}');
  }
  
  // Note: We can't update providers from background handler
  // The notification will be processed when app comes to foreground
}

/// Push Service - Singleton for Firebase Cloud Messaging integration
/// 
/// Responsibilities:
/// - Initialize Firebase Messaging
/// - Request permissions (iOS)
/// - Handle foreground, background, and terminated state messages
/// - Show local notifications
/// - Coordinate with NotificationsProvider
/// 
/// TODO BACKEND (Abdellah):
/// Create endpoint POST /api/devices/register
/// Body:
/// {
///   "token": string,
///   "platform": "ios" | "android",
///   "device_name": optional string
/// }
/// Call it here after login or token refresh.
class PushService {
  PushService._();
  
  static final PushService instance = PushService._();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  WidgetRef? _ref;
  GoRouter? _router;
  BuildContext? _context;
  bool _isInitialized = false;

  /// A notification tap that arrived before the router was wired (cold start from
  /// a terminated state: getInitialMessage fires in main() before setRouter runs
  /// in the post-first-frame callback). Held here and flushed by [setRouter] so
  /// the tap is never silently dropped.
  AppNotification? _pendingNotification;
  
  // Stream controller for notification taps
  final StreamController<AppNotification> _notificationTapController = 
      StreamController<AppNotification>.broadcast();
  
  Stream<AppNotification> get onNotificationTap => _notificationTapController.stream;

  /// Initialize push notification service
  /// Must be called after Firebase.initializeApp()
  Future<void> init() async {
    if (_isInitialized) {
      _debugLog('Already initialized');
      return;
    }

    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permissions (iOS)
      await _requestPermissions();

      // Set up message handlers
      _setupMessageHandlers();

      // Create notification channel for Android
      await _createNotificationChannel();

      _isInitialized = true;
      _debugLog('Push service initialized successfully');
    } catch (e) {
      _debugLog('Error initializing push service: $e');
      // Don't throw - app should work without push notifications
    }
  }

  /// Set Riverpod ref for state management
  void setRef(WidgetRef ref) {
    _ref = ref;
  }

  /// Set router for navigation. Flushes any notification tap that arrived while
  /// the router wasn't ready yet (terminated-state cold start).
  void setRouter(GoRouter router) {
    _router = router;

    final pending = _pendingNotification;
    if (pending != null) {
      _pendingNotification = null;
      _debugLog('Flushing queued notification tap: ${pending.id}');
      PushRouter.navigateToNotification(router, pending);
    }
  }

  /// Set context for showing UI elements
  void setContext(BuildContext context) {
    _context = context;
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    _debugLog('Local notification tapped: ${response.payload}');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      // Newer payloads are a JSON map carrying the real notification id + fields
      // so mark-as-read targets the correct stored notification. Older payloads
      // were a bare route string — fall back to treating them as a deep link.
      Map<String, dynamic> data;
      final decoded = jsonDecode(payload);
      data = (decoded is Map)
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{'deep_link': payload};

      final notification = AppNotification.fromRemoteMessage(data);
      _handleNotificationTap(notification);
    } on FormatException {
      // Bare route string (legacy payload) — not valid JSON.
      final notification =
          AppNotification.fromRemoteMessage(<String, dynamic>{'deep_link': payload});
      _handleNotificationTap(notification);
    } catch (e) {
      _debugLog('Error parsing local notification payload: $e');
    }
  }

  /// Request push notification permissions
  Future<void> _requestPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      _debugLog('Permission status: ${settings.authorizationStatus}');

      // For iOS, also request local notification permissions
      if (Platform.isIOS) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
    } catch (e) {
      _debugLog('Error requesting permissions: $e');
    }
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      'aji_tfarraj_notifications',
      'Aji Tfarraj Notifications',
      description: 'Notifications pour vos réservations et billets',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Set up Firebase message handlers
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Check for initial message (app opened from terminated state)
    _checkInitialMessage();
  }

  /// Check if app was opened from a notification while terminated
  Future<void> _checkInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      
      if (initialMessage != null) {
        _debugLog('App opened from terminated state via notification');
        
        // Small delay to ensure app is ready
        await Future.delayed(const Duration(milliseconds: 500));
        
        _handleMessageOpenedApp(initialMessage);
      }
    } catch (e) {
      _debugLog('Error checking initial message: $e');
    }
  }

  /// Handle foreground message
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _debugLog('Foreground message received: ${message.messageId}');

    try {
      // Convert to AppNotification
      final notification = AppNotification.fromRemoteMessage(
        message.data,
        notificationTitle: message.notification?.title,
        notificationBody: message.notification?.body,
      );

      // Store notification
      await _storeNotification(notification);

      // Auto-refresh reservations when a reservation notification arrives
      if (notification.type == NotificationType.reservation) {
        _ref?.read(myReservationsProvider.notifier).refresh();
      }

      // Show foreground UI
      _showForegroundNotification(notification);

      // Show local system notification
      await _showLocalNotification(notification);
    } catch (e) {
      _debugLog('Error handling foreground message: $e');
    }
  }

  /// Handle message when app is opened from background (or terminated).
  void _handleMessageOpenedApp(RemoteMessage message) {
    _debugLog('App opened from notification: ${message.messageId}');

    // Store-redirect push (mass "please update" campaign): open the platform
    // store and stop — these have no in-app destination.
    if (message.data['action'] == 'open_store') {
      _openStore(message.data);
      return;
    }

    try {
      final notification = AppNotification.fromRemoteMessage(
        message.data,
        notificationTitle: message.notification?.title,
        notificationBody: message.notification?.body,
      );

      // Store and mark as read since user tapped it
      _storeNotification(notification.copyWith(isRead: true));

      // Navigate to appropriate screen
      _handleNotificationTap(notification);
    } catch (e) {
      _debugLog('Error handling message opened app: $e');
    }
  }

  /// Open the platform store URL for an "open_store" notification.
  /// Backend data: { action: open_store, ios_url, android_url }.
  Future<void> _openStore(Map<String, dynamic> data) async {
    final url = (Platform.isIOS ? data['ios_url'] : data['android_url']) as String?;

    if (url == null || url.isEmpty) {
      _debugLog('open_store: no store URL for this platform');
      return;
    }

    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      _debugLog('Error opening store URL: $e');
    }
  }

  /// Store notification in provider
  Future<void> _storeNotification(AppNotification notification) async {
    try {
      _ref?.read(notificationsProvider.notifier).addNotification(notification);
    } catch (e) {
      _debugLog('Error storing notification: $e');
    }
  }

  /// Show foreground notification banner
  void _showForegroundNotification(AppNotification notification) {
    final context = _context;
    if (context == null || !context.mounted) {
      _debugLog('No valid context for foreground notification');
      return;
    }

    try {
      ScaffoldMessenger.of(context).showMaterialBanner(
        MaterialBanner(
          backgroundColor: AppColors.backgroundWhite,
          padding: const EdgeInsets.all(16),
          leading: _getNotificationIcon(notification.type),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                notification.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (notification.body.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  notification.body,
                  style: const TextStyle(fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
              },
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
                _handleNotificationTap(notification);
              },
              child: const Text(
                'Ouvrir',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );

      // Auto-dismiss after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (context.mounted) {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        }
      });
    } catch (e) {
      _debugLog('Error showing foreground notification: $e');
    }
  }

  /// Show local system notification
  Future<void> _showLocalNotification(AppNotification notification) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'aji_tfarraj_notifications',
        'Aji Tfarraj Notifications',
        channelDescription: 'Notifications pour vos réservations et billets',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Encode the real id + routing fields so a tap can mark the correct
      // stored notification as read AND resolve the destination. deep_link holds
      // an explicit link when present, else the type-resolved route.
      final payload = jsonEncode(<String, dynamic>{
        'id': notification.id,
        'type': notification.type.toJson(),
        if (notification.reservationId != null)
          'reservation_id': notification.reservationId,
        if (notification.ticketCode != null)
          'ticket_code': notification.ticketCode,
        'deep_link': notification.deepLink ??
            PushRouter.getRouteForNotification(notification),
      });

      await _localNotifications.show(
        notification.id.hashCode,
        notification.title,
        notification.body,
        details,
        payload: payload,
      );
    } catch (e) {
      _debugLog('Error showing local notification: $e');
    }
  }

  /// Handle notification tap - navigate to appropriate screen
  void _handleNotificationTap(AppNotification notification) {
    _debugLog('Handling notification tap: ${notification.id}');

    // Emit to stream for external listeners
    _notificationTapController.add(notification);

    // Mark as read
    _ref?.read(notificationsProvider.notifier).markAsRead(notification.id);

    // Navigate — or queue if the router isn't wired yet (cold start). setRouter
    // flushes the pending tap the moment it runs, so we never lose it.
    if (_router != null) {
      PushRouter.navigateToNotification(_router!, notification);
    } else {
      _debugLog('Router not ready — queueing notification tap for flush');
      _pendingNotification = notification;
    }
  }

  /// Get icon for notification type
  Widget _getNotificationIcon(NotificationType type) {
    IconData iconData;
    Color color;

    switch (type) {
      case NotificationType.reservation:
        iconData = Icons.calendar_today;
        color = AppColors.primary;
      case NotificationType.ticket:
        iconData = Icons.confirmation_number;
        color = AppColors.success;
      case NotificationType.system:
        iconData = Icons.info_outline;
        color = AppColors.info;
      case NotificationType.unknown:
        iconData = Icons.notifications;
        color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  /// Debug logging
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[PushService] $message');
    }
  }

  /// Dispose resources
  void dispose() {
    _notificationTapController.close();
  }
}

/// Provider for PushService instance
final pushServiceProvider = Provider<PushService>((ref) {
  return PushService.instance;
});
