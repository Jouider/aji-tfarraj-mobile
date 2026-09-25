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
  static List<BoxShadow> get card => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.45),
          blurRadius: 24,
          offset: const Offset(0, 10),
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
