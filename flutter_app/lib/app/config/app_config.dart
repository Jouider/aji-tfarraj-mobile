/// App configuration constants
///
/// Switch environments at build time:
///   flutter run --dart-define=ENV=local
///   flutter run --dart-define=ENV=prod  (default)
class AppConfig {
  AppConfig._();

  /// API Base URL - Production
  static const String apiBaseUrl =
      'https://aji-tfarraj-backend-production.up.railway.app';

  /// API Base URL - Local development
  static const String apiBaseUrlLocal = 'http://localhost:8000';

  static const _env = String.fromEnvironment('ENV', defaultValue: 'prod');

  /// Current environment base URL — set via --dart-define=ENV=local|prod
  static String get currentBaseUrl =>
      _env == 'local' ? apiBaseUrlLocal : apiBaseUrl;

  // ─── Sentry (error monitoring) ──────────────────────────────────────────────
  // The Sentry DSN is a client-side identifier (it only allows SENDING events)
  // and is embedded in every shipped binary — safe to keep in source. Same org
  // as the backend, so mobile errors link to backend traces. Override per-build
  // with --dart-define=SENTRY_DSN=... ; set to empty to disable Sentry entirely.
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://90c78b2f1b2d6f4121504d7ddcf8d278@o4511328504643584.ingest.us.sentry.io/4511328511590400',
  );

  /// Whether Sentry should be initialized / capture events.
  static bool get sentryEnabled => sentryDsn.isNotEmpty;

  /// Sentry environment tag — mirrors the API environment.
  static String get sentryEnvironment =>
      _env == 'local' ? 'development' : 'production';

  /// Safely compose API endpoint URL
  static String apiUrl(String path) {
    final base = currentBaseUrl.endsWith('/')
        ? currentBaseUrl.substring(0, currentBaseUrl.length - 1)
        : currentBaseUrl;
    final endpoint = path.startsWith('/') ? path : '/$path';
    return '$base$endpoint';
  }

  /// API Endpoints
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authLogout = '/api/auth/logout';
  static const String authMe = '/api/auth/me';
  static const String authRefresh = '/api/auth/refresh';
  static const String shows = '/api/shows';
  static String showDetail(int id) => '/api/shows/$id';
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/me/reservations';
  static String reservationDetail(int id) => '/api/reservations/$id';
  static String cancelReservation(int id) => '/api/reservations/$id/cancel';
  static const String myTicket = '/api/me/ticket';

  // Referral / Parrainage
  static const String myReferralLinks = '/api/me/referral-links';
  static String resolveReferralLink(String token) =>
      '/api/referral-links/$token';
  static const String myReferrals = '/api/me/referrals';

  // Support Tickets
  static const String supportTickets = '/api/support/tickets';
  static const String mySupportTickets = '/api/me/support-tickets';
  static String supportTicketDetail(int id) => '/api/me/support-tickets/$id';

  // App version gate (public): { latest_version, min_version, ios_url, android_url }
  static const String appConfig = '/api/app-config';
}
