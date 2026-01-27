import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';

/// Profile Screen
/// TODO: Display user information
/// TODO: Add language selection option
/// TODO: Add logout functionality
/// TODO: Add other settings (notifications, help, about)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TODO: Add user avatar and info
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Nom d\'utilisateur',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Center(
            child: Text('+212 XXX XXX XXX'),
          ),
          const SizedBox(height: 32),
          // TODO: Add profile options
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Langue'),
            subtitle: const Text('Français'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show language selection dialog
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to notification settings
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Aide'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('À propos'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to about screen
            },
          ),
          const Divider(),
          const SizedBox(height: 24),
          // TODO: Add logout button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Implement logout
                context.go(Routes.login);
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Se déconnecter'),
            ),
          ),
        ],
      ),
    );
  }
}
