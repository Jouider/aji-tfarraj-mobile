import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

/// Le champ de recherche au-dessus d'une liste d'arrêts.
///
/// Il n'apparaît qu'à partir de [showFrom] arrêts. En dessous, la liste tient
/// à l'écran et un champ de plus ne ferait que voler une ligne — tandis
/// qu'au-delà, le staff faisait défiler à l'aveugle devant la file, ce qui
/// est exactement ce qu'on a voulu éviter en posant la question à la
/// réservation.
class ReturnPointSearchField extends StatelessWidget {
  const ReturnPointSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;

  /// Vrai au scan, faux à la réservation : le staff arrive avec le nom en
  /// tête et une file devant lui ; le membre, lui, découvre la liste.
  final bool autofocus;

  /// Le seuil à partir duquel chercher devient plus rapide que parcourir.
  static const int showFrom = 6;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      style: AppTypography.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        prefixIcon: Icon(Icons.search, size: 20, color: AppColors.textMuted),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  icon: Icon(Icons.close, size: 18, color: AppColors.textMuted),
                  onPressed: controller.clear,
                ),
        ),
        isDense: true,
        filled: true,
        fillColor: AppColors.backgroundGrey,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: AppColors.accentInk, width: 1.5),
        ),
      ),
    );
  }
}
