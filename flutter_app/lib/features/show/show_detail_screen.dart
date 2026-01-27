import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Show Detail Screen
/// TODO: Fetch show details from API using showId
/// TODO: Display show image, title, description, date, time
/// TODO: Show available seats count
/// TODO: Add reserve button
class ShowDetailScreen extends StatelessWidget {
  final String showId;

  const ShowDetailScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'émission'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // TODO: Add show image
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.tv, size: 64)),
            ),
            const SizedBox(height: 16),
            // TODO: Replace with actual show title
            Text(
              'Show $showId',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            // TODO: Add show description
            const Text('Description de l\'émission...'),
            const SizedBox(height: 16),
            // TODO: Add date and time info
            const Row(
              children: [
                Icon(Icons.calendar_today, size: 16),
                SizedBox(width: 8),
                Text('Date: XX/XX/XXXX'),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.access_time, size: 16),
                SizedBox(width: 8),
                Text('Heure: XX:XX'),
              ],
            ),
            const SizedBox(height: 24),
            // TODO: Add available seats info
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to reserve seats
                  context.go(Routes.showReserve(showId));
                },
                child: const Text('Réserver des places'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
