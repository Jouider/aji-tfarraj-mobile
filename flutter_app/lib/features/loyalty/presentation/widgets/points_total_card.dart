import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';

/// Large card showing the user's total points balance
class PointsTotalCard extends StatelessWidget {
  final int balance;
  final String subtitle;

  const PointsTotalCard({
    super.key,
    required this.balance,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      backgroundColor: AppColors.primary,
      child: Column(
        children: [
          const Icon(
            Icons.star_rounded,
            size: AppSpacing.iconXxl,
            color: AppColors.secondaryLight,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '$balance',
            style: AppTypography.h1.copyWith(
              fontSize: 48,
              color: AppColors.backgroundWhite,
              fontWeight: AppTypography.semiBold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'POINTS',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.backgroundWhite.withValues(alpha: 0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.backgroundWhite.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
