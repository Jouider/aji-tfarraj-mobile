import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// App Shell with Bottom Navigation Bar — dark premium styling
/// Tabs: Émissions (0) | Explorer (1) | Réservations (2) | Billet (3) | Profil (4)
class AppShell extends ConsumerWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundWhite,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.backgroundWhite,
          currentIndex: _calculateSelectedIndex(context),
          onTap: (index) => _onItemTapped(index, context),
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.textLight,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.movie_outlined),
              activeIcon: const Icon(Icons.movie),
              label: s.navTabEmissions,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: s.navTabExplorer,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.calendar_today_outlined),
              activeIcon: const Icon(Icons.calendar_today),
              label: s.navTabReservations,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.confirmation_number_outlined),
              activeIcon: const Icon(Icons.confirmation_number),
              label: s.navTabTicket,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: s.navTabProfile,
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(Routes.home)) {
      return 0;
    }
    if (location.startsWith(Routes.browse)) {
      return 1;
    }
    if (location.startsWith(Routes.myReservations) ||
        location.startsWith(Routes.reservation)) {
      return 2;
    }
    if (location.startsWith(Routes.ticket)) {
      return 3;
    }
    if (location.startsWith(Routes.profile)) {
      return 4;
    }
    // Show detail pages — keep Home tab selected
    if (location.startsWith(Routes.show)) {
      return 0;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.browse);
        break;
      case 2:
        context.go(Routes.myReservations);
        break;
      case 3:
        context.go(Routes.ticket);
        break;
      case 4:
        context.go(Routes.profile);
        break;
    }
  }
}
