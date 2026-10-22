import 'package:flutter/material.dart';

import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// L'adresse exacte, les soirs où la navette dépose chacun chez lui.
///
/// Demandée seulement quand le tournage le veut (`asks_return_address`) et
/// qu'un arrêt est choisi : les autres soirs, l'arrêt suffit, et le chauffeur
/// n'a pas à lire une adresse personnelle. Partagée par la réservation et la
/// porte, où le staff peut la corriger.
class ReturnAddressField extends StatelessWidget {
  const ReturnAddressField({
    super.key,
    required this.controller,
    required this.strings,
    this.enabled = true,
    this.onChanged,
  });

  /// La limite du serveur (`return_point_detail`).
  static const maxLength = 255;

  final TextEditingController controller;
  final AppStrings strings;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Icon(Icons.home_outlined,
                size: 20, color: AppColors.textMuted),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              onChanged: onChanged,
              minLines: 1,
              maxLines: 3,
              maxLength: maxLength,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                labelText: strings.returnAddressLabel,
                hintText: strings.returnAddressHint,
                labelStyle:
                    AppTypography.caption.copyWith(color: AppColors.textMuted),
                hintStyle: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                filled: false,
                isDense: true,
                // Le compteur n'apparaît qu'en approchant de la limite.
                counterText: '',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
