import 'dart:async';
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
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/reservations/presentation/reservation_status.dart';

/// My Reservations Screen with 3 tabs: Pending, Approved, Past
class MyReservationsScreen extends ConsumerStatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  ConsumerState<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends ConsumerState<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _autoRefreshTimer;

  /// Poll interval — refresh reservations every 30s while screen is visible
  static const _pollInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_pollInterval, (_) {
      if (mounted) {
        ref.read(myReservationsProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      // FIX: App bar — backgroundWhite, centered title, w700 18px, no back arrow
      appBar: AppBar(
        title: Text(
          s.myReservationsTitle,
          style: AppTypography.h4.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: reservationsAsync.when(
            loading: () => _buildTabBar(0, 0, 0),
            error: (_, __) => _buildTabBar(0, 0, 0),
            data: (reservations) {
              final counts = _getTabCounts(reservations);
              return _buildTabBar(counts.pending, counts.approved, counts.past);
            },
          ),
        ),
      ),
      body: reservationsAsync.when(
        loading: () => const _ReservationsSkeleton(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: s.myResRetryLabel,
          onRetry: () => ref.read(myReservationsProvider.notifier).refresh(),
        ),
        data: (reservations) => _buildTabContent(reservations),
      ),
    );
  }

  // FIX: Tab bar — UnderlineTabIndicator primary 3px, active w700 primary, inactive w400 textMuted, bottom border
  Widget _buildTabBar(int pending, int approved, int past) {
    final s = ref.read(stringsProvider);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w400),
        dividerColor: Colors.transparent,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.circular(2),
        ),
        tabs: [
          Tab(text: '${s.myResTabPending}${pending > 0 ? ' ($pending)' : ''}'),
          Tab(text: '${s.myResTabApproved}${approved > 0 ? ' ($approved)' : ''}'),
          Tab(text: '${s.myResTabPast}${past > 0 ? ' ($past)' : ''}'),
        ],
      ),
    );
  }

  Widget _buildTabContent(List<Reservation> reservations) {
    final pending = _filterPending(reservations);
    final approved = _filterApproved(reservations);
    final past = _filterPast(reservations);
    final s = ref.read(stringsProvider);

    return TabBarView(
      controller: _tabController,
      children: [
        _ReservationsList(
          reservations: pending,
          emptyMessage: s.myResEmptyPending,
          emptySubMessage: s.myResEmptyPendingSubtitle,
          onRefresh: () => ref.read(myReservationsProvider.notifier).refresh(),
        ),
        _ReservationsList(
          reservations: approved,
          emptyMessage: s.myResEmptyApproved,
          emptySubMessage: s.myResEmptyApprovedSubtitle,
          onRefresh: () => ref.read(myReservationsProvider.notifier).refresh(),
        ),
        _ReservationsList(
          reservations: past,
          emptyMessage: s.myResEmptyPast,
          emptySubMessage: s.myResEmptyPastSubtitle,
          onRefresh: () => ref.read(myReservationsProvider.notifier).refresh(),
        ),
      ],
    );
  }

  // ============================================
  // Helper methods to filter reservations
  // ============================================

  _TabCounts _getTabCounts(List<Reservation> reservations) {
    return _TabCounts(
      pending: _filterPending(reservations).length,
      approved: _filterApproved(reservations).length,
      past: _filterPast(reservations).length,
    );
  }

  List<Reservation> _filterPending(List<Reservation> reservations) {
    return reservations
        .where((r) => ReservationStatusHelper(r.status).isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Reservation> _filterApproved(List<Reservation> reservations) {
    return reservations
        .where((r) => ReservationStatusHelper(r.status).isApproved)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<Reservation> _filterPast(List<Reservation> reservations) {
    return reservations
        .where((r) => ReservationStatusHelper(r.status).isFinal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
}

class _TabCounts {
  final int pending;
  final int approved;
  final int past;

  _TabCounts({required this.pending, required this.approved, required this.past});
}

/// Reservations list with pull-to-refresh and empty state
class _ReservationsList extends ConsumerWidget {
  final List<Reservation> reservations;
  final String emptyMessage;
  final String emptySubMessage;
  final Future<void> Function() onRefresh;

  const _ReservationsList({
    required this.reservations,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (reservations.isEmpty) {
      // FIX: Empty state — icon, title, subtitle, CTA to browse
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 56,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: AppTypography.labelLarge.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    emptySubMessage,
                    style: AppTypography.bodyMedium.copyWith(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => context.go(Routes.home),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      ref.read(stringsProvider).browseShows,
                      style: AppTypography.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _ReservationCard(reservation: reservations[index]),
          );
        },
      ),
    );
  }
}

/// Reservation card with show info, status badge, and cancel action
class _ReservationCard extends ConsumerStatefulWidget {
  final Reservation reservation;

  const _ReservationCard({required this.reservation});

  @override
  ConsumerState<_ReservationCard> createState() => _ReservationCardState();
}

class _ReservationCardState extends ConsumerState<_ReservationCard> {
  bool _isCancelling = false;

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final statusHelper = ReservationStatusHelper(reservation.status);
    final isAr = ref.watch(isRtlProvider);
    final dateFormat = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');
    final s = ref.watch(stringsProvider);

    // FIX: Card — cardDarkElevated bg, border token, radius 16, shadow 6%
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go(Routes.reservationDetail(reservation.id.toString())),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Top row: image + show info ───
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FIX: Image — 70×70, radius 12
                  _ShowThumbnail(imageUrl: reservation.show?.imageUrl),
                  const SizedBox(width: AppSpacing.md),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FIX: Title — 15px w600 textPrimary
                        Text(
                          reservation.show?.localizedTitle(isAr) ?? 'Émission #${reservation.showId}',
                          style: AppTypography.labelLarge.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // FIX: Date — secondary icon, textMuted text 12px
                        if (reservation.show != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 13, color: AppColors.secondary),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  reservation.show!.startsAt != null
                                      ? dateFormat.format(reservation.show!.startsAt!.toLocal())
                                      : '—',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xs),

                        // FIX: City — secondary icon, textMuted text 12px
                        if (reservation.show != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 13, color: AppColors.secondary),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                reservation.show!.city,
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 12,
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
            ),

            // FIX: Separator between top and bottom rows
            Container(height: 1, color: AppColors.border),

            // ─── Bottom row: seats badge + status + action ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // FIX: Seats badge — backgroundGrey, primary icon, border token, radius 20
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_seat, size: 13, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          s.myResSeatCount(reservation.seats),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // FIX: Expanded so badge takes remaining space, cancel button stays at end
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ReservationStatusBadge(status: reservation.status),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // FIX: Cancel button — errorLight bg, error text, radius 8, padding 6x12
                  if (statusHelper.canCancel)
                    _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : GestureDetector(
                            onTap: () => _showCancelDialog(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                s.cancel,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ),

                  // FIX: Chevron — textMuted, size 16, only when tappable
                  if (!statusHelper.canCancel)
                    Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 16),
                ],
              ),
            ),

            // FIX: Rejection banner — errorLight bg, border, radius 12, italic, RTL-aware
            if (reservation.rejectionReason != null && statusHelper.isRejected)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.errorDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        reservation.rejectionReason!,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.errorDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Expired banner
            if (statusHelper.isExpired)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_off, size: 18, color: AppColors.warningDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.myResExpiredBanner,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.warningDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Checked-in banner
            if (statusHelper.isCheckedIn)
              Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.success.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, size: 18, color: AppColors.successDark),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.myResCheckedInBanner,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 13,
                          color: AppColors.successDark,
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

  Future<void> _showCancelDialog(BuildContext context) async {
    final s = ref.read(stringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.myResCancelDialogTitle, style: AppTypography.h3),
        content: Text(s.myResCancelDialogContent, style: AppTypography.bodyMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              s.myResCancelDialogKeep,
              style: AppTypography.labelMedium.copyWith(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(
              s.myResCancelDialogConfirm,
              style: AppTypography.labelMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _cancelReservation();
    }
  }

  Future<void> _cancelReservation() async {
    if (_isCancelling) return;

    setState(() => _isCancelling = true);
    final s = ref.read(stringsProvider);

    try {
      await ref.read(myReservationsProvider.notifier).cancelReservation(
            widget.reservation.id,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.myResCancelSuccess, style: AppTypography.bodyMedium),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      String message;
      if (e.statusCode == 403) {
        message = s.myResCancelErrorForbidden;
      } else if (e.statusCode == 409) {
        message = s.myResCancelErrorConflict;
      } else {
        message = e.message;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: AppTypography.bodyMedium),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(s.myResCancelErrorGeneric, style: AppTypography.bodyMedium),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }
}

/// Show thumbnail with image or placeholder
class _ShowThumbnail extends StatelessWidget {
  final String? imageUrl;

  const _ShowThumbnail({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    // FIX: Image — 70×70, radius 12
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 70,
        height: 70,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SkeletonLoader(
                  width: 70,
                  height: 70,
                  borderRadius: 12,
                ),
                errorWidget: (context, url, error) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.backgroundGrey,
      child: Icon(Icons.tv, color: AppColors.textMuted, size: 28),
    );
  }
}

/// Skeleton loading state for reservations
class _ReservationsSkeleton extends StatelessWidget {
  const _ReservationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: _ReservationCardSkeleton(),
      ),
    );
  }
}

class _ReservationCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLoader(
                  width: 64,
                  height: 64,
                  borderRadius: AppSpacing.radiusMd,
                ),
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
          Container(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                SkeletonLoader.text(width: 70, height: 24),
                const SizedBox(width: AppSpacing.sm),
                SkeletonLoader.text(width: 90, height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
