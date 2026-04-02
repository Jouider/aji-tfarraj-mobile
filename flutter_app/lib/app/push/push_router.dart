// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/push/push_router.dart
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/notifications/domain/app_notification.dart';

/// Push Router - Handles navigation from push notifications
/// 
/// Supports backend payload formats:
/// 
/// Format A: { "type": "reservation", "reservation_id": "123", "title": "...", "body": "..." }
/// Format B: { "type": "ticket", "title": "...", "body": "..." }
/// Format C: { "deep_link": "/reservation/123" }
class PushRouter {
  PushRouter._();

  /// Navigate to the appropriate route based on notification
  /// Returns the route path to navigate to
  static String getRouteForNotification(AppNotification notification) {
    try {
      // Priority 1: Deep link if provided (Format C)
      if (notification.deepLink != null && notification.deepLink!.isNotEmpty) {
        final deepLink = notification.deepLink!;
        
        // Validate deep link format (must start with /)
        if (deepLink.startsWith('/')) {
          return _validateAndSanitizeRoute(deepLink);
        }
        
        _debugLog('Invalid deep link format: $deepLink');
      }

      // Priority 2: Type-based routing (Format A & B)
      switch (notification.type) {
        case NotificationType.reservation:
          if (notification.reservationId != null && 
              notification.reservationId!.isNotEmpty) {
            return Routes.reservationDetail(notification.reservationId!);
          }
          // Fallback to reservations list
          return Routes.myReservations;

        case NotificationType.ticket:
          return Routes.ticket;

        case NotificationType.system:
          // System notifications go to home or notifications center
          return Routes.home;

        case NotificationType.unknown:
          return Routes.home;
      }
    } catch (e) {
      _debugLog('Error getting route for notification: $e');
      return Routes.home;
    }
  }

  /// Navigate directly from raw push data
  /// Use this when you have the raw FCM data payload
  static String getRouteFromData(Map<String, dynamic> data) {
    try {
      // Check for deep_link first (Format C)
      final deepLink = data['deep_link']?.toString();
      if (deepLink != null && deepLink.isNotEmpty) {
        if (deepLink.startsWith('/')) {
          return _validateAndSanitizeRoute(deepLink);
        }
      }

      // Check type-based routing (Format A & B)
      final type = data['type']?.toString();
      
      if (type == 'reservation') {
        final reservationId = data['reservation_id']?.toString();
        if (reservationId != null && reservationId.isNotEmpty) {
          return Routes.reservationDetail(reservationId);
        }
        return Routes.myReservations;
      }
      
      if (type == 'ticket') {
        return Routes.ticket;
      }

      return Routes.home;
    } catch (e) {
      _debugLog('Error getting route from data: $e');
      return Routes.home;
    }
  }

  /// Navigate using GoRouter instance
  /// Safe navigation that handles errors gracefully
  static void navigateToNotification(
    GoRouter router,
    AppNotification notification,
  ) {
    try {
      final route = getRouteForNotification(notification);
      _debugLog('Navigating to route: $route');
      router.go(route);
    } catch (e) {
      _debugLog('Error navigating to notification: $e');
      // Fallback to home on error
      try {
        router.go(Routes.home);
      } catch (_) {
        // Ignore if even home navigation fails
      }
    }
  }

  /// Navigate using GoRouter instance from raw data
  static void navigateFromData(GoRouter router, Map<String, dynamic> data) {
    try {
      final route = getRouteFromData(data);
      _debugLog('Navigating to route from data: $route');
      router.go(route);
    } catch (e) {
      _debugLog('Error navigating from data: $e');
      try {
        router.go(Routes.home);
      } catch (_) {}
    }
  }

  /// Parse deep link from raw string
  /// Supports formats like:
  /// - /reservation/123
  /// - /show/456
  /// - ajitfarraj://reservation/123
  static String? parseDeepLink(String? rawDeepLink) {
    if (rawDeepLink == null || rawDeepLink.isEmpty) {
      return null;
    }

    try {
      // Handle app scheme URLs
      if (rawDeepLink.startsWith('ajitfarraj://')) {
        final uri = Uri.parse(rawDeepLink);
        return '/${uri.host}${uri.path}';
      }

      // Handle web URLs
      if (rawDeepLink.startsWith('https://') || 
          rawDeepLink.startsWith('http://')) {
        final uri = Uri.parse(rawDeepLink);
        return uri.path;
      }

      // Already a path
      if (rawDeepLink.startsWith('/')) {
        return rawDeepLink;
      }

      // Add leading slash if missing
      return '/$rawDeepLink';
    } catch (e) {
      _debugLog('Error parsing deep link: $e');
      return null;
    }
  }

  /// Validate and sanitize a route path
  /// Ensures the route is safe to navigate to
  static String _validateAndSanitizeRoute(String route) {
    // List of valid route prefixes
    const validPrefixes = [
      '/home',
      '/my-reservations',
      '/ticket',
      '/profile',
      '/show/',
      '/reservation/',
      '/reservation-result/',
      '/notifications',
      '/r/',
      '/referral-stats',
      '/referral-links',
    ];

    // Check if route matches any valid prefix
    final isValid = validPrefixes.any((prefix) => route.startsWith(prefix));
    
    if (isValid) {
      return route;
    }

    _debugLog('Route not in valid prefixes, defaulting to home: $route');
    return Routes.home;
  }

  /// Debug logging
  static void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[PushRouter] $message');
    }
  }
}
