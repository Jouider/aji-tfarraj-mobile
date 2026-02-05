import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Show Detail Screen with hero image, info sections, rules, and sticky CTA
class ShowDetailScreen extends ConsumerWidget {
  final String showId;

  const ShowDetailScreen({super.key, required this.showId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showAsync = ref.watch(showDetailProvider(int.parse(showId)));

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: showAsync.when(
        loading: () => const _ShowDetailSkeleton(),
        error: (error, stack) => _ErrorView(
          message: error.toString(),
          onRetry: () => ref.refresh(showDetailProvider(int.parse(showId))),
          onBack: () => context.go(Routes.home),
        ),
        data: (show) => _ShowDetailContent(show: show, showId: showId),
      ),
    );
  }
}

/// Main content widget for show details
class _ShowDetailContent extends StatelessWidget {
  final Show show;
  final String showId;

  const _ShowDetailContent({required this.show, required this.showId});

  @override
  Widget build(BuildContext context) {
    final seatsLeft = show.availableSeats > 0 ? show.availableSeats : 0;
    final isSoldOut = seatsLeft == 0;

    return Stack(
      children: [
        // Scrollable content
        CustomScrollView(
          slivers: [
            // Hero Image with back button
            SliverToBoxAdapter(
              child: _HeroImageSection(show: show),
            ),
            
            // Content sections
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Seats left indicator
                    _SeatsIndicator(
                      seatsLeft: seatsLeft,
                      capacity: show.capacity,
                      reservedSeats: show.reservedSeats,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Show info section
                    _ShowInfoSection(show: show),
                    const SizedBox(height: AppSpacing.xl),

                    // Location section
                    _LocationSection(show: show),
                    const SizedBox(height: AppSpacing.xl),

                    // Rules section
                    const _RulesSection(),
                    
                    // Bottom padding for sticky CTA
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Back button overlay
        Positioned(
          top: MediaQuery.of(context).padding.top + AppSpacing.sm,
          left: AppSpacing.lg,
          child: _BackButton(onTap: () => context.go(Routes.home)),
        ),

        // Sticky bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyReserveCTA(
            isSoldOut: isSoldOut,
            onReserve: () => context.go(Routes.showReserve(showId)),
          ),
        ),
      ],
    );
  }
}

/// Hero image section with rounded bottom corners
class _HeroImageSection extends StatelessWidget {
  final Show show;

  const _HeroImageSection({required this.show});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppSpacing.radiusXl),
        bottomRight: Radius.circular(AppSpacing.radiusXl),
      ),
      child: SizedBox(
        height: 280,
        width: double.infinity,
        child: show.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: show.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundGrey,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                ),
                errorWidget: (context, url, error) => _ImagePlaceholder(),
              )
            : _ImagePlaceholder(),
      ),
    );
  }
}

/// Placeholder for missing/failed images
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundGrey,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tv,
              size: AppSpacing.iconXxl,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Image non disponible',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Back button overlay
class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.backgroundWhite.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: AppSpacing.iconLg,
        ),
      ),
    );
  }
}

/// Seats left indicator with progress bar
class _SeatsIndicator extends StatelessWidget {
  final int seatsLeft;
  final int capacity;
  final int reservedSeats;

  const _SeatsIndicator({
    required this.seatsLeft,
    required this.capacity,
    required this.reservedSeats,
  });

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft == 0;
    final progress = capacity > 0 ? reservedSeats / capacity : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSoldOut ? Icons.event_busy : Icons.event_seat,
                color: isSoldOut ? AppColors.error : AppColors.success,
                size: AppSpacing.iconLg,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  isSoldOut ? 'Complet' : '$seatsLeft places restantes',
                  style: AppTypography.h4.copyWith(
                    color: isSoldOut ? AppColors.error : AppColors.success,
                  ),
                ),
              ),
              Text(
                '$reservedSeats / $capacity',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.backgroundGrey,
              valueColor: AlwaysStoppedAnimation<Color>(
                isSoldOut ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Show info section with title, date, channel
class _ShowInfoSection extends StatelessWidget {
  final Show show;

  const _ShowInfoSection({required this.show});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm', 'fr_FR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(show.title, style: AppTypography.h2),
        const SizedBox(height: AppSpacing.md),

        // Channel badge
        if (show.channel != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tv, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  show.channel!,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Description
        if (show.description != null) ...[
          Text(
            show.description!,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Date & Time card
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date',
                value: dateFormat.format(show.startsAt.toLocal()),
              ),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.access_time_outlined,
                label: 'Heure',
                value: timeFormat.format(show.startsAt.toLocal()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Info row widget for date/time/location
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textMuted, size: AppSpacing.iconMd),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(value, style: AppTypography.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

/// Location section with city, studio, and open in maps button
class _LocationSection extends StatelessWidget {
  final Show show;

  const _LocationSection({required this.show});

  String get _locationText {
    if (show.studio != null && show.studio!.isNotEmpty) {
      return '${show.studio}, ${show.city}';
    }
    return show.city;
  }

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(_locationText);
    final url = Uri.parse('https://maps.google.com/?q=$query');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Lieu', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: AppSpacing.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (show.studio != null && show.studio!.isNotEmpty) ...[
                          Text(show.studio!, style: AppTypography.bodyMedium),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        Text(
                          show.city,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: AppButtonSecondary(
                  text: 'Ouvrir dans Maps',
                  icon: Icons.map_outlined,
                  isSmall: true,
                  onPressed: _openInMaps,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Rules section with bullet list
class _RulesSection extends StatelessWidget {
  const _RulesSection();

  @override
  Widget build(BuildContext context) {
    final rules = CopyFr.rules;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Règles', style: AppTypography.h4),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rules.introduction,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...rules.items.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rule.title,
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            rule.description,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Sticky bottom CTA for reservation
class _StickyReserveCTA extends StatelessWidget {
  final bool isSoldOut;
  final VoidCallback onReserve;

  const _StickyReserveCTA({
    required this.isSoldOut,
    required this.onReserve,
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
        child: SizedBox(
          width: double.infinity,
          child: isSoldOut
              ? AppButtonSecondary(
                  text: 'Complet',
                  onPressed: null,
                )
              : AppButton(
                  text: 'Réserver',
                  icon: Icons.confirmation_number_outlined,
                  onPressed: onReserve,
                ),
        ),
      ),
    );
  }
}

/// Skeleton loading state
class _ShowDetailSkeleton extends StatelessWidget {
  const _ShowDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero image skeleton
          const SkeletonLoader(
            width: double.infinity,
            height: 280,
            borderRadius: 0,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Seats indicator skeleton
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SkeletonLoader.circle(size: 24),
                          const SizedBox(width: AppSpacing.md),
                          SkeletonLoader.text(width: 150, height: 20),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SkeletonLoader.text(width: double.infinity, height: 8),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Title skeleton
                SkeletonLoader.text(width: double.infinity, height: 28),
                const SizedBox(height: AppSpacing.md),

                // Channel badge skeleton
                SkeletonLoader.text(width: 100, height: 24),
                const SizedBox(height: AppSpacing.lg),

                // Description skeleton
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.sm),
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.sm),
                SkeletonLoader.text(width: 200, height: 16),
                const SizedBox(height: AppSpacing.xl),

                // Date card skeleton
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          SkeletonLoader.circle(size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader.text(width: 40, height: 12),
                              const SizedBox(height: AppSpacing.xs),
                              SkeletonLoader.text(width: 150, height: 16),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          SkeletonLoader.circle(size: 20),
                          const SizedBox(width: AppSpacing.md),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonLoader.text(width: 40, height: 12),
                              const SizedBox(height: AppSpacing.xs),
                              SkeletonLoader.text(width: 80, height: 16),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Location section skeleton
                SkeletonLoader.text(width: 60, height: 20),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundWhite,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Row(
                    children: [
                      SkeletonLoader(
                        width: 48,
                        height: 48,
                        borderRadius: AppSpacing.radiusMd,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLoader.text(width: 120, height: 16),
                          const SizedBox(height: AppSpacing.xs),
                          SkeletonLoader.text(width: 80, height: 14),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error view with retry
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Back button
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _BackButton(onTap: onBack),
            ),
          ),
          // Error content
          Expanded(
            child: ErrorState(
              message: message,
              retryText: 'Réessayer',
              onRetry: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}
