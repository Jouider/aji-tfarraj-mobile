import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Splash Screen - Initial app loading screen
/// TODO: Add app logo and branding
/// TODO: Add loading animation
/// TODO: Check authentication state and navigate accordingly
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement splash logic and auto-navigation
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        context.go(Routes.language);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aji Tfarraj'),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add app logo
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text(
              'Aji Tfarraj',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
