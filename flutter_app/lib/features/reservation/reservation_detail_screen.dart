import 'package:flutter/material.dart';

/// Reservation Detail Screen
/// TODO: Fetch reservation details from API using reservationId
/// TODO: Display show info, seats, date, time
/// TODO: Show QR code for entry
/// TODO: Add cancel reservation option
class ReservationDetailScreen extends StatelessWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la réservation'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Add show image
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.tv, size: 48)),
            ),
            const SizedBox(height: 16),
            Text(
              'Réservation #$reservationId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // TODO: Add reservation details
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Émission: Show Name'),
                    SizedBox(height: 8),
                    Text('Date: XX/XX/XXXX'),
                    SizedBox(height: 8),
                    Text('Heure: XX:XX'),
                    SizedBox(height: 8),
                    Text('Places: A1, A2'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Add QR code
            Container(
              height: 150,
              width: double.infinity,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.qr_code, size: 80),
              ),
            ),
            const SizedBox(height: 24),
            // TODO: Add cancel button with confirmation
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Implement cancel reservation
                },
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Annuler la réservation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
