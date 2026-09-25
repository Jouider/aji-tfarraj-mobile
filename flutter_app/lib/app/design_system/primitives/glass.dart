import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Une capsule en verre : translucide, floutée, posée sur ce qu'il y a
/// derrière.
///
/// Sa raison d'être : sur une affiche, une pastille pleine et colorée entre en
/// concurrence avec le bouton d'à côté — même taille, même saturation, et
/// l'œil ne sait plus lequel agit. Le verre laisse passer l'image, reste
/// lisible, et dit clairement « je suis une information, pas un geste ».
///
/// Même matière que la barre du bas, donc même vocabulaire d'un bout à l'autre
/// de l'écran.
///
/// Le flou se recalcule à chaque image : à réserver aux éléments posés sur une
/// image, jamais en liste.
class GlassPill extends StatelessWidget {
  const GlassPill({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 10,
    ),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Facultatif : une capsule sans geste reste une étiquette.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            // Voile sombre, comme la barre : le flou seul laisse passer les
            // couleurs de l'affiche et le texte s'y noie.
            color: Colors.black.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: child,
        ),
      ),
    );

    if (onTap == null) return pill;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

/// L'étiquette d'une chaîne, ou tout badge court posé sur l'orange de marque.
///
/// L'orange vif reste — c'est lui qui se voit de loin — mais l'encre passe au
/// sombre : en blanc, ces majuscules de 10 px ne mesuraient que 3,1:1.
class BrandBadge extends StatelessWidget {
  const BrandBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.onSecondary,
        ),
      ),
    );
  }
}
