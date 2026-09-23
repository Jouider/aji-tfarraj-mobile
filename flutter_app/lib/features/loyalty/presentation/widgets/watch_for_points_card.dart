import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';

/// « Gagne des points en vidéo » : la seule publicité que le membre déclenche
/// lui-même.
///
/// Elle annonce ce qu'elle rapporte et ce qu'il en reste aujourd'hui, puis
/// disparaît quand le quota est atteint — une proposition qu'on ne peut plus
/// accepter n'a rien à faire à l'écran.
class WatchForPointsCard extends StatelessWidget {
  const WatchForPointsCard({
    super.key,
    required this.status,
    required this.strings,
    required this.onWatch,
    this.busy = false,
  });

  final AdRewardStatus status;
  final AppStrings strings;
  final VoidCallback onWatch;

  /// La vidéo est en train de se charger ou de se jouer.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: AppColors.secondary,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(strings.adRewardTitle, style: AppTypography.labelLarge),
                const SizedBox(height: 2),
                Text(
                  strings.adRewardPoints(status.points),
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (status.remainingToday > 0)
                  Text(
                    strings.adRewardRemaining(status.remainingToday),
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: onWatch,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  ),
                  child: Text(strings.adRewardWatch),
                ),
        ],
      ),
    );
  }
}
