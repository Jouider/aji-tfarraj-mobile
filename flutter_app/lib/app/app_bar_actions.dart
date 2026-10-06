import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/tutorials/presentation/tutorial_widgets.dart';

/// Les trois gestes qu'on doit pouvoir faire depuis n'importe quel onglet :
/// écrire au support, revoir un tutoriel, ouvrir ses notifications.
///
/// Ils ne vivaient qu'à l'accueil. Un membre qui bute sur l'écran de
/// réservation devait donc revenir en arrière pour trouver l'aide — au moment
/// précis où il en a besoin.
///
/// **Aucune de ces icônes ne fixe sa couleur.** Elles prennent celle de
/// l'`IconTheme` ambiant, ce qui leur permet de suivre une barre qui change —
/// blanche sur une affiche, sombre sur du verre clair.
class AppBarActions extends ConsumerWidget {
  const AppBarActions({super.key, this.showSupport = true});

  /// L'écran du support lui-même n'a pas besoin d'un raccourci vers lui-même.
  final bool showSupport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showSupport)
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.headset_mic_outlined),
                // Une réponse du support pas encore lue : un point, pas un
                // chiffre — la cloche porte déjà les chiffres.
                if ((ref.watch(supportUnreadProvider).valueOrNull ?? 0) > 0)
                  const Positioned(
                    right: -2,
                    top: -2,
                    child: SizedBox(
                      width: 10,
                      height: 10,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: ref.watch(stringsProvider).supportChat.listTitle,
            // Par le routeur, au-dessus des onglets : une conversation ne
            // vit pas sous la barre d'onglets flottante.
            onPressed: () async {
              await context.push(Routes.support);
              ref.invalidate(supportUnreadProvider);
            },
          ),
        const TutorialHelpAction(),
        const NotificationBellButton(),
        const SizedBox(width: AppSpacing.xs),
      ],
    );
  }
}

/// La cloche, et sa pastille de non-lus.
///
/// Elle lit le compteur elle-même : le faire descendre en paramètre obligeait
/// chaque écran à connaître un provider qui ne le regarde pas.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationsCountProvider);
    final s = ref.watch(stringsProvider);

    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          // Sans couleur : elle prend celle de la barre, qui change selon
          // qu'on est sur l'affiche ou sur le verre.
          const Icon(Icons.notifications_outlined),
          if (unread > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  unread > 99 ? '99+' : unread.toString(),
                  // L'or ne porte pas le blanc : 2,1:1. Cette pastille est un
                  // aplat doré, son encre est sombre.
                  style: const TextStyle(
                    color: AppColors.onSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: s.homeNotificationsTooltip,
      onPressed: () => context.push(Routes.notifications),
    );
  }
}
