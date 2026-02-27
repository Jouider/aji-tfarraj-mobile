import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central analytics service — thin wrapper around FirebaseAnalytics.
/// All 5 events defined in the Trello card are here.
class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService(this._analytics);

  /// User opens a show detail screen.
  Future<void> logViewShow({
    required int showId,
    required String showTitle,
  }) async {
    await _analytics?.logEvent(
      name: 'view_show',
      parameters: {
        'show_id': showId,
        'show_title': showTitle,
      },
    );
  }

  /// User taps "Confirmer la réservation" — before the API call.
  Future<void> logReserveAttempt({
    required int showId,
    required int seats,
  }) async {
    await _analytics?.logEvent(
      name: 'reserve_attempt',
      parameters: {
        'show_id': showId,
        'seats': seats,
      },
    );
  }

  /// API returns a created reservation — reservation submitted successfully.
  Future<void> logReserveSuccess({
    required int showId,
    required int reservationId,
    required int seats,
  }) async {
    await _analytics?.logEvent(
      name: 'reserve_success',
      parameters: {
        'show_id': showId,
        'reservation_id': reservationId,
        'seats': seats,
      },
    );
  }

  /// User lands on the ticket screen and a valid ticket is displayed.
  Future<void> logTicketGenerated({
    required String ticketCode,
    required int showId,
  }) async {
    await _analytics?.logEvent(
      name: 'ticket_generated',
      parameters: {
        'ticket_code': ticketCode,
        'show_id': showId,
      },
    );
  }

  /// App detects a ticket with checked_in status for the first time.
  Future<void> logCheckinSuccess({
    required String ticketCode,
    required int showId,
  }) async {
    await _analytics?.logEvent(
      name: 'checkin_success',
      parameters: {
        'ticket_code': ticketCode,
        'show_id': showId,
      },
    );
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  try {
    return AnalyticsService(FirebaseAnalytics.instance);
  } catch (_) {
    // Firebase not initialized (missing GoogleService-Info.plist / google-services.json)
    return AnalyticsService(null);
  }
});
