import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/app_shell.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/splash/splash_screen.dart';
import 'package:aji_tfarraj/features/language/language_selection_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/auth_landing_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/login_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/register_screen.dart';
import 'package:aji_tfarraj/features/auth/presentation/forgot_password_screen.dart';
import 'package:aji_tfarraj/features/home/home_screen.dart';
import 'package:aji_tfarraj/features/show/show_detail_screen.dart';
import 'package:aji_tfarraj/features/reservation/reserve_seats_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_success_screen.dart';
import 'package:aji_tfarraj/features/reservation/my_reservations_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_detail_screen.dart';
import 'package:aji_tfarraj/features/ticket/ticket_screen.dart';
import 'package:aji_tfarraj/features/profile/profile_screen.dart';
import 'package:aji_tfarraj/features/profile/presentation/edit_profile_screen.dart';
import 'package:aji_tfarraj/features/error/error_screen.dart';
import 'package:aji_tfarraj/features/show/sold_out_screen.dart';
import 'package:aji_tfarraj/features/reservation/reservation_result_screen.dart';
import 'package:aji_tfarraj/features/notifications/presentation/notification_center_screen.dart';
import 'package:aji_tfarraj/features/loyalty/presentation/loyalty_screen.dart';
import 'package:aji_tfarraj/features/shows/presentation/shows_browse_screen.dart';
import 'package:aji_tfarraj/features/staff/presentation/staff_check_in_screen.dart';
import 'package:aji_tfarraj/features/profile/presentation/rules_screen.dart';
import 'package:aji_tfarraj/features/rewards/presentation/rewards_screen.dart';
import 'package:aji_tfarraj/features/rewards/presentation/my_rewards_screen.dart';
import 'package:aji_tfarraj/features/referral/presentation/referral_landing_screen.dart';
import 'package:aji_tfarraj/features/referral/presentation/referral_stats_screen.dart';
import 'package:aji_tfarraj/features/referral/presentation/my_referral_links_screen.dart';

/// Routes that require authentication
const _protectedRoutes = [
  Routes.home,
  Routes.browse,
  Routes.myReservations,
  Routes.ticket,
  Routes.profile,
  Routes.notifications,
  Routes.loyalty,
  Routes.rewards,
  Routes.myRewards,
  Routes.staffCheckIn,
  Routes.referralStats,
  Routes.referralLinks,
];

/// Routes that should redirect to home if already authenticated
const _authRoutes = [
  Routes.authLanding,
  Routes.login,
  Routes.register,
  Routes.forgotPassword,
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
      final isProtectedRoute = _protectedRoutes.any(
          (route) => currentPath == route || currentPath.startsWith('$route/'));

      // Also protect show detail and reservation routes
      final isShowRoute = currentPath.startsWith('/show/');
      final isReservationRoute = currentPath.startsWith('/reservation/');
      // /r/{token} is public — no auth required for referral landing
      final isReferralLanding = currentPath.startsWith('/r/');
      final needsAuth =
          (isProtectedRoute || isShowRoute || isReservationRoute) &&
              !isReferralLanding;

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

      // If not authenticated and trying to access protected route -> redirect to landing
      if (!isAuthenticated && needsAuth) {
        return Routes.authLanding;
      }

      // If authenticated but not staff, block staff check-in route
      if (isAuthenticated && currentPath == Routes.staffCheckIn) {
        final user = ref.read(loginAuthStateProvider).user;
        if (user != null && !user.isStaffOrAdmin) {
          return Routes.home;
        }
      }

      // If authenticated and trying to access login/register -> redirect to home
      if (isAuthenticated && isAuthRoute) {
        return Routes.home;
      }

      // If authenticated but profile is incomplete -> redirect to edit profile
      // (except when already on the edit profile screen to avoid redirect loops)
      if (isAuthenticated && currentPath != Routes.editProfile) {
        final user = ref.read(loginAuthStateProvider).user;
        // Exclude photo and phone fields — these are optional until reservation
        // (phone verification enforcement happens server-side via 409 PROFILE_INCOMPLETE)
        const optionalFields = {
          'avatar', 'avatar_url', 'live_photo_captured_at',
          'phone_verified_at',
        };
        final missingRequired = user?.missingProfileFields
                .where((f) => !optionalFields.contains(f))
                .isNotEmpty ??
            false;
        if (user != null && !user.profileComplete && missingRequired) {
          return Routes.editProfile;
        }
      }

      // No redirect needed
      return null;
    },
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
        path: Routes.authLanding,
        name: 'authLanding',
        builder: (context, state) => const AuthLandingScreen(),
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
      GoRoute(
        path: Routes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ============================================
      // Shell Route — StatefulShellRoute preserves each tab's navigation
      // stack and scroll position when switching between tabs.
      // ============================================
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // ── Branch 0: Home + Show detail flows ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.home,
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
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
                    path: 'episode/:episodeId/reserve',
                    name: 'reserveEpisode',
                    builder: (context, state) {
                      final showId = state.pathParameters['showId']!;
                      final episodeId = state.pathParameters['episodeId']!;
                      return ReserveSeatsScreen(
                        showId: showId,
                        episodeId: episodeId,
                      );
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
              GoRoute(
                path: '/reservation/:reservationId',
                name: 'reservationDetail',
                builder: (context, state) {
                  final reservationId = state.pathParameters['reservationId']!;
                  return ReservationDetailScreen(reservationId: reservationId);
                },
              ),
              GoRoute(
                path: Routes.editProfile,
                name: 'editProfile',
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),

          // ── Branch 1: Browse ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.browse,
                name: 'browse',
                builder: (context, state) => const ShowsBrowseScreen(),
              ),
            ],
          ),

          // ── Branch 2: My Reservations ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myReservations,
                name: 'myReservations',
                builder: (context, state) => const MyReservationsScreen(),
              ),
            ],
          ),

          // ── Branch 3: Ticket ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ticket,
                name: 'ticket',
                builder: (context, state) => const TicketScreen(),
              ),
            ],
          ),

          // ── Branch 4: Profile ──
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
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
        builder: (context, state) {
          final message = state.extra is String ? state.extra as String : null;
          return ErrorScreen(message: message);
        },
      ),
      GoRoute(
        path: Routes.staffCheckIn,
        name: 'staffCheckIn',
        builder: (context, state) => const StaffCheckInScreen(),
      ),
      GoRoute(
        path: Routes.rules,
        name: 'rules',
        builder: (context, state) => const RulesScreen(),
      ),
      GoRoute(
        path: Routes.rewards,
        name: 'rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: Routes.myRewards,
        name: 'myRewards',
        builder: (context, state) => const MyRewardsScreen(),
      ),

      // ============================================
      // Referral Routes
      // ============================================
      GoRoute(
        path: '/r/:token',
        name: 'referralLanding',
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return ReferralLandingScreen(token: token);
        },
      ),
      GoRoute(
        path: Routes.referralStats,
        name: 'referralStats',
        builder: (context, state) => const ReferralStatsScreen(),
      ),
      GoRoute(
        path: Routes.referralLinks,
        name: 'referralLinks',
        builder: (context, state) => const MyReferralLinksScreen(),
      ),
    ],
  );
});
