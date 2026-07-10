import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/reservation/confirmation_hero_widget.dart';
import 'package:aji_tfarraj/features/reservation/reservation_summary_card_widget.dart';
import 'package:aji_tfarraj/features/reservation/next_steps_section_widget.dart';
import 'package:aji_tfarraj/features/reservation/confirmation_actions_widget.dart';

/// Reservation Result Screen — "Réservation envoyée" confirmation.
/// FIX: Full-immersive (no app bar), backgroundWhite, SafeArea, entry animations.
class ReservationResultScreen extends ConsumerWidget {
  final String reservationId;

  const ReservationResultScreen({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationAsync = ref.watch(
        reservationDetailProvider(int.parse(reservationId)));

    return Scaffold(
      // FIX: No app bar — full immersive confirmation feel
      // FIX: backgroundWhite token
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: reservationAsync.when(
          loading: () => const _ResultSkeleton(),
          error: (error, stack) => ErrorState(
            message: error.toString(),
            retryText: 'Réessayer',
            onRetry: () => ref.refresh(
                reservationDetailProvider(int.parse(reservationId))),
          ),
          data: (reservation) => _ResultContent(reservation: reservation),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Animated Content
// ─────────────────────────────────────────────────────────────────────────────

class _ResultContent extends ConsumerStatefulWidget {
  final Reservation reservation;

  const _ResultContent({required this.reservation});

  @override
  ConsumerState<_ResultContent> createState() => _ResultContentState();
}

class _ResultContentState extends ConsumerState<_ResultContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // FIX: Sequential fade+slide-up entry animations with staggered delays
  late final Animation<double> _heroOpacity;
  late final Animation<Offset> _heroSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;
  late final Animation<double> _stepsOpacity;
  late final Animation<Offset> _stepsSlide;

  @override
  void initState() {
    super.initState();
    // Total duration covers last element end: 500ms delay + 350ms = 850ms
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _heroOpacity = _interval(0.00, 0.44);
    _heroSlide = _slideInterval(0.00, 0.44);
    _cardOpacity = _interval(0.39, 0.78);
    _cardSlide = _slideInterval(0.39, 0.78);
    _stepsOpacity = _interval(0.56, 1.00);
    _stepsSlide = _slideInterval(0.56, 1.00);
  }

  Animation<double> _interval(double begin, double end) =>
      CurvedAnimation(
        parent: _ctrl,
        curve: Interval(begin, end, curve: Curves.easeOut),
      );

  Animation<Offset> _slideInterval(double begin, double end) =>
      Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _ctrl,
        curve: Interval(begin, end, curve: Curves.easeOut),
      ));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Navigate back to the home screen. Used by the top-left back control
  /// and the swipe-to-go-back gesture.
  void _goHome() => context.go(Routes.home);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // FIX: Actions pinned to a persistent bottom bar. A top-left back control
    // ("Retour") + an edge swipe both return to home.
    return GestureDetector(
      // Swipe-to-go-back: right-swipe in LTR, left-swipe in RTL.
      onHorizontalDragEnd: (details) {
        final v = details.primaryVelocity ?? 0;
        if (!isRtl && v > 250) _goHome();
        if (isRtl && v < -250) _goHome();
      },
      child: Column(
        children: [
          // Top-left back control (arrow + "Retour") → home.
          _Animated(
            opacity: _heroOpacity,
            slide: _heroSlide,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: TextButton.icon(
                  onPressed: _goHome,
                  icon: Icon(
                    isRtl ? Icons.arrow_forward_ios : Icons.arrow_back_ios_new,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  label: Text(
                    s.back,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  // FIX: Top spacing below the back control
                  const SizedBox(height: 16),

                  // Hero: icon + title + status badge (animated separately but in same widget)
                  // We split into 3 animated wrappers to match the stagger
                  _Animated(
                    opacity: _heroOpacity,
                    slide: _heroSlide,
                    child: const ConfirmationHero(),
                  ),

                // FIX: status badge → title spacing 28px, badge → card 28px
                const SizedBox(height: 28),

                _Animated(
                  opacity: _cardOpacity,
                  slide: _cardSlide,
                  child: ReservationSummaryCard(reservation: widget.reservation),
                ),

                const SizedBox(height: 28),

                _Animated(
                  opacity: _stepsOpacity,
                  slide: _stepsSlide,
                  child: const NextStepsSection(),
                ),

                // FIX: Bottom spacing before the pinned action bar
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

          // FIX: Persistent action bar — primary CTA only ("Voir mes
          // réservations"); "Retour" now lives top-left + swipe-back.
          _Animated(
            opacity: _stepsOpacity,
            slide: _stepsSlide,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 16, AppSpacing.lg, 12),
              child: const ConfirmationActions(showHomeButton: false),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable fade + slide-up wrapper.
class _Animated extends StatelessWidget {
  final Animation<double> opacity;
  final Animation<Offset> slide;
  final Widget child;

  const _Animated({
    required this.opacity,
    required this.slide,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: slide,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loading
// ─────────────────────────────────────────────────────────────────────────────

class _ResultSkeleton extends StatelessWidget {
  const _ResultSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.xxl),
          SkeletonLoader.circle(size: 120),
          const SizedBox(height: AppSpacing.xl),
          SkeletonLoader.text(width: 200, height: 28),
          const SizedBox(height: AppSpacing.md),
          SkeletonLoader.text(width: 180, height: 36),
          const SizedBox(height: AppSpacing.xxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.cardDarkElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SkeletonLoader(
                        width: 44,
                        height: 44,
                        borderRadius: AppSpacing.radiusMd),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLoader.text(width: 150, height: 18),
                        const SizedBox(height: AppSpacing.xs),
                        SkeletonLoader.text(width: 80, height: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.text(width: double.infinity, height: 1),
                const SizedBox(height: AppSpacing.lg),
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.md),
                SkeletonLoader.text(width: double.infinity, height: 16),
                const SizedBox(height: AppSpacing.md),
                SkeletonLoader.text(width: double.infinity, height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
