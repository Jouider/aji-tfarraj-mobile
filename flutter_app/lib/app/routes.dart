/// Centralized route constants for the app
/// Use these constants instead of hardcoding paths throughout the app
class Routes {
  Routes._(); // Private constructor to prevent instantiation

  // Auth flow (outside shell)
  static const splash = '/';
  static const language = '/language';
  static const authLanding = '/auth';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';

  // Tab roots (inside shell)
  static const home = '/home';
  static const browse = '/browse';
  static const myReservations = '/my-reservations';
  static const ticket = '/ticket';
  static const profile = '/profile';

  // Profile edit
  static const editProfile = '/profile/edit';

  // Notifications
  static const notifications = '/notifications';

  // Loyalty
  static const loyalty = '/loyalty';

  // Rewards
  static const rewards = '/rewards';
  static const myRewards = '/my-rewards';

  // Show routes (inside shell, independent of tabs)
  static const show = '/show';
  static String showDetail(String showId) => '/show/$showId';
  static String showReserve(String showId) => '/show/$showId/reserve';
  static String showSoldOut(String showId) => '/show/$showId/sold-out';

  // Reservation routes (inside shell, independent of tabs)
  static const reservation = '/reservation';
  static String reservationDetail(String reservationId) =>
      '/reservation/$reservationId';

  // Full screen routes (outside shell)
  static const reservationSuccess = '/reservation-success';
  static String reservationResult(String reservationId) =>
      '/reservation-result/$reservationId';
  static const error = '/error';

  // Phone OTP verification (full screen, outside shell)
  static const phoneVerification = '/phone-verify';

  // Staff check-in (full screen, outside shell — staff/admin only)
  static const staffCheckIn = '/staff/check-in';

  // Legal / participation conditions (full screen, outside shell — public)
  static const rules = '/rules';
}
