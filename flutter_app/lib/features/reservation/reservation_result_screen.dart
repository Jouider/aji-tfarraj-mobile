import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

/// Reservation Result Screen - Shows pending confirmation status
class ReservationResultScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationResultScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationDetailProvider(int.parse(reservationId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: reservationAsync.when(
          loading: () => const _ResultSkeleton(),
          error: (error, stack) => ErrorState(
            message: error.toString(),
            retryText: 'Réessayer',
            onRetry: () => ref.refresh(reservationDetailProvider(int.parse(reservationId))),
          ),
          data: (reservation) => _ResultContent(reservation: reservation),
        ),
      ),
    );
  }
}

/// Main content widget for reservation result
class _ResultContent extends StatelessWidget {
  final Reservation reservation;

  const _ResultContent({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Success icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_top_rounded,
              size: 50,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            'Réservation envoyée',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pending_outlined, size: 18, color: AppColors.warning),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  CopyFr.statuses.pendingReview,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Reservation summary card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                if (reservation.show != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGrey,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Icon(Icons.tv, color: AppColors.textMuted),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.show!.title,
                              style: AppTypography.h4,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              reservation.show!.city,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                ],
                _InfoRow(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Numéro de réservation',
                  value: '#${reservation.id}',
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: Icons.event_seat_outlined,
                  label: 'Places réservées',
                  value: '${reservation.seats} ${reservation.seats == 1 ? 'place' : 'places'}',
                ),
                if (reservation.show != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date du spectacle',
                    value: dateFormat.format(reservation.show!.startsAt.toLocal()),
                  ),
                ],
                if (reservation.expiresAt != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  _InfoRow(
                    icon: Icons.timer_outlined,
                    label: 'Expire le',
                    value: dateFormat.format(reservation.expiresAt!.toLocal()),
                    valueColor: AppColors.warning,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Next steps card
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Text('Prochaines étapes', style: AppTypography.h4),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _StepItem(
                  number: 1,
                  text: 'Votre demande est en cours de traitement.',
                ),
                const SizedBox(height: AppSpacing.md),
                _StepItem(
                  number: 2,
                  text: 'Notre équipe vous contactera pour confirmer votre réservation.',
                ),
                const SizedBox(height: AppSpacing.md),
                _StepItem(
                  number: 3,
                  text: 'Une fois approuvée, vous recevrez votre billet électronique.',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // CTA buttons
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Voir mes réservations',
              icon: Icons.list_alt_outlined,
              onPressed: () => context.go(Routes.myReservations),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: AppButtonSecondary(
              text: 'Retour à l\'accueil',
              icon: Icons.home_outlined,
              onPressed: () => context.go(Routes.home),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

/// Info row widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: 20),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step item widget for next steps
class _StepItem extends StatelessWidget {
  final int number;
  final String text;

  const _StepItem({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton loading state
class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          SkeletonLoader.circle(size: 100),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 200, height: 28),
          const SizedBox(height: AppSpacing.md),
          SkeletonLoader.text(width: 150, height: 24),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SkeletonLoader(width: 48, height: 48, borderRadius: AppSpacing.radiusMd),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader.text(width: 150, height: 18),
                        const SizedBox(height: AppSpacing.xs),
                        SkeletonLoader.text(width: 80, height: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.text(width: double.infinity, height: 1),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.md),
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.md),
                SkeletonLoader.text(width: double.infinity, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
