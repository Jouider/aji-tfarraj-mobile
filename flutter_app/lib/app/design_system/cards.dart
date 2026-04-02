import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';

// Re-export the primitive AppCard for backward compatibility
export 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';

import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';

/// Show Card - for displaying show/event information
class ShowCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? date;
  final String? location;
  final VoidCallback? onTap;

  const ShowCard({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.date,
    this.location,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSpacing.cardRadius),
            ),
            child: Container(
              height: 160,
              width: double.infinity,
              color: AppColors.backgroundGrey,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
                    )
                  : const _ImagePlaceholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (date != null || location != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (date != null) ...[
                        Icon(
                          Icons.calendar_today_outlined,
                          size: AppSpacing.iconSm,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(date!, style: AppTypography.labelSmall),
                      ],
                      if (date != null && location != null)
                        const SizedBox(width: AppSpacing.md),
                      if (location != null) ...[
                        Icon(
                          Icons.location_on_outlined,
                          size: AppSpacing.iconSm,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            location!,
                            style: AppTypography.labelSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_outlined,
        size: AppSpacing.iconXxl,
        color: AppColors.textMuted,
      ),
    );
  }
}
