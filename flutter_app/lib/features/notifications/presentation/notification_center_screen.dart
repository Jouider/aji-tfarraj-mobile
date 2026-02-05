// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/features/notifications/presentation/notification_center_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/app/router.dart';
import 'package:aji_tfarraj/features/notifications/domain/app_notification.dart';
import 'package:aji_tfarraj/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:aji_tfarraj/features/notifications/presentation/widgets/notification_card.dart';

/// Notification Center Screen
/// Displays all notifications with actions to mark as read, delete, and navigate
class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final router = ref.watch(routerProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (notificationsState.hasNotifications) ...[
            // Mark all as read
            if (notificationsState.hasUnread)
              IconButton(
                icon: const Icon(Icons.done_all),
                tooltip: 'Tout marquer comme lu',
                onPressed: () {
                  ref.read(notificationsProvider.notifier).markAllAsRead();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Toutes les notifications marquées comme lues'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            // Clear all
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _showClearAllDialog(context, ref);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: AppColors.error),
                      SizedBox(width: AppSpacing.sm),
                      Text('Tout supprimer'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _buildContent(context, ref, notificationsState, router),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    NotificationsState state,
    GoRouter router,
  ) {
    // Loading state
    if (state.isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: 5,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: const NotificationCardSkeleton(),
        ),
      );
    }

    // Error state
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        retryText: 'Réessayer',
        onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
      );
    }

    // Empty state
    if (!state.hasNotifications) {
      return EmptyState(
        icon: Icons.notifications_none,
        title: 'Aucune notification',
        description: 'Vous n\'avez pas encore reçu de notification.',
      );
    }

    // Notifications list
    return RefreshIndicator(
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.notifications.length,
        itemBuilder: (context, index) {
          final notification = state.notifications[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: NotificationCard(
              notification: notification,
              onTap: () => _onNotificationTap(context, ref, notification, router),
              onDismiss: () => _onNotificationDismiss(context, ref, notification),
            ),
          );
        },
      ),
    );
  }

  void _onNotificationTap(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
    GoRouter router,
  ) {
    // Mark as read
    ref.read(notificationsProvider.notifier).markAsRead(notification.id);

    // Navigate using PushRouter
    PushRouter.navigateToNotification(router, notification);
  }

  void _onNotificationDismiss(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    ref.read(notificationsProvider.notifier).deleteNotification(notification.id);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Notification supprimée'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () {
            // Re-add the notification
            ref.read(notificationsProvider.notifier).addNotification(notification);
          },
        ),
      ),
    );
  }

  void _showClearAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).clearAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Toutes les notifications ont été supprimées'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
