import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/loaders.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/reservations/presentation/reservation_status.dart';

/// Reservation Detail Screen — dark premium redesign
class ReservationDetailScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final reservationAsync = ref.watch(reservationDetailProvider(int.parse(reservationId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // FIX: App bar — backgroundWhite, centered title w700 18px, primary back arrow
      appBar: AppBar(
        title: Text(
          s.resDetailAppBarTitle,
          style: AppTypography.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(Routes.myReservations),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: reservationAsync.when(
        loading: () => const _DetailSkeleton(),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          retryLabel: s.resDetailRetry,
          onRetry: () => ref.refresh(reservationDetailProvider(int.parse(reservationId))),
        ),
        data: (reservation) {
          final isAr = ref.watch(isRtlProvider);
          final statusHelper = ReservationStatusHelper(reservation.status);
          final localeName = isAr ? 'ar' : 'fr_FR';
          final dateFormat = DateFormat('EEEE dd MMMM yyyy', localeName);
          final timeFormat = DateFormat('HH:mm');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status hero
                _StatusCard(
                  statusHelper: statusHelper,
                  message: _getStatusMessage(statusHelper, s),
                  rejectionReason: statusHelper.isRejected
                      ? reservation.rejectionReason
                      : null,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Show info
                if (reservation.show != null) ...[
                  _SectionLabel(s.resDetailSectionShow),
                  const SizedBox(height: AppSpacing.sm),
                  _ShowInfoCard(
                    reservation: reservation,
                    dateFormat: dateFormat,
                    timeFormat: timeFormat,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Reservation details
                _SectionLabel(s.resDetailSectionDetails),
                const SizedBox(height: AppSpacing.sm),
                _ReservationDetailsCard(
                  reservation: reservation,
                  statusHelper: statusHelper,
                ),

                // Contextual info boxes
                if (reservation.rejectionReason != null && statusHelper.isRejected) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AlertInfoBox(
                    icon: Icons.info_outline,
                    title: s.resDetailAlertRejectionTitle,
                    message: reservation.rejectionReason!,
                    color: AppColors.error,
                    bgColor: AppColors.errorLight,
                  ),
                ],
                if (statusHelper.isExpired) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AlertInfoBox(
                    icon: Icons.timer_off_outlined,
                    title: s.resDetailAlertExpiredTitle,
                    message: s.resDetailAlertExpiredBody,
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                  ),
                ],
                if (statusHelper.isCheckedIn) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _AlertInfoBox(
                    icon: Icons.verified_outlined,
                    title: s.resDetailAlertCheckedInTitle,
                    message: s.resDetailAlertCheckedInBody,
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Action buttons
                _ActionButtons(
                  statusHelper: statusHelper,
                  onCancel: () => _showCancelDialog(context, ref, s),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusMessage(ReservationStatusHelper helper, AppStrings s) {
    if (helper.isPending) return s.resDetailMsgPending;
    if (helper.isApproved) return s.resDetailMsgApproved;
    if (helper.isRejected) return s.resDetailMsgRejected;
    if (helper.isCheckedIn) return s.resDetailMsgCheckedIn;
    if (helper.isCancelled) return s.resDetailMsgCancelled;
    if (helper.isExpired) return s.resDetailMsgExpired;
    return '';
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref, AppStrings s) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surfaceOverlay,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(s.resDetailCancelDialogTitle, style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.resDetailCancelDialogBody,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        backgroundColor: AppColors.backgroundGrey,
                        side: BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(s.resDetailCancelDialogBack),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          await ref
                              .read(myReservationsProvider.notifier)
                              .cancelReservation(int.parse(reservationId));
                          if (context.mounted) {
                            context.go(Routes.myReservations);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  s.resDetailCancelSuccess,
                                  style: AppTypography.bodyMedium,
                                ),
                                backgroundColor: AppColors.backgroundGrey,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$e', style: AppTypography.bodyMedium),
                                backgroundColor: AppColors.errorLight,
                              ),
                            );
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(s.resDetailCancelDialogConfirm),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status Hero Card
// ─────────────────────────────────────────────────────────────────────────────

// FIX: Status banner — radius 20, theme-aware foreground, status-tinted border 25%, icon circle 20%
class _StatusCard extends StatelessWidget {
  final ReservationStatusHelper statusHelper;
  final String message;
  final String? rejectionReason;

  const _StatusCard({
    required this.statusHelper,
    required this.message,
    this.rejectionReason,
  });

  @override
  Widget build(BuildContext context) {
    // FIX: Use theme-aware foreground for text/icon — readable in both modes
    final fg = AppColors.getStatusForegroundColor(statusHelper.status);
    final rawColor = AppColors.getStatusColor(statusHelper.status);
    final statusBg = AppColors.getStatusBackgroundColor(statusHelper.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: rawColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          // FIX: Icon circle — 20% opacity background
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: rawColor.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Icon(statusHelper.icon, size: 28, color: fg),
          ),
          const SizedBox(height: AppSpacing.md),
          // FIX: Title — 20px w700 foreground color
          Text(
            statusHelper.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          // FIX: Rejection reason in italic below message
          if (rejectionReason != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              rejectionReason!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: fg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

// FIX: Section label — secondary 2px left accent, textMuted 11px w600 ls1.2
class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 2,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text.toUpperCase(),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShowInfoCard extends ConsumerWidget {
  final Reservation reservation;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _ShowInfoCard({
    required this.reservation,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final show = reservation.show!;

    // Build rows list to properly insert dividers between (not after last)
    final rows = <_InfoRow>[
      _InfoRow(
        icon: Icons.calendar_today_outlined,
        iconColor: AppColors.secondary,
        label: show.startsAt != null
            ? dateFormat.format(show.startsAt!.toLocal())
            : '—',
      ),
      _InfoRow(
        icon: Icons.access_time_outlined,
        iconColor: AppColors.secondary,
        label: show.startsAt != null
            ? timeFormat.format(show.startsAt!.toLocal())
            : '—',
      ),
      _InfoRow(
        icon: Icons.location_on_outlined,
        iconColor: AppColors.secondary,
        label: show.studio ?? show.city,
      ),
      if (show.channel != null)
        // FIX: Channel icon — primary to differentiate from location
        _InfoRow(
          icon: Icons.tv_outlined,
          iconColor: AppColors.primary,
          label: show.channel!,
        ),
    ];

    // FIX: Card — cardDarkElevated, radius 16, shadow 5%
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Show title — textPrimary w700 18px
          Text(
            show.localizedTitle(isAr),
            style: AppTypography.h4.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          // FIX: Info rows with dividers between (not after last)
          ...List.generate(rows.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Divider(height: 1, color: AppColors.border);
            }
            return rows[i ~/ 2];
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Details Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationDetailsCard extends ConsumerWidget {
  final Reservation reservation;
  final ReservationStatusHelper statusHelper;

  const _ReservationDetailsCard({
    required this.reservation,
    required this.statusHelper,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    // FIX: Details card — cardDarkElevated, radius 16, shadow 5%
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
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
      child: Column(
        children: [
          // FIX: Reservation number — secondary w700 15px + copy icon
          _DetailRow(
            label: s.resDetailLabelNumber,
            value: '#${reservation.id}',
            valueStyle: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            onCopy: () {
              Clipboard.setData(ClipboardData(text: '#${reservation.id}'));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(s.resDetailCopied),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          Divider(height: 1, color: AppColors.border),
          _DetailRow(
            label: s.resDetailLabelSeats,
            value: s.resDetailSeats(reservation.seats),
          ),
          Divider(height: 1, color: AppColors.border),
          _DetailRow(
            label: s.resDetailLabelCreatedAt,
            value: DateFormat('dd/MM/yyyy').format(reservation.createdAt.toLocal()),
            valueStyle: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (reservation.expiresAt != null) ...[
            Divider(height: 1, color: AppColors.border),
            _DetailRow(
              label: statusHelper.isExpired ? s.resDetailLabelExpiredAt : s.resDetailLabelExpiresAt,
              value: DateFormat('dd/MM/yyyy à HH:mm')
                  .format(reservation.expiresAt!.toLocal()),
              valueStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: statusHelper.isExpired
                    ? AppColors.errorDark
                    : AppColors.warningDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Alert Info Box
// ─────────────────────────────────────────────────────────────────────────────

class _AlertInfoBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color bgColor;

  const _AlertInfoBox({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.labelMedium.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action Buttons
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButtons extends ConsumerWidget {
  final ReservationStatusHelper statusHelper;
  final VoidCallback onCancel;

  const _ActionButtons({required this.statusHelper, required this.onCancel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    return Column(
      children: [
        // Approved → view ticket (gold CTA)
        if (statusHelper.isApproved) ...[
          _ActionButton(
            label: s.resDetailBtnViewTicket,
            icon: Icons.confirmation_number_outlined,
            onPressed: () => context.go(Routes.ticket),
            filled: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Checked-in → view used ticket
        if (statusHelper.isCheckedIn) ...[
          _ActionButton(
            label: s.resDetailBtnViewUsedTicket,
            icon: Icons.confirmation_number_outlined,
            onPressed: () => context.go(Routes.ticket),
            filled: false,
            color: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Expired / rejected → discover shows (gold CTA)
        if (statusHelper.isExpired || statusHelper.isRejected) ...[
          _ActionButton(
            label: s.resDetailBtnDiscoverShows,
            icon: Icons.explore_outlined,
            onPressed: () => context.go(Routes.home),
            filled: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // FIX: Cancel button — errorLight bg, error border 1.5px, errorDark text, radius 14, h52, shadow
        if (statusHelper.canCancel) _CancelButton(label: s.resDetailBtnCancel, onCancel: onCancel),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool filled;
  final Color? color;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.filled,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.secondary;

    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text('  $label', style: AppTypography.buttonLarge),
          style: FilledButton.styleFrom(
            backgroundColor: resolvedColor,
            foregroundColor: AppColors.backgroundWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: AppSpacing.buttonHeight,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text('  $label', style: AppTypography.buttonLarge.copyWith(color: resolvedColor)),
        style: OutlinedButton.styleFrom(
          foregroundColor: resolvedColor,
          side: BorderSide(color: resolvedColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }
}

// FIX: Cancel button — errorLight bg, error 1.5px border, errorDark text, radius 14, h52, shadow
class _CancelButton extends StatelessWidget {
  final String label;
  final VoidCallback onCancel;

  const _CancelButton({required this.label, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: OutlinedButton.icon(
        onPressed: onCancel,
        icon: Icon(Icons.cancel_outlined,
            size: 18, color: AppColors.errorDark),
        label: Text(
          label,
          style: AppTypography.buttonLarge.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.errorDark,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.errorLight,
          foregroundColor: AppColors.errorDark,
          side: const BorderSide(color: AppColors.error, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Row & Detail Row
// ─────────────────────────────────────────────────────────────────────────────

// FIX: Info row — secondary 12% bg container 34×34 radius 8, secondary icon 18px, textSecondary 14px
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    this.iconColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// FIX: Detail row — label textMuted 14px w400, value textPrimary w600, optional copy icon
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;
  final VoidCallback? onCopy;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueStyle,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedStyle = valueStyle ??
        AppTypography.labelLarge.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textMuted,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: resolvedStyle),
              // FIX: Copy icon — secondary color, size 16, tappable
              if (onCopy != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onCopy,
                  child: const Icon(Icons.copy,
                      size: 16, color: AppColors.secondary),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(retryLabel, style: AppTypography.buttonLarge),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.backgroundWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonLoader.card(height: 160),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 100, height: 14),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.card(height: 120),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 200, height: 14),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.card(height: 160),
        ],
      ),
    );
  }
}
