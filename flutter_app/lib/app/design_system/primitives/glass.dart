import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';

/// Ce qu'il y a DERRIÈRE le verre — et c'est ça qui décide de sa teinte.
///
/// Le verre n'a pas de couleur à lui : il ne fait que teinter ce qu'on voit à
/// travers. La seule question utile est donc « posé sur quoi ? ».
enum GlassTone {
  /// Sur une photo. Le voile reste sombre dans les deux thèmes.
  ///
  /// Une photo n'a pas de thème : elle est sombre ou claire selon ce qu'elle
  /// montre, jamais selon le réglage du téléphone. L'encre écrite dessus est
  /// blanche, et elle a besoin d'un voile sombre des deux côtés.
  onPhoto,

  /// Sur la page. Le voile prend la couleur du thème.
  ///
  /// Un voile noir sur une page blanche ne fait pas du verre, il fait une
  /// plaque grise sale. En thème clair, le verre est blanc.
  onPage,
}

extension _GlassColors on GlassTone {
  Color get surface =>
      this == GlassTone.onPhoto ? AppColors.glassOnPhoto : AppColors.glassSurface;

  Color get border => this == GlassTone.onPhoto
      ? AppColors.glassOnPhotoBorder
      : AppColors.glassBorder;
}

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
    this.tone = GlassTone.onPage,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 10,
    ),
    this.onTap,
  });

  final Widget child;

  /// Sur quoi la capsule est posée. Voir [GlassTone] — ce n'est pas un détail
  /// esthétique, c'est ce qui rend l'encre lisible ou non.
  final GlassTone tone;

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
            color: tone.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            border: Border.all(color: tone.border),
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

/// L'étiquette d'une chaîne : du verre, posé sur l'affiche.
///
/// L'orange lui allait mal — sur cet écran, l'orange est la couleur de ce qui
/// agit, et une chaîne ne se touche pas. En verre, elle informe sans réclamer
/// le geste, et elle laisse voir l'image dessous.
///
/// En capsule comme [GlassPill] : tout ce qui est en verre appartient à la
/// même famille. La forme ne dit pas ce qui se touche — la pastille des
/// places est une capsule et n'est pas tapable non plus. Ce qui distingue un
/// geste d'une information, ici, c'est l'aplat orange, et il n'y en a qu'un
/// par écran.
///
/// Toujours [GlassTone.onPhoto] : une étiquette de chaîne ne vit que sur une
/// affiche, et son encre est blanche. En blanc sur une affiche claire, elle
/// disparaîtrait.
///
/// Volontairement SANS flou, contrairement à [GlassPill] : une liste en montre
/// une demi-douzaine à la fois, et une couche de flou par badge est
/// exactement ce qui fait tomber le défilement sur un Android d'entrée de
/// gamme. À cette taille, c'est le voile sombre qui fait tout le travail —
/// le flou ne s'y verrait pas.
class ChannelBadge extends StatelessWidget {
  const ChannelBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.glassOnPhotoSolid,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.glassOnPhotoBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Color(0xFFF7F8F8),
        ),
      ),
    );
  }
}
