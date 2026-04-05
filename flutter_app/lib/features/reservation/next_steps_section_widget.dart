import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';

/// NextStepsSection — numbered step list with connector lines.
/// FIX: section header with secondary left accent + primary icon;
///      step circles: primary→primaryLight gradient, white w700 number;
///      connector lines: border token between steps.
class NextStepsSection extends ConsumerWidget {
  const NextStepsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);

    final steps = [s.reservationResultStep1, s.reservationResultStep2, s.reservationResultStep3];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIX: Section header — secondary 3px left accent, primary info icon, textPrimary w700 17px
        Row(
          children: [
            Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              s.reservationResultNextStepsTitle,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Steps with connector lines
        ..._buildSteps(steps),
      ],
    );
  }

  List<Widget> _buildSteps(List<String> steps) {
    final widgets = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      widgets.add(_StepRow(number: i + 1, text: steps[i]));
      // FIX: Connector line between steps (not after last)
      if (i < steps.length - 1) {
        widgets.add(
          Padding(
            // Indent to align with center of 28px circle (left padding lg + 14 - 0.5)
            padding: const EdgeInsets.only(left: 29.5),
            child: Container(
              width: 1,
              height: 20,
              color: AppColors.border,
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Step number circle — primary→primaryLight gradient, 28×28, white w700
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // FIX: Step text — textSecondary 14px lh1.6
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
