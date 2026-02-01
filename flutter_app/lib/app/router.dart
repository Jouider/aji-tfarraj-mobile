import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/app_shell.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/splash/splash_screen.dart';
import 'package:aji_tfarraj/features/language/language_selection_screen.dart';
import 'package:aji_tfarraj/features/auth/login_screen.dart';
import 'package:aji_tfarraj/features/home/home_screen.dart';
import 'package:aji_tfarraj/features/show/show_detail_screen.dart';
import 'package:aji_tfarraj/features/reservation/reserve_seats_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_success_screen.dart';
import 'package:aji_tfarraj/features/reservation/my_reservations_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_detail_screen.dart';
import 'package:aji_tfarraj/features/ticket/ticket_screen.dart';
import 'package:aji_tfarraj/features/profile/profile_screen.dart';
import 'package:aji_tfarraj/features/error/error_screen.dart';
import 'package:aji_tfarraj/features/show/sold_out_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.splash,
    routes: [
      // ============================================
      // Auth Flow (outside shell - no bottom nav)
      // ============================================
      GoRoute(
        path: Routes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.language,
        name: 'language',
        builder: (context, state) => const LanguageSelectionScreen(),
      ),
      GoRoute(
        path: Routes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ============================================
      // Shell Route (bottom nav stays visible)
      // ============================================
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // --- Tab Roots ---
          GoRoute(
            path: Routes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.myReservations,
            name: 'myReservations',
            builder: (context, state) => const MyReservationsScreen(),
          ),
          GoRoute(
            path: Routes.ticket,
            name: 'ticket',
            builder: (context, state) => const TicketScreen(),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),

          // --- Show Routes (independent of tabs, nav stays) ---
          GoRoute(
            path: '/show/:showId',
            name: 'showDetail',
            builder: (context, state) {
              final showId = state.pathParameters['showId']!;
              return ShowDetailScreen(showId: showId);
            },
            routes: [
              GoRoute(
                path: 'reserve',
                name: 'reserveSeats',
                builder: (context, state) {
                  final showId = state.pathParameters['showId']!;
                  return ReserveSeatsScreen(showId: showId);
                },
              ),
              GoRoute(
                path: 'sold-out',
                name: 'soldOut',
                builder: (context, state) {
                  final showId = state.pathParameters['showId']!;
                  return SoldOutScreen(showId: showId);
                },
              ),
            ],
          ),

          // --- Reservation Detail (independent of tabs, nav stays) ---
          GoRoute(
            path: '/reservation/:reservationId',
            name: 'reservationDetail',
            builder: (context, state) {
              final reservationId = state.pathParameters['reservationId']!;
              return ReservationDetailScreen(reservationId: reservationId);
            },
          ),
        ],
      ),

      // ============================================
      // Full Screen Routes (outside shell - no bottom nav)
      // ============================================
      GoRoute(
        path: Routes.reservationSuccess,
        name: 'reservationSuccess',
        builder: (context, state) => const ReservationSuccessScreen(),
      ),
      GoRoute(
        path: Routes.error,
        name: 'error',
        builder: (context, state) => const ErrorScreen(),
      ),
    ],
  );
});
