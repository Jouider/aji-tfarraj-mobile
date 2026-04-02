import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
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

/// Reserve Seats Screen — dark premium redesign
class ReserveSeatsScreen extends ConsumerStatefulWidget {
  final String showId;
  final String? episodeId;

  const ReserveSeatsScreen({super.key, required this.showId, this.episodeId});

  @override
  ConsumerState<ReserveSeatsScreen> createState() => _ReserveSeatsScreenState();
}

class _ReserveSeatsScreenState extends ConsumerState<ReserveSeatsScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _errorMessage;
  final _referralCodeController = TextEditingController();
  bool _showReferralField = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill referral code from deep link if available
    final pending = ref.read(pendingReferralCodeProvider);
    if (pending != null && pending.isNotEmpty) {
      _referralCodeController.text = pending;
      _showReferralField = true;
    }
  }

  @override
  void dispose() {
    _referralCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showAsync = ref.watch(showDetailProvider(int.parse(widget.showId)));
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(s.reserveSeatsTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go(Routes.showDetail(widget.showId)),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
      ),
      body: showAsync.when(
        loading: () => const _ReserveSkeleton(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: s.retry,
          onRetry: () => ref.refresh(showDetailProvider(int.parse(widget.showId))),
        ),
        data: (show) => _buildContent(context, show, s),
      ),
    );
  }

  /// Resolve the episode to reserve from the show's data
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
              _ShowSummaryCard(
                  show: show, episode: episode, dateFormat: dateFormat),
              const SizedBox(height: AppSpacing.lg),
              _SeatsLeftBadge(seatsLeft: seatsLeft, s: s),
              const SizedBox(height: AppSpacing.xl),

              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: AppSpacing.lg),
              ],

              _InfoCard(s: s),
              const SizedBox(height: AppSpacing.lg),

              // ── Referral code (optional) ──
              if (!isSoldOut) ...[
                _ReferralCodeSection(
                  controller: _referralCodeController,
                  isExpanded: _showReferralField,
                  onToggle: () =>
                      setState(() => _showReferralField = !_showReferralField),
                  s: s,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // ── Agreement checkbox ──
              if (!isSoldOut)
                _AgreementSection(
                  agreed: _agreedToTerms,
                  onChanged: (v) => setState(() => _agreedToTerms = v),
                  s: s,
                ),

              const SizedBox(height: 100),
            ],
          ),
        ),

        // Sticky bottom CTA
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _StickyConfirmCTA(
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

    // Resolve the episode ID to submit
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
      final reservation = await ref.read(myReservationsProvider.notifier).createReservation(
            episodeId: episodeId,
            referralCode: referralCode.isNotEmpty ? referralCode : null,
          );

      // Clear pending referral code after successful reservation
      ref.read(pendingReferralCodeProvider.notifier).state = null;

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
        title: Text(s.profileIncompleteWarning),
        content: Text(s.profileIncompleteMessage),
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
    if (e.statusCode == 409) {
      return s.reserveSeatsErrSoldOut;
    }
    if (e.message.toLowerCase().contains('sold') ||
        e.message.toLowerCase().contains('complet') ||
        e.message.toLowerCase().contains('disponible')) {
      return s.reserveSeatsErrNotEnough;
    }
    if (e.statusCode == null) {
      return s.networkError;
    }
    return e.message;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Show Summary Card
// ─────────────────────────────────────────────────────────────────────────────

class _ShowSummaryCard extends ConsumerWidget {
  final Show show;
  final Episode? episode;
  final DateFormat dateFormat;

  const _ShowSummaryCard({
    required this.show,
    this.episode,
    required this.dateFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    // Prefer episode data when available
    final displayDate = episode?.startsAt ?? show.startsAt;
    final displayLocation = episode != null
        ? (episode!.studio ?? episode!.city)
        : (show.studio ?? show.city);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: show.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: show.imageUrl!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _ThumbPlaceholder(),
                    errorWidget: (_, __, ___) => _ThumbPlaceholder(),
                  )
                : _ThumbPlaceholder(),
          ),
          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Channel badge
                if (show.channel != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      show.channel!,
                      style: AppTypography.labelSmall.copyWith(color: AppColors.secondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],

                Text(
                  show.localizedTitle(isAr),
                  style: AppTypography.h4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Episode subtitle
                if (episode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    episode!.label,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),

                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        displayDate != null
                            ? dateFormat.format(displayDate.toLocal())
                            : '—',
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      displayLocation,
                      style: AppTypography.bodySmall,
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

class _ThumbPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      color: AppColors.backgroundLight,
      child: Icon(Icons.tv_outlined, color: AppColors.textLight, size: 32),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seats Left Badge
// ─────────────────────────────────────────────────────────────────────────────

class _SeatsLeftBadge extends StatelessWidget {
  final int seatsLeft;
  final AppStrings s;

  const _SeatsLeftBadge({required this.seatsLeft, required this.s});

  @override
  Widget build(BuildContext context) {
    final isSoldOut = seatsLeft == 0;
    final isLow = seatsLeft > 0 && seatsLeft <= 5;

    final bgColor = isSoldOut
        ? AppColors.errorLight
        : isLow
            ? AppColors.warningLight
            : AppColors.successLight;

    final fgColor = isSoldOut
        ? AppColors.error
        : isLow
            ? AppColors.warning
            : AppColors.success;

    final label = isSoldOut
        ? s.reserveSeatsSoldOutBadge
        : s.reserveSeatsAvailable(seatsLeft);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isSoldOut ? Icons.event_busy_outlined : Icons.event_seat_outlined,
            color: fgColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: fgColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Card
// ─────────────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final AppStrings s;

  const _InfoCard({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info_outline, color: AppColors.secondary, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.reserveSeatsInfoTitle,
                  style: AppTypography.labelMedium.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 4),
                Text(
                  s.reserveSeatsInfoBody,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Agreement Section (in scrollable content)
// ─────────────────────────────────────────────────────────────────────────────

class _AgreementSection extends StatelessWidget {
  final bool agreed;
  final ValueChanged<bool> onChanged;
  final AppStrings s;

  const _AgreementSection({
    required this.agreed,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!agreed),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: agreed
              ? AppColors.successLight
              : AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: agreed
                ? AppColors.success.withValues(alpha: 0.4)
                : AppColors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: agreed,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: AppColors.success,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.agreementCheckboxLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => context.push(Routes.rules),
                    child: Text(
                      s.agreementReadRules,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Confirm CTA
// ─────────────────────────────────────────────────────────────────────────────

class _StickyConfirmCTA extends StatelessWidget {
  final bool isLoading;
  final bool isSoldOut;
  final bool agreedToTerms;
  final VoidCallback onConfirm;
  final AppStrings s;

  const _StickyConfirmCTA({
    required this.isLoading,
    required this.isSoldOut,
    required this.agreedToTerms,
    required this.onConfirm,
    required this.s,
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
        color: AppColors.backgroundLight,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.reserveSeatsRecap,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                ),
                Row(
                  children: [
                    const Icon(Icons.event_seat_outlined, size: 16, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '1 ${s.place}',
                      style: AppTypography.h4,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            SizedBox(
              width: double.infinity,
              height: AppSpacing.buttonHeight,
              child: isSoldOut
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textLight,
                        side: BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: Text(
                        s.reserveSeatsSoldOutCta,
                        style: AppTypography.buttonLarge.copyWith(color: AppColors.textLight),
                      ),
                    )
                  : FilledButton(
                      onPressed: (isLoading || !agreedToTerms) ? null : onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.backgroundWhite,
                        disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                      ),
                      child: isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.backgroundWhite,
                              ),
                            )
                          : Text(s.reserveSeatsConfirm, style: AppTypography.buttonLarge),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Referral Code Section (optional, expandable)
// ─────────────────────────────────────────────────────────────────────────────

class _ReferralCodeSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isExpanded;
  final VoidCallback onToggle;
  final AppStrings s;

  const _ReferralCodeSection({
    required this.controller,
    required this.isExpanded,
    required this.onToggle,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundGrey,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.people_outline,
                    size: 20, color: AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    s.referralCodeLabel,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: AppColors.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            maxLength: 8,
            decoration: InputDecoration(
              hintText: s.referralCodeHint,
              hintStyle:
                  AppTypography.bodySmall.copyWith(color: AppColors.textLight),
              counterText: '',
              filled: true,
              fillColor: AppColors.backgroundLight,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                borderSide: const BorderSide(color: AppColors.secondary),
              ),
              prefixIcon: Icon(Icons.confirmation_number_outlined,
                  size: 18, color: AppColors.textMuted),
            ),
            style: AppTypography.bodyMedium.copyWith(
              letterSpacing: 2,
              fontWeight: AppTypography.medium,
            ),
          ),
        ],
      ],
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
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Row(
              children: [
                const SkeletonLoader(width: 80, height: 80, borderRadius: AppSpacing.radiusMd),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLoader.text(width: 80, height: 16),
                      const SizedBox(height: AppSpacing.xs),
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
          const SizedBox(height: AppSpacing.lg),
          SkeletonLoader.text(width: double.infinity, height: 50),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
