import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/badges/domain/badge.dart';

/// A polished card for a tiered badge (attendance or charge-public level):
/// medal (emoji + tier color), tier label, current count, and a progress bar
/// showing how much is left to reach the next tier.
///
/// Colors, emoji and labels come from the backend — nothing tier-specific is
/// hardcoded here.
class LevelBadgeCard extends ConsumerWidget {
  final LevelBadge badge;

  /// true → charge-public level phrasing; false → attendance phrasing.
  final bool isCp;

  const LevelBadgeCard({super.key, required this.badge, required this.isCp});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);
    final accent = badge.color ?? AppColors.secondary;

    final countText = isCp
        ? s.badgeCpCount(badge.count)
        : s.badgeAttendanceCount(badge.count);
    final remainingText = badge.isMax
        ? s.badgeMaxReached
        : (isCp
            ? s.badgeRemainingCp(badge.remaining)
            : s.badgeRemainingAttendance(badge.remaining));

    // La carte est une VRAIE surface, pas un lavis teinté.
    //
    // Un fond à 6 % et un filet à 30 % de la couleur du palier donnaient, au
    // palier zéro où cette couleur est grise, une boîte grise contenant un
    // titre gris, une pastille grise et une barre grise : cela se lisait comme
    // un élément désactivé, pas comme une distinction. La carte prend
    // maintenant la même matière que toutes les autres de la page, et la
    // couleur du palier ne sert plus qu'aux trois endroits qui la méritent —
    // la médaille, la pastille de niveau, la barre.
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Medal(emoji: badge.emoji, accent: accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        badge.localizedLabel(isAr),
                        // Le titre prend l'encre de la page, pas la couleur
                        // du palier : celle-ci pâlit d'un palier à l'autre, et
                        // le nom du rang n'a pas à pâlir avec elle.
                        style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: accent.withValues(alpha: 0.45)),
                      ),
                      child: Text(
                        s.badgeLevelShort(badge.level),
                        style: AppTypography.labelSmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(countText,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted)),
                const SizedBox(height: 10),
                if (!badge.isMax)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: badge.progress,
                      minHeight: 6,
                      // Le rail est neutre. Teinté de l'accent, il se
                      // confondait avec son propre remplissage au palier
                      // zéro — une barre qui n'avait plus ni début ni fin.
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation(accent),
                    ),
                  ),
                if (!badge.isMax) const SizedBox(height: 6),
                Text(
                  remainingText,
                  style: AppTypography.labelSmall.copyWith(
                    color: badge.isMax ? accent : AppColors.textSecondary,
                    fontWeight: badge.isMax ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Medal extends StatelessWidget {
  final String? emoji;
  final Color accent;
  const _Medal({required this.emoji, required this.accent});

  @override
  Widget build(BuildContext context) {
    // Un disque PLEIN, pas un cercle translucide.
    //
    // À 15 % d'opacité, la médaille n'était qu'un halo autour d'un emoji
    // flottant — la signature visuelle la plus sûre d'une app bâclée. Pleine,
    // elle redevient un objet posé sur la carte, et l'emoji un motif gravé
    // dessus plutôt qu'un autocollant.
    return Container(
      width: 58,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [accent, Color.lerp(accent, Colors.black, 0.28)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        // Le liseré reprend le fond de la carte : il détache le disque sans
        // ajouter une troisième couleur.
        border: Border.all(color: AppColors.backgroundLight, width: 2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.28),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        emoji ?? '🏅',
        style: const TextStyle(fontSize: 24),
      ),
    );
  }
}
