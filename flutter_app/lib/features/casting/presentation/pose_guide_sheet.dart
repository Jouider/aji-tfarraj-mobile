import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';
import 'package:aji_tfarraj/features/casting/presentation/pose_capture_screen.dart';

/// The instructions for one shot, read *before* the camera opens.
///
/// Deliberately a separate step. Instructions printed over a live preview are
/// not read — the person is already holding a pose and looking at themselves.
/// Read first, then shoot, is the order that produces a usable book.
///
/// Returns the captured file path, or null if they backed out.
Future<String?> showPoseGuide(
  BuildContext context,
  WidgetRef ref, {
  required CastingPose pose,
}) async {
  final s = ref.read(stringsProvider);
  final copy = poseCopy(s.casting, pose);

  final go = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOverlay,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text(copy.label,
                        style: AppTypography.h3
                            .copyWith(color: AppColors.textPrimary)),
                  ),
                  _Chip(
                    label: pose.isRequired
                        ? s.casting.bookRequired
                        : s.casting.bookOptional,
                    highlight: pose.isRequired,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              for (var i = 0; i < copy.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.secondary)),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(copy.steps[i],
                            style: AppTypography.bodyMedium),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group_outlined,
                        size: 18, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(s.casting.bookHelper,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.textMuted)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: AppSpacing.buttonHeight,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(sheetContext).pop(true),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(s.casting.bookTake),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.onSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  if (go != true || !context.mounted) return null;

  return Navigator.of(context).push<String>(
    MaterialPageRoute(builder: (_) => PoseCaptureScreen(pose: pose)),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.highlight});

  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: highlight ? AppColors.secondary : AppColors.textMuted,
        ),
      ),
    );
  }
}
