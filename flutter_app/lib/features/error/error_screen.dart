import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Error Screen
/// TODO: Display error message
/// TODO: Add retry button
/// TODO: Add go back/home options
class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Erreur'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TODO: Add error illustration
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              const Text(
                'Une erreur est survenue',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Veuillez réessayer plus tard.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // TODO: Add retry functionality
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement retry logic
                },
                child: const Text('Réessayer'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  context.go(Routes.home);
                },
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
