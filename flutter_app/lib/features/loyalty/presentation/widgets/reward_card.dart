import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/badges.dart';

/// A single reward item card.
/// Shows the reward name, required points, and whether the user can redeem it.
/// For MVP, all rewards display a "Bientôt disponible" badge.
class RewardCard extends StatelessWidget {
  final String title;
  final int requiredPoints;
  final int currentBalance;
  final IconData icon;
  final String comingSoonLabel;

  const RewardCard({
    super.key,
    required this.title,
    required this.requiredPoints,
    required this.currentBalance,
    this.icon = Icons.card_giftcard,
    this.comingSoonLabel = 'Bientôt disponible',
  });

  bool get _isUnlocked => currentBalance >= requiredPoints;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: _isUnlocked ? 1.0 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: _isUnlocked ? AppColors.secondary : AppColors.border,
            width: _isUnlocked ? 1.5 : 1.0,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _isUnlocked
                    ? AppColors.secondaryLight.withValues(alpha: 0.3)
                    : AppColors.backgroundGrey,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                color:
                    _isUnlocked ? AppColors.secondaryDark : AppColors.textMuted,
                size: AppSpacing.iconLg,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Title + points
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.labelLarge),
                  const SizedBox(height: 2),
                  Text(
                    '$requiredPoints pts',
                    style: AppTypography.bodySmall.copyWith(
                      color: _isUnlocked
                          ? AppColors.secondary
                          : AppColors.textMuted,
                      fontWeight: AppTypography.medium,
                    ),
                  ),
                ],
              ),
            ),
            // Coming soon badge
            AppBadge.info(comingSoonLabel),
          ],
        ),
      ),
    );
  }
}
