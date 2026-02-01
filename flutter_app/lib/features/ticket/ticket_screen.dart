import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:aji_tfarraj/features/tickets/data/ticket_repository.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

/// Ticket Screen with two states: Locked and Generated
class TicketScreen extends ConsumerWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketAsync = ref.watch(myTicketProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon billet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(myTicketProvider.notifier).refresh(),
          ),
        ],
      ),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.read(myTicketProvider.notifier).refresh(),
        ),
        data: (ticket) {
          if (ticket == null) {
            return RefreshIndicator(
              onRefresh: () => ref.read(myTicketProvider.notifier).refresh(),
              child: const SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: 500,
                  child: _TicketLockedView(),
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(myTicketProvider.notifier).refresh(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: _TicketGeneratedView(ticket: ticket),
            ),
          );
        },
      ),
    );
  }
}

/// Widget displayed when ticket is approved and generated
class _TicketGeneratedView extends StatelessWidget {
  final Ticket ticket;

  const _TicketGeneratedView({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final show = ticket.reservation?.show;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ticket Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ticket.isCheckedIn ? Colors.teal : Colors.green,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        ticket.isCheckedIn
                            ? Icons.verified
                            : Icons.confirmation_number,
                        size: 40,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.isCheckedIn ? 'Billet utilisé' : 'Billet valide',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show Info
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (show != null) ...[
                        Text(
                          show.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _TicketInfoRow(
                          icon: Icons.calendar_today,
                          label: dateFormat.format(show.startsAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _TicketInfoRow(
                          icon: Icons.access_time,
                          label: timeFormat.format(show.startsAt.toLocal()),
                        ),
                        const SizedBox(height: 8),
                        _TicketInfoRow(
                          icon: Icons.location_on,
                          label: show.studio ?? show.city,
                        ),
                        if (show.channel != null) ...[
                          const SizedBox(height: 8),
                          _TicketInfoRow(
                            icon: Icons.tv,
                            label: show.channel!,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _TicketInfoRow(
                          icon: Icons.event_seat,
                          label: '${ticket.reservation?.seats ?? 1} place(s)',
                        ),
                      ],
                    ],
                  ),
                ),
                // Dashed Divider
                Row(
                  children: List.generate(
                    30,
                    (index) => Expanded(
                      child: Container(
                        height: 2,
                        color: index.isEven ? Colors.grey[300] : Colors.transparent,
                      ),
                    ),
                  ),
                ),
                // QR Code
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: QrImageView(
                          data: ticket.qrToken,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          ticket.ticketCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Présentez ce QR code à l\'entrée',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Checked in info
          if (ticket.isCheckedIn && ticket.checkedInAt != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.teal[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.teal[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Check-in effectué le ${DateFormat('dd/MM/yyyy à HH:mm').format(ticket.checkedInAt!.toLocal())}',
                      style: TextStyle(color: Colors.teal[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TicketInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

/// Widget displayed when ticket is pending approval
class _TicketLockedView extends StatelessWidget {
  const _TicketLockedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 60,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Aucun billet disponible',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Votre billet sera disponible ici une fois votre réservation approuvée.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tirez vers le bas pour actualiser.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
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
