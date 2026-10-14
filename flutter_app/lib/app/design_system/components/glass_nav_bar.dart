import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';

/// La barre d'onglets de l'app : une pilule de verre qui flotte au-dessus du
/// contenu. Partagée par l'espace public (`AppShell`) et le mode chargé
/// public, pour que les deux soient la même app.
///
/// À poser dans `Scaffold.bottomNavigationBar` avec `extendBody: true`, et à
/// laisser de la place sous le contenu : `AppSpacing.navBarClearance`.

class GlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class GlassNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottom > 0 ? bottom : 12),
      // L'ombre se pose AVANT le ClipRRect : ce qui est coupé ne projette
      // rien. En thème clair, c'est elle qui décolle une pilule blanche d'une
      // page blanche.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          boxShadow: AppShadows.glass,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          // Le verre : le contenu de la page se devine derrière la barre au
          // lieu de s'arrêter net. Le flou se recalcule à chaque image —
          // c'est le geste le plus cher de l'interface, et la raison pour
          // laquelle le rayon reste modéré.
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 62,
              decoration: BoxDecoration(
                // Un voile teinté, pas du verre nu : le flou seul laisse
                // passer les couleurs d'une affiche et les libellés s'y
                // noient. C'est ce que fait WhatsApp.
                //
                // Et il suit le thème. Le voile noir posé sur une page
                // blanche ne faisait pas du verre, il faisait une plaque
                // grise sale.
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  return _GlassNavButton(
                    data: items[index],
                    isActive: currentIndex == index,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavButton extends StatelessWidget {
  final GlassNavItem data;
  final bool isActive;
  final VoidCallback onTap;

  const _GlassNavButton({
    required this.data,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Plus clair qu'ailleurs dans l'app : ce texte repose sur du verre, donc
    // sur ce qui défile derrière, et le gris discret n'y survit pas.
    //
    // `glassAccent` n'est pas toujours l'or de la charte : sur du verre blanc
    // il s'efface, et c'est l'orange sombre des boutons qui prend le relais.
    final color = isActive ? AppColors.glassAccent : AppColors.textSecondary;

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
              color: isActive ? AppColors.glassHighlight : Colors.transparent,
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
