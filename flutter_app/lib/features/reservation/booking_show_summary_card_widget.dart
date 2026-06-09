import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';

/// BookingShowSummaryCard — show thumbnail + channel badge + title + episode + date + location
/// FIX: cardDarkElevated bg, border, radius 16, shadow; unified channel badge; secondary icons.
class BookingShowSummaryCard extends ConsumerWidget {
  final Show show;
  final Episode? episode;
  final DateFormat dateFormat;

  const BookingShowSummaryCard({
    super.key,
    required this.show,
    this.episode,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final displayDate = episode?.startsAt ?? show.startsAt;
    final displayLocation = episode != null
        ? (episode!.studio ?? episode!.city)
        : (show.studio ?? show.city);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // FIX: cardDarkElevated bg + border token + radius 16 + shadow
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Thumbnail — radius 12, 80×80, cover
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: show.imageUrl != null
                ? Image.network(
                    show.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) =>
                        progress == null ? child : const _ThumbPlaceholder(),
                    errorBuilder: (_, __, ___) => const _ThumbPlaceholder(),
                  )
                : const _ThumbPlaceholder(),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIX: Channel badge — primary 85% bg, white text, radius 20, 4×10 padding
                if (show.channel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      show.channel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],

                // FIX: Show title — textPrimary w700 17px
                Text(
                  show.localizedTitle(isAr),
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // FIX: Episode label — secondary color + film icon, w600 13px
                if (episode != null) ...[
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.videocam_outlined,
                          size: 13, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          episode!.label,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),

                // FIX: Date row — secondary calendar icon 16px, textSecondary 13px
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        displayDate != null
                            ? dateFormat.format(displayDate.toLocal())
                            : '—',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // FIX: Location row — secondary pin icon 16px, textSecondary 13px
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 16, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        displayLocation,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbPlaceholder extends StatelessWidget {
  const _ThumbPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.backgroundGrey,
      child: Icon(Icons.tv_outlined, color: AppColors.textLight, size: 32),
    );
  }
}
