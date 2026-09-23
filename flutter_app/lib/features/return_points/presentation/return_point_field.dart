import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/return_points/domain/return_point_option.dart';
import 'package:aji_tfarraj/features/return_points/presentation/return_point_choice.dart';

/// Le choix du retour, en une seule ligne.
///
/// La liste complète tenait sur l'écran de réservation et le rendait
/// interminable à faire défiler — dix arrêts poussaient les conditions et le
/// bouton hors de vue. Ici on affiche la réponse en cours, et la liste ne
/// s'ouvre que si la personne la demande.
class ReturnPointField extends StatelessWidget {
  const ReturnPointField({
    super.key,
    required this.points,
    required this.selectedId,
    required this.onChoose,
    required this.isArabic,
    required this.strings,
    this.enabled = true,
  });

  final List<ReturnPointOption> points;

  /// L'arrêt choisi, ou null pour « je rentre par mes propres moyens ».
  final int? selectedId;

  final ValueChanged<int?> onChoose;
  final bool isArabic;
  final AppStrings strings;
  final bool enabled;

  ReturnPointOption? get _selected {
    for (final point in points) {
      if (point.id == selectedId) return point;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    final chosen = _selected;

    return Material(
      color: AppColors.backgroundWhite,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        onTap: enabled ? () => _open(context) : null,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Row(
            children: [
              Icon(Icons.directions_bus_outlined,
                  size: 20, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings.returnPointQuestion,
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      // Sans arrêt choisi, la réponse est « par mes propres
                      // moyens » : c'en est une, et l'afficher évite de faire
                      // croire qu'il reste quelque chose à remplir.
                      chosen?.localizedName(isArabic) ?? strings.returnPointNone,
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                strings.returnPointChange,
                style: AppTypography.labelMedium
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.backgroundLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md,
              AppSpacing.lg, AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              Text(strings.returnPointQuestion, style: AppTypography.h4),
              const SizedBox(height: AppSpacing.xs),
              Text(
                strings.returnPointHint,
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Beaucoup d'arrêts : la liste défile dans la feuille, pas la
              // page de réservation.
              Flexible(
                child: SingleChildScrollView(
                  child: ReturnPointChoice(
                    points: points,
                    selectedId: selectedId,
                    isArabic: isArabic,
                    noneLabel: strings.returnPointNone,
                    onChoose: (id) {
                      onChoose(id);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
