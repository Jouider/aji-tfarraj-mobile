import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Login Screen
/// TODO: Implement phone number input with country code
/// TODO: Add OTP verification flow
/// TODO: Integrate with authentication service
/// TODO: Handle login errors and validation
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TODO: Add phone number input field
            const TextField(
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixText: '+212 ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            // TODO: Implement OTP verification
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // TODO: Send OTP and navigate to verification
                  context.go(Routes.home);
                },
                child: const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
