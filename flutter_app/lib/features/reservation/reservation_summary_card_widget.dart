import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

/// ReservationSummaryCard — show info + detail rows.
/// FIX: cardDarkElevated bg, border, radius 16, shadow 6%.
///      Show row: primary 10% icon bg, secondary icons in detail rows.
///      Reservation number: secondary w700 15px.
class ReservationSummaryCard extends ConsumerWidget {
  final Reservation reservation;

  const ReservationSummaryCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final isAr = ref.watch(isRtlProvider);
    final dateFormat = DateFormat(
        'dd MMMM yyyy à HH:mm', isAr ? 'ar' : 'fr_FR');

    final detailRows = <_DetailRow>[
      _DetailRow(
        icon: Icons.confirmation_number_outlined,
        iconColor: AppColors.secondary,
        label: s.reservationResultNumberLabel,
        value: '#${reservation.id}',
        valueColor: AppColors.secondary,
        valueFontSize: 15,
        valueFontWeight: FontWeight.w700,
      ),
      _DetailRow(
        icon: Icons.event_seat_outlined,
        // FIX: Seat icon → primary
        iconColor: AppColors.primary,
        label: s.reservationResultSeatsLabel,
        value: s.reservationResultSeats(reservation.seats),
      ),
      if (reservation.show?.startsAt != null)
        _DetailRow(
          icon: Icons.calendar_today_outlined,
          iconColor: AppColors.secondary,
          label: s.reservationResultDateLabel,
          value: dateFormat
              .format(reservation.show!.startsAt!.toLocal()),
        ),
      if (reservation.expiresAt != null)
        _DetailRow(
          icon: Icons.timer_outlined,
          iconColor: AppColors.warning,
          label: s.reservationResultExpiresLabel,
          value: dateFormat.format(reservation.expiresAt!.toLocal()),
          valueColor: AppColors.warning,
        ),
    ];

    return Container(
      // FIX: cardDarkElevated bg, border, radius 16, 6% shadow
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Show row
          if (reservation.show != null) ...[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  // FIX: primary 10% bg, radius 10, 44×44, primary TV icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.tv_outlined,
                        color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIX: Show name — textPrimary w700 16px
                        Text(
                          reservation.show!.title,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // FIX: Location — textMuted 13px
                        Text(
                          reservation.show!.city,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // FIX: Divider — border token
            Divider(height: 1, thickness: 1, color: AppColors.border),
          ],

          // Detail rows with dividers between (not after last)
          ...List.generate(
            detailRows.length * 2 - 1,
            (i) => i.isOdd
                ? Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.border,
                    indent: AppSpacing.lg,
                  )
                : _DetailRowWidget(row: detailRows[i ~/ 2]),
          ),
        ],
      ),
    );
  }
}

// Data model for a detail row
class _DetailRow {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color? valueColor;
  final double valueFontSize;
  final FontWeight valueFontWeight;

  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
    this.valueFontSize = 14,
    this.valueFontWeight = FontWeight.w600,
  });
}

// FIX: Detail row widget — secondary icon 18px, textMuted label 12px, textPrimary value 14px w600
class _DetailRowWidget extends StatelessWidget {
  final _DetailRow row;

  const _DetailRowWidget({required this.row});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 12),
      child: Row(
        children: [
          Icon(row.icon, color: row.iconColor, size: 18),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  row.value,
                  style: TextStyle(
                    color: row.valueColor ?? AppColors.textPrimary,
                    fontSize: row.valueFontSize,
                    fontWeight: row.valueFontWeight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
