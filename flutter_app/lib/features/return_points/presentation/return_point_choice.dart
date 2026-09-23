import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';

/// « Où la navette te dépose ? », posé partout de la même façon.
///
/// Une ligne par arrêt, plus « je rentre par mes propres moyens » : le refus
/// est une réponse comme une autre, et sans cette ligne on ne distingue pas
/// celui qui a dit non de celui à qui on n'a rien demandé.
///
/// Ne s'affiche jamais avec une liste vide : pas d'arrêt veut dire pas de
/// navette, et proposer une navette qui ne passe pas est pire que se taire.
class ReturnPointChoice extends StatelessWidget {
  const ReturnPointChoice({
    super.key,
    required this.points,
    required this.selectedId,
    required this.onChoose,
    required this.isArabic,
    required this.noneLabel,
    this.enabled = true,
  });

  final List<ReturnPointOption> points;

  /// L'arrêt choisi, ou null pour « par mes propres moyens ».
  final int? selectedId;

  final ValueChanged<int?> onChoose;
  final bool isArabic;

  /// Le libellé du refus : il n'est pas formulé pareil selon qu'on parle à la
  /// personne ou d'elle.
  final String noneLabel;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final point in points)
          _Option(
            label: point.localizedName(isArabic),
            sublabel: point.landmark,
            selected: selectedId == point.id,
            enabled: enabled,
            onTap: () => onChoose(point.id),
          ),
        _Option(
          label: noneLabel,
          selected: selectedId == null,
          enabled: enabled,
          onTap: () => onChoose(null),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.sublabel,
  });

  final String label;
  final String? sublabel;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primary : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.06)
            : AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(
                  color: border, width: selected ? 1.6 : 1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: AppTypography.bodyMedium),
                      if (sublabel != null && sublabel!.isNotEmpty)
                        Text(
                          sublabel!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
