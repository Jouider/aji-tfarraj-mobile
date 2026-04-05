import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// BookingInfoCard — "Bon à savoir" information card.
/// FIX: warningLight bg, secondary 25% border, radius 14, icon circle 36×36.
class BookingInfoCard extends StatelessWidget {
  final AppStrings s;

  const BookingInfoCard({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    // FIX: Icon color — secondaryDark light / secondaryLight dark
    final iconColor = AppColors.getStatusForegroundColor('contacting');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // FIX: warningLight bg (subtle warm tint) + secondary 25% border + radius 14
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.25)),
        // FIX: No shadow — info card feels flat/calm
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Icon circle 36×36 — secondary 15% bg, secondaryDark/Light icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info_outline, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Title — secondaryDark/Light, w700, 15px
                Text(
                  s.reserveSeatsInfoTitle,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                // FIX: Body — textSecondary, 13px, line-height 1.6
                Text(
                  s.reserveSeatsInfoBody,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.6,
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
