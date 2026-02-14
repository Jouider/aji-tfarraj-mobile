import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';

/// Displays a list of points history entries.
/// In preview mode, shows only [previewCount] items with a "Voir tout" button.
class PointsHistoryList extends StatelessWidget {
  final List<PointsEntry> entries;
  final bool isPreview;
  final int previewCount;
  final String seeAllLabel;
  final VoidCallback? onSeeAll;

  /// Label resolver per entry type (e.g. "attendance" → "Présence")
  final String Function(String type) labelForType;

  const PointsHistoryList({
    super.key,
    required this.entries,
    required this.labelForType,
    this.isPreview = true,
    this.previewCount = 5,
    this.seeAllLabel = 'Voir tout',
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final visible = isPreview ? entries.take(previewCount).toList() : entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...visible.map((entry) => _HistoryTile(
              entry: entry,
              label: labelForType(entry.type),
            )),
        if (isPreview && entries.length > previewCount && onSeeAll != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Center(
              child: TextButton(
                onPressed: onSeeAll,
                child: Text(
                  seeAllLabel,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A single history row
class _HistoryTile extends StatelessWidget {
  final PointsEntry entry;
  final String label;

  const _HistoryTile({required this.entry, required this.label});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('dd MMM yyyy', 'fr').format(entry.createdAt);
    final isPositive = entry.isPositive;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isPositive
                  ? AppColors.successLight
                  : AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline,
              color: isPositive ? AppColors.success : AppColors.error,
              size: AppSpacing.iconMd,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMedium),
                const SizedBox(height: 2),
                Text(
                  dateFormatted,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          // Points
          Text(
            entry.formattedPoints,
            style: AppTypography.h4.copyWith(
              color: isPositive ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
