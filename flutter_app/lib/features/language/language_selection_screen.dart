import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Language Selection Screen
/// TODO: Implement language selection UI with French and Arabic options
/// TODO: Save selected language to persistent storage
/// TODO: Update app locale based on selection
class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisir la langue'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add language selection buttons with flags
            const Text(
              'Sélectionnez votre langue',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Set language to French
                context.go(Routes.login);
              },
              child: const Text('Français'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Set language to Arabic and enable RTL
                context.go(Routes.login);
              },
              child: const Text('العربية'),
            ),
          ],
        ),
      ),
    );
  }
}
