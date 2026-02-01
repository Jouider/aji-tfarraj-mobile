import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// App Shell with Bottom Navigation Bar
/// Contains the main navigation tabs: Home, MyReservations, Ticket, Profile
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: Colors.black87,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Émissions', // TODO: Add localization
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Réservations', // TODO: Add localization
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Billet', // TODO: Add localization
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil', // TODO: Add localization
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith(Routes.home)) {
      return 0;
    }
    if (location.startsWith(Routes.myReservations) || 
        location.startsWith(Routes.reservation)) {
      return 1;
    }
    if (location.startsWith(Routes.ticket)) {
      return 2;
    }
    if (location.startsWith(Routes.profile)) {
      return 3;
    }
    // Show detail pages - keep Home tab selected
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
        context.go(Routes.myReservations);
        break;
      case 2:
        context.go(Routes.ticket);
        break;
      case 3:
        context.go(Routes.profile);
        break;
    }
  }
}
