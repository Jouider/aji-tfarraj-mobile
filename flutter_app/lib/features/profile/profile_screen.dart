import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';

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
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

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
            leading: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_outlined),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 9 ? '9+' : unreadCount.toString(),
                        style: const TextStyle(
                          color: AppColors.backgroundWhite,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            title: const Text('Notifications'),
            subtitle: unreadCount > 0 
                ? Text('$unreadCount non lue${unreadCount > 1 ? 's' : ''}')
                : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.notifications),
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
