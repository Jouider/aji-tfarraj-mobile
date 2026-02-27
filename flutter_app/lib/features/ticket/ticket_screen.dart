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
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
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

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Mes billets', style: AppTypography.h3),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
      ),
      body: ticketsAsync.when(
        loading: () => const _TicketLoadingView(),
        error: (error, stack) => ErrorState(
          message: error.toString(),
          retryText: 'Réessayer',
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
              isRefreshing: ticketsState.isRefreshing,
              onRefresh: () => ref.read(myTicketsProvider.notifier).refresh(),
            );
          }

          return _TicketsContentView(
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
  const _TicketLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: AppSpacing.lg),
          Text(
            'Chargement de vos billets...',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Widget displayed when no approved tickets are available
class _TicketLockedView extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _TicketLockedView({
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
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
                'En attente de confirmation',
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                'Vos billets seront disponibles ici une fois vos réservations approuvées par notre équipe.',
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
                  text: 'Afficher mes billets',
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
                  text: 'Voir mes réservations',
                  icon: Icons.list_alt_outlined,
                  onPressed: () => context.go(Routes.myReservations),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Rules reminder
              const _RulesReminderCard(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget displayed when tickets are available (single or multiple)
class _TicketsContentView extends StatelessWidget {
  final TicketsState ticketsState;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onRefresh;

  const _TicketsContentView({
    required this.ticketsState,
    required this.pageController,
    required this.onPageChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              // Offline banner
              if (ticketsState.isOffline) const _OfflineBanner(),

              // Refresh button
              _RefreshButton(
                isRefreshing: ticketsState.isRefreshing,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: AppSpacing.md),

              // Ticket count badge
              _TicketCountBadge(
                count: ticketsState.ticketCount,
                currentIndex: ticketsState.currentPage,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Tickets swiper or single ticket
              if (ticketsState.hasSingleTicket)
                _TicketCard(ticket: ticketsState.tickets.first)
              else
                _TicketSwiper(
                  tickets: ticketsState.tickets,
                  pageController: pageController,
                  currentPage: ticketsState.currentPage,
                  onPageChanged: onPageChanged,
                ),

              const SizedBox(height: AppSpacing.xl),

              // Rules reminder (shared for all tickets)
              const _RulesReminderCard(),
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
  final int count;
  final int currentIndex;

  const _TicketCountBadge({
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
          Icon(Icons.confirmation_number, size: 16, color: AppColors.success),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count == 1 
                ? '1 billet approuvé'
                : '${currentIndex + 1} / $count billets approuvés',
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
  final List<Ticket> tickets;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _TicketSwiper({
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
                child: _TicketCard(ticket: tickets[index]),
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
          'Glissez pour voir vos autres billets',
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
  const _OfflineBanner();

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
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Mode hors ligne - Dernière version des billets',
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
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _RefreshButton({
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AppButtonSecondary(
        text: 'Rafraîchir',
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
  final Ticket ticket;

  const _TicketCard({required this.ticket});

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
            color: Colors.black.withOpacity(0.08),
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
              color: isUsed ? Colors.teal : AppColors.success,
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
                  isUsed ? 'Billet utilisé' : 'Billet valide',
                  style: AppTypography.h4.copyWith(color: Colors.white),
                ),
                if (isUsed) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Entrée validée',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.9),
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
                    label: '${ticket.seats} place(s)',
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
                          color: Colors.teal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: Colors.teal,
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
                              'UTILISÉ',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.teal[700],
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
                  ticketCode: ticket.ticketCode,
                  isUsed: isUsed,
                ),
                const SizedBox(height: AppSpacing.xs),

                // Instructions
                Text(
                  isUsed
                      ? 'Ce billet a déjà été utilisé'
                      : 'Présentez ce QR code à l\'entrée',
                  style: AppTypography.labelSmall.copyWith(
                    color: isUsed ? Colors.teal[600] : AppColors.textMuted,
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
                color: Colors.teal[50],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppSpacing.radiusXl),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.teal[700]),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Check-in le ${DateFormat('dd/MM/yyyy à HH:mm').format(ticket.checkedInAt!.toLocal())}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.teal[700],
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
  final String ticketCode;
  final bool isUsed;

  const _TicketCodeRow({
    required this.ticketCode,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _copyToClipboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
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
            Icon(
              Icons.copy,
              size: 16,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: ticketCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code copié: $ticketCode',
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
  const _RulesReminderCard();

  @override
  Widget build(BuildContext context) {
    final rules = CopyFr.rules;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rappel des règles',
                style: AppTypography.h4,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          
          // Rules list
          ...rules.items.map((rule) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
