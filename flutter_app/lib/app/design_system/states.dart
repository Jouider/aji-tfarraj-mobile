import 'package:flutter/material.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';

/// Aji Tfarraj State Widgets
/// Empty, Loading, and Error states

/// Empty State Widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    required this.title,
    this.description,
    this.actionText,
    this.onAction,
  });

  /// No reservations
  factory EmptyState.noReservations({VoidCallback? onAction}) => EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'Aucune réservation',
        description: 'Vous n\'avez pas encore de réservation.',
        actionText: 'Découvrir les spectacles',
        onAction: onAction,
      );

  /// No shows
  factory EmptyState.noShows({VoidCallback? onAction}) => EmptyState(
        icon: Icons.theater_comedy_outlined,
        title: 'Aucun spectacle',
        description: 'Aucun spectacle disponible pour le moment.',
        actionText: 'Réessayer',
        onAction: onAction,
      );

  /// No tickets
  factory EmptyState.noTickets({VoidCallback? onAction}) => EmptyState(
        icon: Icons.confirmation_number_outlined,
        title: 'Aucun billet',
        description: 'Vous n\'avez pas encore de billet.',
        actionText: 'Réserver un spectacle',
        onAction: onAction,
      );

  /// No search results
  factory EmptyState.noSearchResults({VoidCallback? onAction}) => EmptyState(
        icon: Icons.search_off_outlined,
        title: 'Aucun résultat',
        description: 'Aucun résultat ne correspond à votre recherche.',
        actionText: 'Effacer la recherche',
        onAction: onAction,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: AppTypography.h4,
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButtonSecondary(
                text: actionText!,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading State Widget
class LoadingState extends StatelessWidget {
  final String? message;
  final bool inline;

  const LoadingState({
    super.key,
    this.message,
    this.inline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.secondary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.secondary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              message!,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error State Widget
class ErrorState extends StatelessWidget {
  final String message;
  final String? retryText;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.retryText,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Network error
  factory ErrorState.network({VoidCallback? onRetry}) => ErrorState(
        icon: Icons.wifi_off_outlined,
        message: 'Impossible de se connecter au serveur.\nVeuillez vérifier votre connexion internet.',
        retryText: 'Réessayer',
        onRetry: onRetry,
      );

  /// Unauthorized error
  factory ErrorState.unauthorized({VoidCallback? onRetry}) => ErrorState(
        icon: Icons.lock_outline,
        message: 'Votre session a expiré.\nVeuillez vous reconnecter.',
        retryText: 'Se connecter',
        onRetry: onRetry,
      );

  /// Generic error
  factory ErrorState.generic({VoidCallback? onRetry}) => ErrorState(
        icon: Icons.error_outline,
        message: 'Une erreur inattendue est survenue.\nVeuillez réessayer.',
        retryText: 'Réessayer',
        onRetry: onRetry,
      );

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
            if (retryText != null && onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButtonSecondary(
                text: retryText!,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
