// FEATURE: Support Tickets - Status Banner Widget
import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// Full-width status banner shown at the top of the ticket detail screen.
class TicketStatusBanner extends StatelessWidget {
  final String status; // 'open' | 'in_progress' | 'closed'
  final AppStrings s;

  const TicketStatusBanner({super.key, required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    final config = _bannerConfig(status, s);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: config.iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, size: 28, color: config.fg),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            config.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: config.fg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            config.message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  static _BannerConfig _bannerConfig(String status, AppStrings s) {
    switch (status) {
      case 'in_progress':
        return _BannerConfig(
          bg: AppColors.primary.withValues(alpha: 0.08),
          borderColor: AppColors.primary.withValues(alpha: 0.25),
          iconBg: AppColors.primary.withValues(alpha: 0.20),
          icon: Icons.phone_in_talk,
          fg: AppColors.primary,
          title: s.supportBannerInProgressTitle,
          message: s.supportBannerInProgressMsg,
        );
      case 'closed':
        return _BannerConfig(
          bg: AppColors.infoLight,
          borderColor: AppColors.info.withValues(alpha: 0.30),
          iconBg: AppColors.info.withValues(alpha: 0.20),
          icon: Icons.check_circle_outline,
          fg: AppColors.textMuted,
          title: s.supportBannerClosedTitle,
          message: s.supportBannerClosedMsg,
        );
      default: // 'open'
        final warningText = AppColors.getStatusForegroundColor('contacting');
        return _BannerConfig(
          bg: AppColors.warningLight,
          borderColor: AppColors.warning,
          iconBg: AppColors.warning.withValues(alpha: 0.20),
          icon: Icons.hourglass_empty,
          fg: warningText,
          title: s.supportBannerOpenTitle,
          message: s.supportBannerOpenMsg,
        );
    }
  }
}

class _BannerConfig {
  final Color bg;
  final Color borderColor;
  final Color iconBg;
  final IconData icon;
  final Color fg;
  final String title;
  final String message;

  const _BannerConfig({
    required this.bg,
    required this.borderColor,
    required this.iconBg,
    required this.icon,
    required this.fg,
    required this.title,
    required this.message,
  });
}
