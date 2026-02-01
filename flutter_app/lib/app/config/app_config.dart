/// App configuration constants
class AppConfig {
  AppConfig._();

  /// API Base URL - Production
  static const String apiBaseUrl = 'https://aji-tfarraj-backend-production.up.railway.app';

  /// API Base URL - Local development
  static const String apiBaseUrlLocal = 'http://localhost:8000';

  /// Current environment base URL
  static const String currentBaseUrl = apiBaseUrl;

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
  static const String shows = '/api/shows';
  static String showDetail(int id) => '/api/shows/$id';
  static const String reservations = '/api/reservations';
  static const String myReservations = '/api/me/reservations';
  static String reservationDetail(int id) => '/api/reservations/$id';
  static String cancelReservation(int id) => '/api/reservations/$id/cancel';
  static const String myTicket = '/api/me/ticket';
}
