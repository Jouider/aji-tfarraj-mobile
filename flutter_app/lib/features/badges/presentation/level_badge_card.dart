import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
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

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
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
                        style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.w700, color: accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
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
                      backgroundColor: accent.withValues(alpha: 0.15),
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
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.15),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 2),
      ),
      child: Text(
        emoji ?? '🏅',
        style: const TextStyle(fontSize: 28),
      ),
    );
  }
}
