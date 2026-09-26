import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// Les deux façons de signer l'app.
enum AppLogoVariant {
  /// Le logotype complet : le symbole, « tfarraj », et la signature
  /// « Koun f l'Action ». Pour les moments de présentation — l'écran de
  /// lancement, la connexion, le choix de la langue —, là où il a la place de
  /// se déployer et où rien ne lui dispute l'attention.
  lockup,

  /// Le symbole seul. Pour une barre de navigation.
  ///
  /// La signature fait 6 pixels de haut dans une barre de 56 : elle n'est plus
  /// une signature, c'est une bavure. Le symbole, lui, reste net à 30 px — et
  /// c'est exactement ce que le membre vient de toucher sur son écran
  /// d'accueil, donc il le reconnaît sans avoir à le lire.
  mark,
}

/// Le logo Aji Tfarraj, dans la bonne langue et sur le bon fond.
///
/// Ce composant existe parce que les sept écrans qui affichent le logo
/// recopiaient tous le même choix à quatre branches — langue × thème — et que
/// l'un d'eux s'était trompé de dimension : `height: 130` dans une barre de
/// 56 points, sur une image carrée de 2000 × 2000 dont le logo n'occupe que le
/// milieu. L'app affichait donc une bande découpée au hasard dans un carré
/// presque vide.
///
/// **Le symbole n'a qu'un seul fichier** : il est en dégradé orange, il ne
/// change pas avec le thème. Seul le logotype en a deux, parce que son
/// « tfarraj » est blanc sur fond sombre et noir sur fond clair.
class AppLogo extends ConsumerWidget {
  const AppLogo({
    super.key,
    this.variant = AppLogoVariant.lockup,
    this.width,
    this.height,
    this.semanticLabel = 'Aji Tfarraj',
  });

  final AppLogoVariant variant;

  /// Donnez l'une ou l'autre, pas les deux : le logo garde ses proportions.
  final double? width;
  final double? height;

  final String semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = switch (variant) {
      AppLogoVariant.mark => 'assets/images/ajitfarraj_logo/mark.png',
      AppLogoVariant.lockup => _lockupFor(
          isArabic: ref.watch(localeProvider) == AppLocale.ar,
          onDark: AppColors.isDark,
        ),
    };

    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
  }

  /// Le nom du fichier dit sur quoi il se pose, pas de quelle couleur il est :
  /// « blanc » et « noir » se lisaient dans les deux sens, et un appelant sur
  /// deux se trompait.
  static String _lockupFor({required bool isArabic, required bool onDark}) {
    final lang = isArabic ? 'ar' : 'fr';
    final ground = onDark ? 'dark' : 'light';

    return 'assets/images/ajitfarraj_logo/lockup_${lang}_on_$ground.png';
  }
}

/// Le titre d'un onglet : le symbole, puis le nom de l'écran.
///
/// La même composition que l'accueil une fois défilé, et pour la même raison :
/// la marque ouvre la ligne, le nom dit où l'on est, les gestes ferment à
/// l'autre bout. Un titre centré entre un nombre inégal d'icônes se lit
/// toujours comme décalé ; au bord, la question ne se pose pas.
///
/// À poser avec `centerTitle: false` et `titleSpacing: AppSpacing.lg` — sur
/// iOS, Flutter centre le titre par défaut.
class AppBarBrandTitle extends StatelessWidget {
  const AppBarBrandTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppLogo(variant: AppLogoVariant.mark, height: 28),
        const SizedBox(width: AppSpacing.sm),
        // `h3` et pas un style écrit sur place : deux de ces écrans
        // demandaient 18 px en w700 dans la police du système, un troisième
        // le jeton. Trois onglets, deux typographies.
        Flexible(
          child: Text(
            title,
            style: AppTypography.h3,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
