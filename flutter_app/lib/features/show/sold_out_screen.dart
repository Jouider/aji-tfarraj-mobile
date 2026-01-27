import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Sold Out Screen
/// TODO: Display sold out message for the show
/// TODO: Add option to get notified if seats become available
/// TODO: Add button to browse other shows
class SoldOutScreen extends StatelessWidget {
  final String showId;

  const SoldOutScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complet'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: Add sold out illustration
              const Icon(
                Icons.event_busy,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Complet !',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Désolé, toutes les places pour le show $showId sont réservées.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // TODO: Add notification signup
              ElevatedButton(
                onPressed: () {
                  context.go(Routes.home);
                },
                child: const Text('Voir d\'autres émissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
