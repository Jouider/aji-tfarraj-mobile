/// Centralized route constants for the app
/// Use these constants instead of hardcoding paths throughout the app
class Routes {
  Routes._(); // Private constructor to prevent instantiation

  // Auth flow (outside shell)
  static const splash = '/';
  static const language = '/language';
  static const login = '/login';

  // Tab roots (inside shell)
  static const home = '/home';
  static const myReservations = '/my-reservations';
  static const ticket = '/ticket';
  static const profile = '/profile';

  // Show routes (inside shell, independent of tabs)
  static const show = '/show';
  static String showDetail(String showId) => '/show/$showId';
  static String showReserve(String showId) => '/show/$showId/reserve';
  static String showSoldOut(String showId) => '/show/$showId/sold-out';

  // Reservation routes (inside shell, independent of tabs)
  static const reservation = '/reservation';
  static String reservationDetail(String reservationId) => '/reservation/$reservationId';

  // Full screen routes (outside shell)
  static const reservationSuccess = '/reservation-success';
  static const error = '/error';
}
