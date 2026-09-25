import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';

/// Deux ombres, et pas une de plus.
///
/// L'app en portait trois familles sans le vouloir : une ombre claire héritée
/// du thème clair — strictement invisible sur fond noir —, un halo orange sur
/// certains boutons, et rien ailleurs. Une ombre qui ne se voit pas est du
/// code mort ; trois ombres différentes sur un écran, c'est du désordre.
///
/// [card] fait flotter une surface. [action] ne sert qu'au geste principal :
/// c'est ce qui le distingue de tout le reste, et c'est pour ça qu'il faut
/// s'interdire de l'utiliser ailleurs.
class AppShadows {
  AppShadows._();

  /// Sous une carte ou une feuille : diffuse, basse, jamais colorée.
  ///
  /// Et beaucoup plus discrète en thème clair. Une ombre se lit par le
  /// contraste qu'elle creuse avec la page : sur du noir il faut 45 % de noir
  /// pour qu'elle existe, sur du blanc 8 % suffisent largement. Les mêmes
  /// 45 % posés sur une page blanche donnaient un nuage sombre sous chaque
  /// carte — et, les cartes n'étant espacées que de 14 points, les nuages se
  /// rejoignaient en une plaque grise continue d'un bord à l'autre de
  /// l'écran.
  static List<BoxShadow> get card => AppColors.isDark
      ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ]
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ];

  /// Sous une surface en verre. En thème clair, une pilule blanche posée sur
  /// une page blanche n'existe pas : c'est l'ombre qui la décolle. En thème
  /// sombre, le liseré suffit et l'ombre se contente de creuser un peu.
  static List<BoxShadow> get glass => [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: AppColors.isDark ? 0.30 : 0.10,
          ),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  /// Sous le bouton principal : le halo de la marque, réservé à l'action.
  static List<BoxShadow> get action => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ];
}
