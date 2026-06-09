// FEATURE: Support Tickets - Status Badge Widget
import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// Small inline badge shown on ticket cards.
class TicketStatusBadge extends StatelessWidget {
  final String status; // 'open' | 'in_progress' | 'closed'
  final AppStrings s;

  const TicketStatusBadge({super.key, required this.status, required this.s});

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfig(status, s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.fg),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: TextStyle(
              color: config.fg,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  static _BadgeConfig _badgeConfig(String status, AppStrings s) {
    switch (status) {
      case 'in_progress':
        return _BadgeConfig(
          bg: AppColors.primary.withValues(alpha: 0.10),
          borderColor: AppColors.primary.withValues(alpha: 0.30),
          icon: Icons.phone_in_talk_outlined,
          fg: AppColors.primary,
          label: s.supportStatusInProgress,
        );
      case 'closed':
        return _BadgeConfig(
          bg: AppColors.infoLight,
          borderColor: AppColors.info.withValues(alpha: 0.30),
          icon: Icons.check_circle_outline,
          fg: AppColors.textMuted,
          label: s.supportStatusClosed,
        );
      default: // 'open'
        return _BadgeConfig(
          bg: AppColors.warningLight,
          borderColor: AppColors.warning.withValues(alpha: 0.30),
          icon: Icons.hourglass_empty,
          fg: AppColors.getStatusForegroundColor('contacting'),
          label: s.supportStatusOpen,
        );
    }
  }
}

class _BadgeConfig {
  final Color bg;
  final Color borderColor;
  final IconData icon;
  final Color fg;
  final String label;

  const _BadgeConfig({
    required this.bg,
    required this.borderColor,
    required this.icon,
    required this.fg,
    required this.label,
  });
}
