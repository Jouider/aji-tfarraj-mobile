import 'package:flutter/material.dart';

/// Ticket Screen with two states: Locked and Generated
/// TODO: Connect to provider state for ticket approval status
/// TODO: Implement actual QR code generation
class TicketScreen extends StatelessWidget {
  const TicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with provider state (e.g., ref.watch(ticketProvider))
    final hasApprovedTicket = false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon billet'),
      ),
      body: hasApprovedTicket
          ? const _TicketGeneratedView()
          : const _TicketLockedView(),
    );
  }
}

/// Widget displayed when ticket is approved and generated
class _TicketGeneratedView extends StatelessWidget {
  const _TicketGeneratedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // TODO: Replace with actual show name from ticket data
                    const Text(
                      'Show Name',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // TODO: Generate actual QR code with ticket data
                    Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // TODO: Replace with actual ticket number
                    const Text(
                      'Ticket #12345',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // TODO: Replace with actual ticket details
                    const Text('Date: XX/XX/XXXX'),
                    const SizedBox(height: 8),
                    const Text('Heure: XX:XX'),
                    const SizedBox(height: 8),
                    const Text('Places: A1, A2'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
            // TODO: Add custom locked illustration
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
              'Billet en attente',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Votre billet sera disponible après approbation de votre réservation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            // TODO: Add refresh/check status button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Refresh ticket status
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Vérifier le statut'),
            ),
          ],
        ),
      ),
    );
  }
}
