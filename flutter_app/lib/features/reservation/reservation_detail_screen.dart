import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/reservations/presentation/reservation_status.dart';

/// Reservation Detail Screen — dark premium redesign
class ReservationDetailScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationDetailProvider(int.parse(reservationId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text('Ma réservation', style: AppTypography.h3),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.myReservations),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: reservationAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.refresh(reservationDetailProvider(int.parse(reservationId))),
        ),
        data: (reservation) {
          final statusHelper = ReservationStatusHelper(reservation.status);
          final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
          final timeFormat = DateFormat('HH:mm');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status hero
                _StatusCard(
                  statusHelper: statusHelper,
                  message: _getStatusMessage(statusHelper),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Show info
                if (reservation.show != null) ...[
                  const _SectionLabel('Émission'),
                  const SizedBox(height: AppSpacing.sm),
                  _ShowInfoCard(
                    reservation: reservation,
                    dateFormat: dateFormat,
                    timeFormat: timeFormat,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Reservation details
                const _SectionLabel('Détails de la réservation'),
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
                    title: 'Raison du refus',
                    message: reservation.rejectionReason!,
                    color: AppColors.error,
                    bgColor: AppColors.errorLight,
                  ),
                ],
                if (statusHelper.isExpired) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _AlertInfoBox(
                    icon: Icons.timer_off_outlined,
                    title: 'Réservation expirée',
                    message:
                        'Cette réservation a expiré car elle n\'a pas été confirmée à temps. Vous pouvez faire une nouvelle réservation.',
                    color: AppColors.warning,
                    bgColor: AppColors.warningLight,
                  ),
                ],
                if (statusHelper.isCheckedIn) ...[
                  const SizedBox(height: AppSpacing.lg),
                  const _AlertInfoBox(
                    icon: Icons.verified_outlined,
                    title: 'Entrée validée',
                    message:
                        'Votre billet a été utilisé pour accéder à l\'émission. Merci de votre participation !',
                    color: AppColors.success,
                    bgColor: AppColors.successLight,
                  ),
                ],

                const SizedBox(height: AppSpacing.xxl),

                // Action buttons
                _ActionButtons(
                  statusHelper: statusHelper,
                  onCancel: () => _showCancelDialog(context, ref),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getStatusMessage(ReservationStatusHelper helper) {
    if (helper.isPending) {
      return 'Votre demande est en cours de traitement. Vous serez notifié une fois approuvée.';
    } else if (helper.isApproved) {
      return 'Votre réservation est confirmée ! Consultez votre billet ci-dessous.';
    } else if (helper.isRejected) {
      return 'Votre demande a été refusée. Vous pouvez en faire une nouvelle.';
    } else if (helper.isCheckedIn) {
      return 'Vous avez assisté à cette émission. Merci !';
    } else if (helper.isCancelled) {
      return 'Vous avez annulé cette réservation.';
    } else if (helper.isExpired) {
      return 'Cette réservation a expiré. Vous pouvez réserver une autre émission.';
    }
    return '';
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
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
                decoration: const BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Annuler la réservation', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.',
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
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: const Text('Garder'),
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
                                  'Réservation annulée',
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
                                content: Text('Erreur: $e', style: AppTypography.bodyMedium),
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
                      child: const Text('Annuler'),
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

class _StatusCard extends StatelessWidget {
  final ReservationStatusHelper statusHelper;
  final String message;

  const _StatusCard({required this.statusHelper, required this.message});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.getStatusColor(statusHelper.status);
    final statusBg = AppColors.getStatusBackgroundColor(statusHelper.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: statusBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(statusHelper.icon, size: 32, color: statusColor),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            statusHelper.label,
            style: AppTypography.h3.copyWith(color: statusColor),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textLight,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShowInfoCard extends StatelessWidget {
  final Reservation reservation;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  const _ShowInfoCard({
    required this.reservation,
    required this.dateFormat,
    required this.timeFormat,
  });

  @override
  Widget build(BuildContext context) {
    final show = reservation.show!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(show.title, style: AppTypography.h4),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: dateFormat.format(show.startsAt.toLocal()),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: timeFormat.format(show.startsAt.toLocal()),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: show.studio ?? show.city,
          ),
          if (show.channel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _InfoRow(icon: Icons.tv_outlined, label: show.channel!),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Details Card
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationDetailsCard extends StatelessWidget {
  final Reservation reservation;
  final ReservationStatusHelper statusHelper;

  const _ReservationDetailsCard({
    required this.reservation,
    required this.statusHelper,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _DetailRow(
            label: 'Numéro de réservation',
            value: '#${reservation.id}',
            valueStyle: AppTypography.labelLarge.copyWith(color: AppColors.secondary),
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          _DetailRow(
            label: 'Nombre de places',
            value: '${reservation.seats} place${reservation.seats > 1 ? 's' : ''}',
          ),
          const Divider(height: AppSpacing.xl, color: AppColors.border),
          _DetailRow(
            label: 'Date de réservation',
            value: DateFormat('dd/MM/yyyy').format(reservation.createdAt.toLocal()),
          ),
          if (reservation.expiresAt != null) ...[
            const Divider(height: AppSpacing.xl, color: AppColors.border),
            _DetailRow(
              label: statusHelper.isExpired ? 'Expirée le' : 'Expire le',
              value: DateFormat('dd/MM/yyyy à HH:mm').format(reservation.expiresAt!.toLocal()),
              valueStyle: AppTypography.labelLarge.copyWith(
                color: statusHelper.isExpired ? AppColors.error : AppColors.warning,
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

class _ActionButtons extends StatelessWidget {
  final ReservationStatusHelper statusHelper;
  final VoidCallback onCancel;

  const _ActionButtons({required this.statusHelper, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Approved → view ticket (gold CTA)
        if (statusHelper.isApproved) ...[
          _ActionButton(
            label: 'Voir mon billet',
            icon: Icons.confirmation_number_outlined,
            onPressed: () => context.go(Routes.ticket),
            filled: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Checked-in → view used ticket
        if (statusHelper.isCheckedIn) ...[
          _ActionButton(
            label: 'Voir le billet utilisé',
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
            label: 'Découvrir les émissions',
            icon: Icons.explore_outlined,
            onPressed: () => context.go(Routes.home),
            filled: true,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],

        // Can cancel → red outlined
        if (statusHelper.canCancel)
          _ActionButton(
            label: 'Annuler la réservation',
            icon: Icons.cancel_outlined,
            onPressed: onCancel,
            filled: false,
            color: AppColors.error,
          ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Info Row & Detail Row
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.backgroundLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? valueStyle;

  const _DetailRow({required this.label, required this.value, this.valueStyle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
        Text(
          value,
          style: valueStyle ?? AppTypography.labelLarge,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error View
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

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
              label: Text('Réessayer', style: AppTypography.buttonLarge),
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
