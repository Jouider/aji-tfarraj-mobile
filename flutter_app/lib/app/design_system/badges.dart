import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

/// Status types for badges
enum StatusType {
  pendingReview,
  contacting,
  approved,
  rejected,
  cancelled,
  expired,
  checkedIn,
}

/// Aji Tfarraj Badge/Chip Components
class AppBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  /// Factory for status badges
  factory AppBadge.status(StatusType status, {String? customText}) {
    final config = _getStatusConfig(status);
    return AppBadge(
      text: customText ?? config.defaultText,
      backgroundColor: config.backgroundColor,
      textColor: config.textColor,
      icon: config.icon,
    );
  }

  /// Success badge (approved, checked_in)
  factory AppBadge.success(String text) => AppBadge(
        text: text,
        backgroundColor: AppColors.successLight,
        textColor: AppColors.successDark,
      );

  /// Warning badge (pending, contacting)
  factory AppBadge.warning(String text) => AppBadge(
        text: text,
        backgroundColor: AppColors.warningLight,
        textColor: AppColors.warningDark,
      );

  /// Error badge (rejected, expired)
  factory AppBadge.error(String text) => AppBadge(
        text: text,
        backgroundColor: AppColors.errorLight,
        textColor: AppColors.errorDark,
      );

  /// Info badge (cancelled, neutral)
  factory AppBadge.info(String text) => AppBadge(
        text: text,
        backgroundColor: AppColors.infoLight,
        textColor: AppColors.infoDark,
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AppSpacing.iconSm, color: textColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status configuration helper
class _StatusConfig {
  final String defaultText;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const _StatusConfig({
    required this.defaultText,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });
}

_StatusConfig _getStatusConfig(StatusType status) {
  switch (status) {
    case StatusType.pendingReview:
      return const _StatusConfig(
        defaultText: 'En attente',
        backgroundColor: AppColors.warningLight,
        textColor: AppColors.warningDark,
        icon: Icons.schedule,
      );
    case StatusType.contacting:
      return const _StatusConfig(
        defaultText: 'En cours de contact',
        backgroundColor: AppColors.warningLight,
        textColor: AppColors.warningDark,
        icon: Icons.phone_outlined,
      );
    case StatusType.approved:
      return const _StatusConfig(
        defaultText: 'Confirmée',
        backgroundColor: AppColors.successLight,
        textColor: AppColors.successDark,
        icon: Icons.check_circle_outline,
      );
    case StatusType.rejected:
      return const _StatusConfig(
        defaultText: 'Refusée',
        backgroundColor: AppColors.errorLight,
        textColor: AppColors.errorDark,
        icon: Icons.cancel_outlined,
      );
    case StatusType.cancelled:
      return const _StatusConfig(
        defaultText: 'Annulée',
        backgroundColor: AppColors.infoLight,
        textColor: AppColors.infoDark,
        icon: Icons.block,
      );
    case StatusType.expired:
      return const _StatusConfig(
        defaultText: 'Expirée',
        backgroundColor: AppColors.errorLight,
        textColor: AppColors.errorDark,
        icon: Icons.timer_off_outlined,
      );
    case StatusType.checkedIn:
      return const _StatusConfig(
        defaultText: 'Entrée validée',
        backgroundColor: AppColors.successLight,
        textColor: AppColors.successDark,
        icon: Icons.verified_outlined,
      );
  }
}

/// Get StatusType from API string key
StatusType? statusTypeFromKey(String key) {
  switch (key) {
    case 'pending_review':
      return StatusType.pendingReview;
    case 'contacting':
      return StatusType.contacting;
    case 'approved':
      return StatusType.approved;
    case 'rejected':
      return StatusType.rejected;
    case 'cancelled':
      return StatusType.cancelled;
    case 'expired':
      return StatusType.expired;
    case 'checked_in':
      return StatusType.checkedIn;
    default:
      return null;
  }
}
