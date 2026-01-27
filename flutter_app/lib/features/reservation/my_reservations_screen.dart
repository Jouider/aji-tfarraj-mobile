import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// My Reservations Screen
/// TODO: Fetch user reservations from API
/// TODO: Display list of reservations with status
/// TODO: Add pull-to-refresh functionality
/// TODO: Handle empty state
class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes réservations'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3, // TODO: Replace with actual reservation count
        itemBuilder: (context, index) {
          final reservationId = '${index + 1}';
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              // TODO: Add show thumbnail
              leading: Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.confirmation_number),
              ),
              title: Text('Réservation $reservationId'), // TODO: Replace with show title
              subtitle: const Text('Date: XX/XX/XXXX'), // TODO: Replace with reservation date
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                // Navigate to reservation detail with reservationId
                context.go(Routes.reservationDetail(reservationId));
              },
            ),
          );
        },
      ),
    );
  }
}
