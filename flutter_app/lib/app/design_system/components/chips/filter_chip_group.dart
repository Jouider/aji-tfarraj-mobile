import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/components/chips/app_chip.dart';

/// Filter Chip Group for horizontal scrolling chips
class FilterChipGroup extends StatelessWidget {
  final String? title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onSelected;
  final String allLabel;

  const FilterChipGroup({
    super.key,
    this.title,
    required this.options,
    this.selectedValue,
    required this.onSelected,
    this.allLabel = 'Tous',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              title!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: options.length + 1, // +1 for "All" option
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: AppChip(
                    label: allLabel,
                    isSelected: selectedValue == null,
                    onTap: () => onSelected(null),
                  ),
                );
              }
              final option = options[index - 1];
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppChip(
                  label: option,
                  isSelected: selectedValue == option,
                  onTap: () => onSelected(option),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
