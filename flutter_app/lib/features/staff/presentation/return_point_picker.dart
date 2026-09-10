import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/staff/domain/return_point_option.dart';

/// "Where should the shuttle drop you?", asked at the door.
///
/// Shared by the two places that put the question — scanning a booked ticket,
/// and registering a walk-in on the spot. One widget on purpose: this control
/// decides whether someone gets a ride home, and two copies would drift apart.
class ReturnPointPicker extends ConsumerWidget {
  const ReturnPointPicker({
    required this.points,
    required this.chosenId,
    required this.saving,
    required this.answered,
    required this.error,
    required this.onChoose,
  });

  final List<ReturnPointOption> points;

  /// The stop chosen so far, if any.
  final int? chosenId;
  final bool saving;

  /// Whether the question has been put. Until it has, **nothing** is shown as
  /// selected: a pre-ticked "makes their own way" reads as an answer already
  /// given, and the scanner moves on without asking.
  final bool answered;
  final String? error;
  final ValueChanged<int?> onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        // Still unanswered: make it look like the thing standing in the way,
        // because it is.
        border: Border.all(
          color: answered ? AppColors.border : AppColors.secondary,
          width: answered ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_bus_outlined,
                  size: 18, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.xs),
              // Expanded: an Arabic title on a 360px phone overflowed the row.
              Expanded(
                child: Text(s.staffReturnPointTitle,
                    style: AppTypography.labelMedium),
              ),
              if (saving) ...[
                const SizedBox(width: AppSpacing.sm),
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(s.staffReturnPointQuestion,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.sm),
          for (final point in points)
            _PointTile(
              label: point.localizedName(isAr),
              sublabel: point.landmark,
              selected: answered && chosenId == point.id,
              enabled: !saving,
              onTap: () => onChoose(point.id),
            ),
          // "I make my own way" is a real answer and must be as easy to record
          // as any stop — but it has to be *chosen*, never assumed.
          _PointTile(
            label: s.staffReturnPointNone,
            selected: answered && chosenId == null,
            enabled: !saving,
            onTap: () => onChoose(null),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(error!,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.errorDark)),
          ],
        ],
      ),
    );
  }
}

class _PointTile extends StatelessWidget {
  const _PointTile({
    required this.label,
    this.sublabel,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.12)
                : AppColors.backgroundGrey,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: selected ? AppColors.secondary : AppColors.border,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.bodyMedium),
                    if (sublabel != null)
                      Text(sublabel!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
