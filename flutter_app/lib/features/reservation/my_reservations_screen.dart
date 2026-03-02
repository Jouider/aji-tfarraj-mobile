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
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reservationsAsync = ref.watch(myReservationsProvider);

    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.myReservationsTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
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

  Widget _buildTabBar(int pending, int approved, int past) {
    final s = ref.read(stringsProvider);
    return Container(
      color: AppColors.backgroundWhite,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTypography.labelMedium,
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
      return RefreshIndicator(
        onRefresh: onRefresh,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 250,
            child: EmptyState(
              icon: Icons.calendar_today_outlined,
              title: emptyMessage,
              description: emptySubMessage,
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
    final dateFormat = DateFormat('dd MMM yyyy à HH:mm', 'fr_FR');
    final s = ref.watch(stringsProvider);

    return AppCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.go(Routes.reservationDetail(reservation.id.toString())),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main content
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show image or placeholder
                  _ShowThumbnail(imageUrl: reservation.show?.imageUrl),
                  const SizedBox(width: AppSpacing.md),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          reservation.show?.title ?? 'Émission #${reservation.showId}',
                          style: AppTypography.h4,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSpacing.xs),

                        // Date
                        if (reservation.show != null)
                          Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  dateFormat.format(reservation.show!.startsAt.toLocal()),
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xs),

                        // City
                        if (reservation.show != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                reservation.show!.city,
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
            ),

            // Divider
            const Divider(height: 1, color: AppColors.border),

            // Footer with seats, status, and actions
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Seats badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGrey,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_seat, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          s.myResSeatCount(reservation.seats),
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Status badge
                  Flexible(
                    child: ReservationStatusBadge(status: reservation.status),
                  ),

                  const Spacer(),

                  // Cancel button (only for pending statuses)
                  if (statusHelper.canCancel)
                    _isCancelling
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.error,
                            ),
                          )
                        : TextButton(
                            onPressed: () => _showCancelDialog(context),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                            ),
                            child: Text(
                              s.cancel,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),

                  // Chevron
                  if (!statusHelper.canCancel)
                    Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),

            // Rejection reason if rejected
            if (reservation.rejectionReason != null && statusHelper.isRejected)
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.error),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        reservation.rejectionReason!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Expired status message
            if (statusHelper.isExpired)
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_off,
                        size: 16, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.myResExpiredBanner,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Checked-in status message
            if (statusHelper.isCheckedIn)
              Container(
                margin: const EdgeInsets.fromLTRB(
                    AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 16, color: AppColors.success),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        s.myResCheckedInBanner,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.success,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        width: 64,
        height: 64,
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.backgroundGrey,
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
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
