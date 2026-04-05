import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';

/// SeatsAvailabilityBanner — shared between booking screen and show detail screen.
/// FIX: Brand-tokenised seats banner — secondary for available, error for urgency/sold-out.
class SeatsAvailabilityBanner extends StatelessWidget {
  final int seatsLeft;
  final String availableLabel;
  final String soldOutLabel;

  const SeatsAvailabilityBanner({
    super.key,
    required this.seatsLeft,
    required this.availableLabel,
    required this.soldOutLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft == 0;
    // FIX: Urgency threshold <10 → error tokens
    final isUrgent = seatsLeft > 0 && seatsLeft < 10;
    final useError = isSoldOut || isUrgent;

    // FIX: Normal → secondary 12% bg + 35% border; urgency/sold-out → errorLight + error border
    final bgColor = useError
        ? AppColors.errorLight
        : AppColors.secondary.withValues(alpha: 0.12);
    final borderColor = useError
        ? AppColors.error.withValues(alpha: 0.35)
        : AppColors.secondary.withValues(alpha: 0.35);
    final iconColor = useError ? AppColors.error : AppColors.secondary;
    // FIX: secondaryDark light / secondaryLight dark via status foreground helper
    final textColor = useError
        ? AppColors.getStatusForegroundColor('rejected')
        : AppColors.getStatusForegroundColor('contacting');

    final label = isSoldOut ? soldOutLabel : availableLabel;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: (useError ? AppColors.error : AppColors.secondary)
                .withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isSoldOut
                ? Icons.event_busy_outlined
                : Icons.event_seat_outlined,
            color: iconColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
