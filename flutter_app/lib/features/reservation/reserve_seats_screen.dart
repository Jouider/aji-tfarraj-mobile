import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/loading/skeleton_loader.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/shows/data/shows_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/shows/domain/episode.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/referral/data/referral_repository.dart';
import 'package:aji_tfarraj/features/referral/data/referral_attribution_service.dart';
import 'package:aji_tfarraj/features/reservation/booking_show_summary_card_widget.dart';
import 'package:aji_tfarraj/features/reservation/seats_availability_banner_widget.dart';
import 'package:aji_tfarraj/features/reservation/booking_info_card_widget.dart';
import 'package:aji_tfarraj/features/reservation/referral_code_input_widget.dart';
import 'package:aji_tfarraj/features/reservation/terms_checkbox_widget.dart';
import 'package:aji_tfarraj/features/reservation/booking_bottom_bar_widget.dart';

/// Reserve Seats Screen — "Réserver des places" booking flow.
class ReserveSeatsScreen extends ConsumerStatefulWidget {
  final String showId;
  final String? episodeId;

  const ReserveSeatsScreen({super.key, required this.showId, this.episodeId});

  @override
  ConsumerState<ReserveSeatsScreen> createState() =>
      _ReserveSeatsScreenState();
}

class _ReserveSeatsScreenState extends ConsumerState<ReserveSeatsScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  final _referralCodeController = TextEditingController();
  bool _referralInitiallyExpanded = false;

  @override
  void initState() {
    super.initState();
    final pending = ref.read(pendingReferralCodeProvider);
    if (pending != null && pending.isNotEmpty) {
      _referralCodeController.text = pending;
      _referralInitiallyExpanded = true;
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAsync =
        ref.watch(showDetailProvider(int.parse(widget.showId)));
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      // FIX: App bar — backgroundWhite bg, textPrimary title w700 17px centered, bottom border
      appBar: AppBar(
        title: Text(
          s.reserveSeatsTitle,
          style: AppTypography.h3.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: AppColors.textPrimary, size: 22),
          onPressed: () => context.go(Routes.showDetail(widget.showId)),
        ),
        // FIX: Bottom border — border token
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: showAsync.when(
        loading: () => const _ReserveSkeleton(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: s.retry,
          onRetry: () => ref
              .refresh(showDetailProvider(int.parse(widget.showId))),
        ),
        data: (show) => _buildContent(context, show, s),
      ),
    );
  }

  Episode? _resolveEpisode(Show show) {
    if (widget.episodeId != null) {
      final targetId = int.parse(widget.episodeId!);
      final match = show.episodes.where((e) => e.id == targetId);
      if (match.isNotEmpty) return match.first;
    }
    return show.nextEpisode;
  }

  Widget _buildContent(BuildContext context, Show show, AppStrings s) {
    final episode = _resolveEpisode(show);
    final seatsLeft = episode != null
        ? (episode.availableSeats > 0 ? episode.availableSeats : 0)
        : (show.availableSeats > 0 ? show.availableSeats : 0);
    final isSoldOut = seatsLeft == 0;
    final dateFormat = DateFormat('dd MMM yyyy · HH:mm', 'fr_FR');

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FIX: Show summary card — cardDarkElevated, unified channel badge
              BookingShowSummaryCard(
                show: show,
                episode: episode,
                dateFormat: dateFormat,
              ),
              const SizedBox(height: AppSpacing.lg),

              // FIX: Seats banner — secondary tokens, urgency <10 → error tokens
              SeatsAvailabilityBanner(
                seatsLeft: seatsLeft,
                availableLabel: s.reserveSeatsAvailable(seatsLeft),
                soldOutLabel: s.reserveSeatsSoldOutBadge,
              ),
              const SizedBox(height: AppSpacing.xl),

              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.lg),
              ],

              // FIX: Info card — warningLight bg, secondary icon circle
              BookingInfoCard(s: s),
              const SizedBox(height: AppSpacing.lg),

              if (!isSoldOut) ...[
                // FIX: Referral code — expandable, secondary border on focus
                ReferralCodeInput(
                  controller: _referralCodeController,
                  s: s,
                  initiallyExpanded: _referralInitiallyExpanded,
                ),
                const SizedBox(height: AppSpacing.lg),

                // FIX: Terms checkbox — branded primary checkbox, scale bounce
                TermsCheckbox(
                  value: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v),
                  s: s,
                ),
              ],

              const SizedBox(height: 120),
            ],
          ),
        ),

        // FIX: Sticky bottom bar — primary CTA, recap row, backgroundLight bg
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BookingBottomBar(
            isLoading: _isLoading,
            isSoldOut: isSoldOut,
            agreedToTerms: _agreedToTerms,
            onConfirm: () => _submitReservation(context),
            s: s,
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

    final showAsync = ref.read(showDetailProvider(showId));
    final show = showAsync.valueOrNull;
    final episode = show != null ? _resolveEpisode(show) : null;
    final episodeId = episode?.id;

    if (episodeId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = ref.read(stringsProvider).unknownError;
      });
      return;
    }

    analytics.logReserveAttempt(showId: showId, seats: 1);

    try {
      final referralCode = _referralCodeController.text.trim();
      final reservation = await ref
          .read(myReservationsProvider.notifier)
          .createReservation(
            episodeId: episodeId,
            referralCode: referralCode.isNotEmpty ? referralCode : null,
          );

      // Attribution consumed — clear both the in-memory and the persisted code
      // so a future organic reservation isn't wrongly attributed to the CP.
      ref.read(pendingReferralCodeProvider.notifier).state = null;
      ref.read(referralAttributionServiceProvider).clearStoredCode();

      if (!mounted) return;

      analytics.logReserveSuccess(
        showId: showId,
        reservationId: reservation.id,
        seats: 1,
      );

      router.go(Routes.reservationResult(reservation.id.toString()));
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409 && e.code == 'PROFILE_INCOMPLETE') {
        setState(() => _isLoading = false);
        _showProfileIncompleteDialog();
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = _getErrorMessage(e);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ref.read(stringsProvider).unknownError;
      });
    }
  }

  void _showProfileIncompleteDialog() {
    final s = ref.read(stringsProvider);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceOverlay,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(s.profileIncompleteWarning, style: AppTypography.h3),
        content: Text(s.profileIncompleteMessage,
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.push(Routes.editProfile);
            },
            child: Text(s.completeProfileButton),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(ApiException e) {
    final s = ref.read(stringsProvider);
    if (e.statusCode == 422) {
      if (e.errors != null && e.errors!.isNotEmpty) {
        final firstError = e.errors!.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
      }
      return e.message;
    }
    if (e.statusCode == 409) return s.reserveSeatsErrSoldOut;
    if (e.message.toLowerCase().contains('sold') ||
        e.message.toLowerCase().contains('complet') ||
        e.message.toLowerCase().contains('disponible')) {
      return s.reserveSeatsErrNotEnough;
    }
    // Centralized mapping: 401 → session expired, 429 → rate limit,
    // parse/5xx → generic, null statusCode → network, else server message.
    return e.userMessage(s);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error Banner
// ─────────────────────────────────────────────────────────────────────────────

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
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton Loading
// ─────────────────────────────────────────────────────────────────────────────

class _ReserveSkeleton extends StatelessWidget {
  const _ReserveSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SkeletonLoader(
                    width: 80,
                    height: 80,
                    borderRadius: AppSpacing.radiusMd),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.text(width: 80, height: 16),
                      const SizedBox(height: AppSpacing.xs),
                      SkeletonLoader.text(
                          width: double.infinity, height: 20),
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
          const SizedBox(height: AppSpacing.lg),
          SkeletonLoader.text(width: double.infinity, height: 50),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
