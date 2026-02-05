import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/presentation/reservation_status.dart';

/// Reservation Detail Screen
class ReservationDetailScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(reservationDetailProvider(int.parse(reservationId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
      ),
      body: reservationAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.refresh(reservationDetailProvider(int.parse(reservationId))),
        ),
        data: (reservation) {
          final statusHelper = ReservationStatusHelper(reservation.status);
          final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
          final timeFormat = DateFormat('HH:mm');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: statusHelper.backgroundColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: statusHelper.color.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        statusHelper.icon,
                        size: 48,
                        color: statusHelper.color,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        statusHelper.label,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: statusHelper.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getStatusMessage(statusHelper),
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Show Info
                if (reservation.show != null) ...[
                  const Text(
                    'Émission',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reservation.show!.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InfoRow(
                          icon: Icons.calendar_today,
                          label: dateFormat.format(reservation.show!.startsAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.access_time,
                          label: timeFormat.format(reservation.show!.startsAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.location_on,
                          label: reservation.show!.studio ?? reservation.show!.city,
                        ),
                        if (reservation.show!.channel != null) ...[
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.tv,
                            label: reservation.show!.channel!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Reservation Details
                const Text(
                  'Détails de la réservation',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: 'Numéro de réservation',
                        value: '#${reservation.id}',
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Nombre de places',
                        value: '${reservation.seats}',
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        label: 'Date de réservation',
                        value: DateFormat('dd/MM/yyyy').format(reservation.createdAt.toLocal()),
                      ),
                      // Show expiration date if available
                      if (reservation.expiresAt != null) ...[
                        const Divider(height: 24),
                        _DetailRow(
                          label: statusHelper.isExpired ? 'Expirée le' : 'Expire le',
                          value: DateFormat('dd/MM/yyyy à HH:mm').format(reservation.expiresAt!.toLocal()),
                          valueColor: statusHelper.isExpired ? Colors.brown : Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),

                // Rejection Reason
                if (reservation.rejectionReason != null && statusHelper.isRejected) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Raison du refus',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          reservation.rejectionReason!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ],
                    ),
                  ),
                ],

                // Expired status info box
                if (statusHelper.isExpired) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.brown[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.timer_off, color: Colors.brown[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Réservation expirée',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.brown[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cette réservation a expiré car elle n\'a pas été confirmée à temps. Vous pouvez faire une nouvelle réservation pour une autre émission.',
                          style: TextStyle(color: Colors.brown[700]),
                        ),
                      ],
                    ),
                  ),
                ],

                // Checked-in status info box
                if (statusHelper.isCheckedIn) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.teal[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.teal[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Entrée validée',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.teal[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Votre billet a été utilisé pour accéder à l\'émission. Merci de votre participation !',
                          style: TextStyle(color: Colors.teal[700]),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Actions
                // Show ticket button only for approved (not checked_in, as ticket is already used)
                if (statusHelper.isApproved) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(Routes.ticket),
                      icon: const Icon(Icons.confirmation_number),
                      label: const Text('Voir mon billet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // View used ticket for checked_in
                if (statusHelper.isCheckedIn) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => context.go(Routes.ticket),
                      icon: const Icon(Icons.confirmation_number_outlined),
                      label: const Text('Voir le billet utilisé'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: const BorderSide(color: Colors.teal),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Reserve again button for expired/rejected
                if (statusHelper.isExpired || statusHelper.isRejected) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () => context.go(Routes.home),
                      icon: const Icon(Icons.search),
                      label: const Text('Découvrir les émissions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (statusHelper.canCancel) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(context, ref),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Annuler la réservation'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 16),
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
      return 'Votre réservation a été confirmée ! Vous pouvez consulter votre billet.';
    } else if (helper.isRejected) {
      return 'Votre demande a été refusée. Vous pouvez faire une nouvelle demande.';
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
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette réservation ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(myReservationsProvider.notifier)
                    .cancelReservation(int.parse(reservationId));
                if (context.mounted) {
                  context.go(Routes.myReservations);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Réservation annulée')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[600]),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
