import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/components/glass_nav_bar.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/ads/data/ads_service.dart';

/// App Shell with Bottom Navigation Bar — preserves tab state via StatefulShellRoute.
/// Tabs: Émissions (0) | Explorer (1) | Réservations (2) | Billet (3) | Profil (4)
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    // La publicité démarre en coulisse dès que le serveur l'allume.
    ref.watch(adsWarmUpProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // Le contenu passe SOUS la barre : une pilule qui flotte au-dessus d'une
      // bande vide ne flotte pas, elle est posée sur un socle.
      extendBody: true,
      body: navigationShell,
      // FIX: Bottom Navigation Bar — pill active indicator, secondary color
      bottomNavigationBar: GlassNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        items: [
          GlassNavItem(
            icon: Icons.movie_outlined,
            activeIcon: Icons.movie,
            label: s.navTabEmissions,
          ),
          GlassNavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: s.navTabExplorer,
          ),
          GlassNavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: s.navTabReservations,
          ),
          GlassNavItem(
            icon: Icons.confirmation_number_outlined,
            activeIcon: Icons.confirmation_number,
            label: s.navTabTicket,
          ),
          GlassNavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: s.navTabProfile,
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
