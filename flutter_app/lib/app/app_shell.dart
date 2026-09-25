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

  /// De combien l'onglet actif se soulève hors de la pilule.
  static const double _lift = 12;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      // Assez d'air en haut pour que la goutte sorte sans être rognée, et en
      // bas pour que la pilule se détache du bord de l'écran.
      padding: EdgeInsets.fromLTRB(14, _lift, 14, bottom > 0 ? bottom : 12),
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: AppColors.surfaceOverlay,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
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
    final color = isActive ? AppColors.textPrimary : AppColors.textMuted;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // La goutte : l'onglet actif perle hors de la pilule. Les rayons
            // sont volontairement inégaux — plus ronds en haut, resserrés en
            // bas — pour que la forme tombe au lieu de flotter.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              transform:
                  Matrix4.translationValues(0, isActive ? -_AppNavBar._lift : 0, 0),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.hotGradient : null,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                  bottom: Radius.circular(14),
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? data.activeIcon : data.icon,
                size: 21,
                // Encre sombre sur l'orange : le blanc n'y tient pas (3,1:1).
                color: isActive ? AppColors.onPrimary : color,
              ),
            ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              offset: Offset(0, isActive ? -0.55 : 0),
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}
