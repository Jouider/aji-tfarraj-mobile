import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/design_system/components/cards/app_card.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/tickets/data/ticket_repository.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

/// Ticket Screen with states: Locked, Single Ticket, Multiple Tickets (Swiper)
class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen> {
  late PageController _pageController;
  bool _ticketEventFired = false;
  bool _checkinEventFired = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(myTicketsProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(s.ticketTitle, style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: ticketsAsync.when(
        loading: () => _TicketLoadingView(s: s),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: s.retry,
          onRetry: () => ref.read(myTicketsProvider.notifier).refresh(),
        ),
        data: (ticketsState) {
          if (!ticketsState.isEmpty) {
            final analytics = ref.read(analyticsServiceProvider);

            // ticket_generated — first time user sees a valid ticket
            if (!_ticketEventFired) {
              _ticketEventFired = true;
              final first = ticketsState.tickets.first;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                analytics.logTicketGenerated(
                  ticketCode: first.ticketCode,
                  showId: first.show?.id ?? 0,
                );
              });
            }

            // checkin_success — first time a checked-in ticket is detected
            if (!_checkinEventFired) {
              final checkedIn = ticketsState.tickets
                  .where((t) => t.isCheckedIn)
                  .firstOrNull;
              if (checkedIn != null) {
                _checkinEventFired = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  analytics.logCheckinSuccess(
                    ticketCode: checkedIn.ticketCode,
                    showId: checkedIn.show?.id ?? 0,
                  );
                });
              }
            }
          }

          if (ticketsState.isEmpty) {
            return _TicketLockedView(
              s: s,
              isRefreshing: ticketsState.isRefreshing,
              onRefresh: () => ref.read(myTicketsProvider.notifier).refresh(),
            );
          }

          return _TicketsContentView(
            s: s,
            ticketsState: ticketsState,
            pageController: _pageController,
            onPageChanged: (page) {
              ref.read(myTicketsProvider.notifier).setCurrentPage(page);
            },
            onRefresh: () => ref.read(myTicketsProvider.notifier).refresh(),
          );
        },
      ),
    );
  }
}

/// Loading view
class _TicketLoadingView extends StatelessWidget {
  final AppStrings s;

  const _TicketLoadingView({required this.s});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            s.ticketLoading,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Widget displayed when no approved tickets are available
class _TicketLockedView extends StatelessWidget {
  final AppStrings s;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _TicketLockedView({
    required this.s,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // Hourglass icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: 60,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                s.ticketPendingTitle,
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                s.ticketPendingDesc,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Refresh button
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: s.ticketShowTickets,
                  icon: Icons.refresh,
                  isLoading: isRefreshing,
                  onPressed: isRefreshing ? null : onRefresh,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // View reservations button
              SizedBox(
                width: double.infinity,
                child: AppButtonSecondary(
                  text: s.ticketViewReservations,
                  icon: Icons.list_alt_outlined,
                  onPressed: () => context.go(Routes.myReservations),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rules reminder
              _RulesReminderCard(s: s),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget displayed when tickets are available (single or multiple)
class _TicketsContentView extends StatelessWidget {
  final AppStrings s;
  final TicketsState ticketsState;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRefresh;

  const _TicketsContentView({
    required this.s,
    required this.ticketsState,
    required this.pageController,
    required this.onPageChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.secondary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Offline banner
              if (ticketsState.isOffline) _OfflineBanner(s: s),

              // Refresh button
              _RefreshButton(
                s: s,
                isRefreshing: ticketsState.isRefreshing,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: AppSpacing.md),

              // Ticket count badge
              _TicketCountBadge(
                s: s,
                count: ticketsState.ticketCount,
                currentIndex: ticketsState.currentPage,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tickets swiper or single ticket
              if (ticketsState.hasSingleTicket)
                _TicketCard(s: s, ticket: ticketsState.tickets.first)
              else
                _TicketSwiper(
                  s: s,
                  tickets: ticketsState.tickets,
                  pageController: pageController,
                  currentPage: ticketsState.currentPage,
                  onPageChanged: onPageChanged,
                ),

              const SizedBox(height: AppSpacing.xl),

              // Rules reminder (shared for all tickets)
              _RulesReminderCard(s: s),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ticket count badge showing total and current position
class _TicketCountBadge extends StatelessWidget {
  final AppStrings s;
  final int count;
  final int currentIndex;

  const _TicketCountBadge({
    required this.s,
    required this.count,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count == 1
                ? s.ticketCountSingle
                : s.ticketCountMultiple(currentIndex, count),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ticket swiper for multiple tickets
class _TicketSwiper extends StatelessWidget {
  final AppStrings s;
  final List<Ticket> tickets;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _TicketSwiper({
    required this.s,
    required this.tickets,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // PageView for tickets
        SizedBox(
          height: 580, // Fixed height for ticket cards
          child: PageView.builder(
            controller: pageController,
            itemCount: tickets.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: _TicketCard(s: s, ticket: tickets[index]),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Page indicator dots
        _PageIndicator(
          count: tickets.length,
          currentPage: currentPage,
        ),

        // Swipe hint
        const SizedBox(height: AppSpacing.sm),
        Text(
          s.ticketSwipeHint,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Page indicator dots
class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentPage;

  const _PageIndicator({
    required this.count,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

/// Offline mode banner
class _OfflineBanner extends StatelessWidget {
  final AppStrings s;

  const _OfflineBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              s.ticketOfflineBanner,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Refresh button with loading state
class _RefreshButton extends StatelessWidget {
  final AppStrings s;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _RefreshButton({
    required this.s,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButtonSecondary(
        text: s.ticketRefresh,
        icon: Icons.refresh,
        isLoading: isRefreshing,
        isSmall: true,
        onPressed: isRefreshing ? null : onRefresh,
      ),
    );
  }
}

/// Main ticket card with QR code
class _TicketCard extends StatelessWidget {
  final AppStrings s;
  final Ticket ticket;

  const _TicketCard({required this.s, required this.ticket});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final show = ticket.show;
    final isUsed = ticket.isCheckedIn;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.backgroundWhite,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isUsed ? Icons.verified : Icons.confirmation_number,
                  size: 36,
                  color: Colors.white,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isUsed ? s.ticketUsed : s.ticketValid,
                  style: AppTypography.h4.copyWith(color: Colors.white),
                ),
                if (isUsed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    s.ticketCheckedInLabel,
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Show info
          if (show != null)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  Text(
                    show.title,
                    style: AppTypography.h4,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TicketInfoRow(
                    icon: Icons.calendar_today,
                    label: dateFormat.format(show.startsAt.toLocal()),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _TicketInfoRow(
                    icon: Icons.access_time,
                    label: timeFormat.format(show.startsAt.toLocal()),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _TicketInfoRow(
                    icon: Icons.location_on,
                    label: show.studio ?? show.city,
                  ),
                  if (show.channel != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    _TicketInfoRow(
                      icon: Icons.tv,
                      label: show.channel!,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  _TicketInfoRow(
                    icon: Icons.event_seat,
                    label: s.ticketSeats(ticket.seats),
                  ),
                ],
              ),
            ),

          // Dashed divider
          _DashedDivider(),

          // QR Code section
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                // QR Code with overlay if used
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: isUsed ? 0.3 : 1.0,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: QrImageView(
                          data: ticket.qrToken,
                          version: QrVersions.auto,
                          size: 140,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    if (isUsed)
                      Container(
                        width: 172,
                        height: 172,
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              s.ticketUsedLabel,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.successDark,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Ticket code with copy button
                _TicketCodeRow(
                  s: s,
                  ticketCode: ticket.ticketCode,
                  isUsed: isUsed,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Instructions
                Text(
                  isUsed ? s.ticketQrHintUsed : s.ticketQrHintValid,
                  style: AppTypography.labelSmall.copyWith(
                    color: isUsed ? AppColors.successDark : AppColors.textMuted,
                    fontWeight: isUsed ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),

          // Checked-in timestamp
          if (isUsed && ticket.checkedInAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 14, color: AppColors.successDark),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    s.ticketCheckinAt(
                      DateFormat('dd/MM/yyyy à HH:mm').format(ticket.checkedInAt!.toLocal()),
                    ),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.successDark,
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

/// Ticket code row with copy functionality
class _TicketCodeRow extends StatelessWidget {
  final AppStrings s;
  final String ticketCode;
  final bool isUsed;

  const _TicketCodeRow({
    required this.s,
    required this.ticketCode,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundGrey,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copyToClipboard(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ticketCode,
                style: AppTypography.labelLarge.copyWith(
                  letterSpacing: 2,
                  color: isUsed ? AppColors.textMuted : AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.copy,
                size: 16,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: ticketCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          s.ticketCodeCopied(ticketCode),
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Ticket info row
class _TicketInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TicketInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Dashed divider for ticket look
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        40,
        (index) => Expanded(
          child: Container(
            height: 2,
            color: index.isEven ? AppColors.border : Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// Rules reminder card
class _RulesReminderCard extends StatelessWidget {
  final AppStrings s;

  const _RulesReminderCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final rules = s.rulesItems;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                s.ticketRulesReminder,
                style: AppTypography.h4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Rules list
          ...rules.map((rule) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
                      const SizedBox(height: 2),
                      Text(
                        rule.description,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textMuted,
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
    );
  }
}
