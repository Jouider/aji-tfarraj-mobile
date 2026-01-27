import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Reserve Seats Screen
/// TODO: Implement seat selection UI
/// TODO: Display available seats grid/map
/// TODO: Handle seat selection logic
/// TODO: Show price calculation
/// TODO: Add confirm reservation button
class ReserveSeatsScreen extends StatelessWidget {
  final String showId;

  const ReserveSeatsScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réserver des places'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Show $showId',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // TODO: Add seat selection grid
            const Text('Sélectionnez vos places:'),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: 40, // TODO: Replace with actual seat count
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 10)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add selected seats summary and price
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Process reservation
                  context.go(Routes.reservationSuccess);
                },
                child: const Text('Confirmer la réservation'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
