import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// App Shell with Bottom Navigation Bar — preserves tab state via StatefulShellRoute.
/// Tabs: Émissions (0) | Explorer (1) | Réservations (2) | Billet (3) | Profil (4)
class AppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // Le contenu passe SOUS la barre : une pilule qui flotte au-dessus d'une
      // bande vide ne flotte pas, elle est posée sur un socle.
      extendBody: true,
      body: navigationShell,
      // FIX: Bottom Navigation Bar — pill active indicator, secondary color
      bottomNavigationBar: _AppNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onItemTapped,
        items: [
          _NavItemData(
            icon: Icons.movie_outlined,
            activeIcon: Icons.movie,
            label: s.navTabEmissions,
          ),
          _NavItemData(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore,
            label: s.navTabExplorer,
          ),
          _NavItemData(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today,
            label: s.navTabReservations,
          ),
          _NavItemData(
            icon: Icons.confirmation_number_outlined,
            activeIcon: Icons.confirmation_number,
            label: s.navTabTicket,
          ),
          _NavItemData(
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

// ─────────────────────────────────────────────────────
// Custom Nav Bar
// ─────────────────────────────────────────────────────

class _NavItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItemData({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItemData> items;

  const _AppNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottom > 0 ? bottom : 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        // Le verre : le contenu de la page se devine derrière la barre au lieu
        // de s'arrêter net. Le flou se recalcule à chaque image — c'est le
        // geste le plus cher de l'interface, et la raison pour laquelle le
        // rayon reste modéré.
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 62,
            decoration: BoxDecoration(
              // Un voile SOMBRE, pas clair : le flou seul laisse passer les
              // couleurs d'une affiche et les libellés s'y noient. C'est ce
              // que fait WhatsApp — du verre teinté, pas du verre nu.
              color: Colors.black.withValues(alpha: 0.34),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: List.generate(items.length, (index) {
                return _NavItem(
                  data: items[index],
                  isActive: currentIndex == index,
                  onTap: () => onTap(index),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Plus clair qu'ailleurs dans l'app : ce texte repose sur du verre, donc
    // sur ce qui défile derrière, et le gris discret n'y survit pas.
    final color = isActive ? AppColors.secondary : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
          // La capsule de l'onglet actif : un verre plus clair posé sur le
          // verre. Elle englobe l'icône ET le libellé, et reste dans la barre
          // — rien ne saute, rien ne dépasse.
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.transparent,
              // Complètement arrondie, comme la pilule qui la contient : un
              // rectangle radouci au milieu d'une barre en stade jurait.
              // La moitié de la hauteur utile (62 − 12 de marge) = 25.
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? data.activeIcon : data.icon,
                  size: 21,
                  color: color,
                ),
                const SizedBox(height: 3),
                Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                    color: color,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
