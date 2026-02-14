import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/app_shell.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/auth/token_storage.dart';
import 'package:aji_tfarraj/features/splash/splash_screen.dart';
import 'package:aji_tfarraj/features/language/language_selection_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/login_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/register_screen.dart';
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
import 'package:aji_tfarraj/app/design_system/demo_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_result_screen.dart';
import 'package:aji_tfarraj/features/notifications/presentation/notification_center_screen.dart';
import 'package:aji_tfarraj/features/loyalty/presentation/loyalty_screen.dart';

/// Routes that require authentication
const _protectedRoutes = [
  Routes.home,
  Routes.myReservations,
  Routes.ticket,
  Routes.profile,
  Routes.notifications,
  Routes.loyalty,
];

/// Routes that should redirect to home if already authenticated
const _authRoutes = [
  Routes.login,
  Routes.register,
];

/// Listenable that triggers router refresh on auth state changes
class AuthNotifierListenable extends ChangeNotifier {
  AuthNotifierListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = AuthNotifierListenable(ref);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentPath = state.matchedLocation;

      // Check if trying to access a protected route
      final isProtectedRoute = _protectedRoutes.any((route) => 
          currentPath == route || currentPath.startsWith('$route/'));
      
      // Also protect show detail and reservation routes
      final isShowRoute = currentPath.startsWith('/show/');
      final isReservationRoute = currentPath.startsWith('/reservation/');
      final needsAuth = isProtectedRoute || isShowRoute || isReservationRoute;
      
      // Check if trying to access auth routes (login/register) while authenticated
      final isAuthRoute = _authRoutes.contains(currentPath);

      // Determine authentication status
      // For AsyncValue: check if we have a non-null, non-empty token
      final bool isAuthenticated;
      if (authState.isLoading) {
        // Still loading - don't redirect yet, let the current navigation proceed
        // The router will refresh when loading completes
        return null;
      } else if (authState.hasError) {
        // Error reading token - treat as not authenticated
        isAuthenticated = false;
      } else {
        // Check if token exists and is not empty
        final token = authState.valueOrNull;
        isAuthenticated = token != null && token.isNotEmpty;
      }

      // If not authenticated and trying to access protected route -> redirect to login
      if (!isAuthenticated && needsAuth) {
        return Routes.login;
      }

      // If authenticated and trying to access login/register -> redirect to home
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      // No redirect needed
      return null;
    },
    routes: [
      // ============================================
      // Design System Demo (for development)
      // ============================================
      GoRoute(
        path: '/design-system',
        name: 'designSystem',
        builder: (context, state) => const DesignSystemDemoScreen(),
      ),

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
      GoRoute(
        path: Routes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
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
        path: Routes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationCenterScreen(),
      ),
      GoRoute(
        path: Routes.loyalty,
        name: 'loyalty',
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: Routes.reservationSuccess,
        name: 'reservationSuccess',
        builder: (context, state) => const ReservationSuccessScreen(),
      ),
      GoRoute(
        path: '/reservation-result/:reservationId',
        name: 'reservationResult',
        builder: (context, state) {
          final reservationId = state.pathParameters['reservationId']!;
          return ReservationResultScreen(reservationId: reservationId);
        },
      ),
      GoRoute(
        path: Routes.error,
        name: 'error',
        builder: (context, state) => const ErrorScreen(),
      ),
    ],
  );
});
