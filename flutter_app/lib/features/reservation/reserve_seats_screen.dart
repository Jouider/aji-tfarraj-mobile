import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';

/// Reserve Seats Screen with seat picker and constraints
class ReserveSeatsScreen extends ConsumerStatefulWidget {
  final String showId;

  const ReserveSeatsScreen({super.key, required this.showId});

  @override
  ConsumerState<ReserveSeatsScreen> createState() => _ReserveSeatsScreenState();
}

class _ReserveSeatsScreenState extends ConsumerState<ReserveSeatsScreen> {
  int _selectedSeats = 1;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final showAsync = ref.watch(showDetailProvider(int.parse(widget.showId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Réserver des places', style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.showDetail(widget.showId)),
        ),
      ),
      body: showAsync.when(
        loading: () => const _ReserveSkeleton(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: 'Réessayer',
          onRetry: () => ref.refresh(showDetailProvider(int.parse(widget.showId))),
        ),
        data: (show) => _buildContent(context, show),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Show show) {
    final seatsLeft = show.availableSeats > 0 ? show.availableSeats : 0;
    final maxSeats = seatsLeft.clamp(0, 4);
    final isSoldOut = seatsLeft == 0;
    final dateFormat = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');

    // Ensure selected seats doesn't exceed max
    if (_selectedSeats > maxSeats && maxSeats > 0) {
      _selectedSeats = maxSeats;
    }

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show summary card
              _ShowSummaryCard(
                show: show,
                dateFormat: dateFormat,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Seats left indicator
              _SeatsLeftBadge(seatsLeft: seatsLeft),
              const SizedBox(height: AppSpacing.xl),

              // Seat picker section
              Text('Nombre de places', style: AppTypography.h4),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Maximum 4 places par réservation • $seatsLeft restantes',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Seat picker
              _SeatPicker(
                selectedSeats: _selectedSeats,
                maxSeats: maxSeats,
                isDisabled: _isLoading || isSoldOut,
                onDecrement: () => setState(() => _selectedSeats--),
                onIncrement: () => setState(() => _selectedSeats++),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Error message
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Info card
              _InfoCard(),
              
              // Bottom padding for sticky CTA
              const SizedBox(height: 120),
            ],
          ),
        ),

        // Sticky bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyConfirmCTA(
            selectedSeats: _selectedSeats,
            isLoading: _isLoading,
            isSoldOut: isSoldOut,
            onConfirm: () => _submitReservation(context),
          ),
        ),
      ],
    );
  }

  Future<void> _submitReservation(BuildContext context) async {
    final router = GoRouter.of(context);
    final analytics = ref.read(analyticsServiceProvider);
    final showId = int.parse(widget.showId);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Fire before the API call
    analytics.logReserveAttempt(showId: showId, seats: _selectedSeats);

    try {
      final reservation = await ref.read(myReservationsProvider.notifier).createReservation(
            showId: showId,
            seats: _selectedSeats,
          );

      if (!mounted) return;

      // Fire after successful API response
      analytics.logReserveSuccess(
        showId: showId,
        reservationId: reservation.id,
        seats: _selectedSeats,
      );

      // Navigate to result screen with reservation ID
      router.go(Routes.reservationResult(reservation.id.toString()));
    } on ApiException catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
        _errorMessage = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      });
    }
  }

  String _getErrorMessage(ApiException e) {
    // 401 is handled globally by API client (auto logout)
    if (e.statusCode == 422) {
      // Validation error
      if (e.errors != null && e.errors!.isNotEmpty) {
        final firstError = e.errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return e.message;
    }
    
    if (e.statusCode == 409) {
      // Conflict - likely sold out or already reserved
      return 'Places complètes. Pas assez de places disponibles.';
    }
    
    if (e.message.toLowerCase().contains('sold') || 
        e.message.toLowerCase().contains('complet') ||
        e.message.toLowerCase().contains('disponible')) {
      return 'Pas assez de places disponibles.';
    }
    
    if (e.statusCode == null) {
      // Network error
      return 'Problème de connexion. Vérifiez votre connexion internet.';
    }
    
    return e.message;
  }
}

/// Show summary card at top
class _ShowSummaryCard extends StatelessWidget {
  final Show show;
  final DateFormat dateFormat;

  const _ShowSummaryCard({
    required this.show,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(Icons.tv, color: AppColors.textMuted, size: 32),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  show.title,
                  style: AppTypography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, 
                      size: 14, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        dateFormat.format(show.startsAt.toLocal()),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, 
                      size: 14, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      show.city,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Seats left badge
class _SeatsLeftBadge extends StatelessWidget {
  final int seatsLeft;

  const _SeatsLeftBadge({required this.seatsLeft});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft == 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isSoldOut ? AppColors.errorLight : AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Icon(
            isSoldOut ? Icons.event_busy : Icons.event_seat,
            color: isSoldOut ? AppColors.error : AppColors.success,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isSoldOut ? 'Complet' : '$seatsLeft places restantes',
              style: AppTypography.labelMedium.copyWith(
                color: isSoldOut ? AppColors.error : AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Seat picker with +/- buttons
class _SeatPicker extends StatelessWidget {
  final int selectedSeats;
  final int maxSeats;
  final bool isDisabled;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _SeatPicker({
    required this.selectedSeats,
    required this.maxSeats,
    required this.isDisabled,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final canDecrement = selectedSeats > 1 && !isDisabled;
    final canIncrement = selectedSeats < maxSeats && !isDisabled;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decrement button
          _CircleButton(
            icon: Icons.remove,
            onPressed: canDecrement ? onDecrement : null,
          ),
          const SizedBox(width: AppSpacing.xxl),

          // Seat count display
          Column(
            children: [
              Text(
                '$selectedSeats',
                style: AppTypography.h1.copyWith(
                  fontSize: 56,
                  color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
                ),
              ),
              Text(
                selectedSeats == 1 ? 'place' : 'places',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.xxl),

          // Increment button
          _CircleButton(
            icon: Icons.add,
            onPressed: canIncrement ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

/// Circle button for seat picker
class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleButton({
    required this.icon,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.backgroundGrey,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppColors.backgroundWhite : AppColors.textMuted,
          size: 28,
        ),
      ),
    );
  }
}

/// Error banner
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info card about reservation process
class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Votre demande sera examinée par notre équipe. Vous recevrez une confirmation une fois approuvée.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sticky bottom CTA
class _StickyConfirmCTA extends StatelessWidget {
  final int selectedSeats;
  final bool isLoading;
  final bool isSoldOut;
  final VoidCallback onConfirm;

  const _StickyConfirmCTA({
    required this.selectedSeats,
    required this.isLoading,
    required this.isSoldOut,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  '$selectedSeats ${selectedSeats == 1 ? 'place' : 'places'}',
                  style: AppTypography.h4,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            
            // Confirm button
            SizedBox(
              width: double.infinity,
              child: isSoldOut
                  ? AppButtonSecondary(
                      text: 'Complet',
                      onPressed: null,
                    )
                  : AppButton(
                      text: 'Confirmer la réservation',
                      isLoading: isLoading,
                      onPressed: isLoading ? null : onConfirm,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loading state
class _ReserveSkeleton extends StatelessWidget {
  const _ReserveSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Show summary skeleton
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              children: [
                SkeletonLoader(width: 64, height: 64, borderRadius: AppSpacing.radiusMd),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.text(width: double.infinity, height: 20),
                      const SizedBox(height: AppSpacing.sm),
                      SkeletonLoader.text(width: 150, height: 14),
                      const SizedBox(height: AppSpacing.xs),
                      SkeletonLoader.text(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          // Seats badge skeleton
          SkeletonLoader.text(width: double.infinity, height: 44),
          const SizedBox(height: AppSpacing.xl),

          // Section title skeleton
          SkeletonLoader.text(width: 150, height: 20),
          const SizedBox(height: AppSpacing.sm),
          SkeletonLoader.text(width: 250, height: 14),
          const SizedBox(height: AppSpacing.lg),

          // Seat picker skeleton
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.backgroundWhite,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLoader.circle(size: 56),
                const SizedBox(width: AppSpacing.xxl),
                Column(
                  children: [
                    SkeletonLoader.text(width: 60, height: 56),
                    const SizedBox(height: AppSpacing.xs),
                    SkeletonLoader.text(width: 50, height: 16),
                  ],
                ),
                const SizedBox(width: AppSpacing.xxl),
                SkeletonLoader.circle(size: 56),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
