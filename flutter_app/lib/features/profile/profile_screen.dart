import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';

/// Profile Screen
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    setState(() => _isLoggingOut = true);
    
    try {
      // Clear token and logout - router refresh will handle navigation
      await ref.read(loginAuthStateProvider.notifier).logout();
      // Navigation happens automatically via router refresh on auth state change
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(loginAuthStateProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // User avatar and info
          const CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.backgroundGrey,
            child: Icon(Icons.person, size: 50, color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              user?.name ?? 'Utilisateur',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          if (user?.email != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                user!.email,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xxl),
          
          // Profile options
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
          const SizedBox(height: AppSpacing.xl),
          
          // Logout button using design system
          SizedBox(
            width: double.infinity,
            child: AppButtonSecondary(
              text: 'Se déconnecter',
              icon: Icons.logout,
              isLoading: _isLoggingOut,
              onPressed: _isLoggingOut ? null : _handleLogout,
            ),
          ),
        ],
      ),
    );
  }
}
