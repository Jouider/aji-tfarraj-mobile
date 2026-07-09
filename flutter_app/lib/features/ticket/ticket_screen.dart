import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/tickets/data/ticket_repository.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

// ─── Ticket ordering helpers ──────────────────────────────────────────────────

// FIX: Ticket ordering — sort upcoming by show date ascending (nearest first)
List<Ticket> _upcomingTickets(List<Ticket> tickets) {
  final now = DateTime.now();
  return tickets
      .where((t) {
        final d = t.show?.startsAt;
        return d == null || !d.isBefore(now);
      })
      .toList()
    ..sort((a, b) {
      final aDate = a.show?.startsAt ?? DateTime(9999);
      final bDate = b.show?.startsAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
}

// FIX: Past tickets — separated into their own section, not hidden
List<Ticket> _pastTickets(List<Ticket> tickets) {
  final now = DateTime.now();
  return tickets
      .where((t) {
        final d = t.show?.startsAt;
        return d != null && d.isBefore(now);
      })
      .toList()
    ..sort((a, b) => b.show!.startsAt!.compareTo(a.show!.startsAt!));
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

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
      // FIX: App bar — backgroundWhite, centered title w700 18px, no back arrow
      appBar: AppBar(
        title: Text(
          s.ticketTitle,
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
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.border),
        ),
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

            if (!_checkinEventFired) {
              final checkedIn =
                  ticketsState.tickets.where((t) => t.isCheckedIn).firstOrNull;
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

// ─── Loading View ─────────────────────────────────────────────────────────────

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

// ─── Locked View ──────────────────────────────────────────────────────────────

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
              Text(
                s.ticketPendingTitle,
                style: AppTypography.h2,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                s.ticketPendingDesc,
                style:
                    AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),
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
              SizedBox(
                width: double.infinity,
                child: AppButtonSecondary(
                  text: s.ticketViewReservations,
                  icon: Icons.list_alt_outlined,
                  onPressed: () => context.go(Routes.myReservations),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _RulesReminderCard(s: s),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Content View ─────────────────────────────────────────────────────────────

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
    // FIX: Ticket ordering — split into upcoming (sorted asc) and past
    final upcoming = _upcomingTickets(ticketsState.tickets);
    final past = _pastTickets(ticketsState.tickets);

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

              // FIX: Refresh button — outlined primary, spinning animation
              _RefreshButton(
                s: s,
                isRefreshing: ticketsState.isRefreshing,
                onRefresh: onRefresh,
              ),
              const SizedBox(height: AppSpacing.md),

              // FIX: Count badge — primary-tinted
              _TicketCountBadge(
                s: s,
                count: upcoming.isEmpty
                    ? ticketsState.ticketCount
                    : upcoming.length,
                currentIndex: ticketsState.currentPage,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Upcoming tickets
              if (upcoming.isEmpty && ticketsState.tickets.isNotEmpty)
                // All tickets are past — show one-liner
                Center(
                  child: Text(
                    'Tous vos billets sont passés',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                )
              else if (upcoming.length == 1)
                _TicketCard(s: s, ticket: upcoming.first)
              else if (upcoming.isNotEmpty)
                _TicketSwiper(
                  s: s,
                  tickets: upcoming,
                  pageController: pageController,
                  currentPage: ticketsState.currentPage,
                  onPageChanged: onPageChanged,
                ),

              const SizedBox(height: AppSpacing.xl),

              // FIX: Past tickets section — separate, not hidden
              if (past.isNotEmpty) _PastTicketsSection(s: s, tickets: past),

              // Rules reminder
              _RulesReminderCard(s: s),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Count Badge ──────────────────────────────────────────────────────────────

// FIX: Count badge — primary 10% bg, primary text/icon, primary 30% border
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            count == 1
                ? s.ticketCountSingle
                : s.ticketCountMultiple(currentIndex, count),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Refresh Button ───────────────────────────────────────────────────────────

// FIX: Refresh button — outlined primary 1.5px, spinning icon, radius 14, h48
class _RefreshButton extends StatefulWidget {
  final AppStrings s;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _RefreshButton({
    required this.s,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isRefreshing) _spinController.repeat();
  }

  @override
  void didUpdateWidget(covariant _RefreshButton old) {
    super.didUpdateWidget(old);
    if (widget.isRefreshing && !_spinController.isAnimating) {
      _spinController.repeat();
    } else if (!widget.isRefreshing && _spinController.isAnimating) {
      _spinController.stop();
      _spinController.reset();
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: widget.isRefreshing ? null : widget.onRefresh,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.transparent,
        ),
        icon: AnimatedBuilder(
          animation: _spinController,
          builder: (_, child) => Transform.rotate(
            angle: _spinController.value * 2 * math.pi,
            child: child,
          ),
          child: const Icon(Icons.refresh, size: 18, color: AppColors.primary),
        ),
        label: Text(
          widget.s.ticketRefresh,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

// ─── Ticket Swiper ────────────────────────────────────────────────────────────

// HOTFIX: content-measured height. Previously the PageView used a fixed /
// screen-proportional height (screenHeight * 0.62), which still clipped taller
// ticket cards (2-line titles, channel row, checked-in footer…) so the QR at
// the bottom was cropped and could not be scanned. The viewport now measures
// each card and sizes itself to the current one, so nothing is ever clipped.
class _TicketSwiper extends StatefulWidget {
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
  State<_TicketSwiper> createState() => _TicketSwiperState();
}

class _TicketSwiperState extends State<_TicketSwiper> {
  // Generous first-frame estimate so a card is never clipped before it is
  // measured; heights only shrink to the real card height afterwards.
  static const double _initialHeight = 760;

  late List<double> _heights;
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.currentPage.clamp(0, widget.tickets.length - 1);
    _heights = List<double>.filled(widget.tickets.length, _initialHeight);
  }

  @override
  void didUpdateWidget(covariant _TicketSwiper old) {
    super.didUpdateWidget(old);
    // Ticket set changed (refresh) — reset measurements to stay in sync.
    if (widget.tickets.length != _heights.length) {
      _heights = List<double>.filled(widget.tickets.length, _initialHeight);
      _current = _current.clamp(0, widget.tickets.length - 1);
    }
  }

  void _onMeasured(int index, double height) {
    if (index < 0 || index >= _heights.length) return;
    if ((_heights[index] - height).abs() < 1) return;
    // Defer to the next frame to avoid setState during layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && index < _heights.length) {
        setState(() => _heights[index] = height);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = (_current >= 0 && _current < _heights.length)
        ? _heights[_current]
        : _initialHeight;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: SizedBox(
            height: height,
            child: PageView.builder(
              controller: widget.pageController,
              itemCount: widget.tickets.length,
              onPageChanged: (i) {
                setState(() => _current = i);
                widget.onPageChanged(i);
              },
              // Each page can scroll as a safety net during height transitions
              // and reports its natural height so the viewport can match it.
              itemBuilder: (context, index) => SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: _MeasureSize(
                  onChange: (size) => _onMeasured(index, size.height),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                    child:
                        _TicketCard(s: widget.s, ticket: widget.tickets[index]),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // FIX: Pagination dots — primary pill active, border inactive, animated
        _PageIndicator(count: widget.tickets.length, currentPage: _current),
        const SizedBox(height: AppSpacing.sm),

        // FIX: Swipe hint — only when 2+ tickets, with arrow icons
        if (widget.tickets.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back_ios, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                widget.s.ticketSwipeHint,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
            ],
          ),
      ],
    );
  }
}

// ─── Measure Size helper ──────────────────────────────────────────────────────

typedef _OnSizeChange = void Function(Size size);

/// Reports its child's laid-out size via [onChange]. Used to size the ticket
/// PageView to the current card so the QR is never clipped.
class _MeasureSize extends SingleChildRenderObjectWidget {
  final _OnSizeChange onChange;

  const _MeasureSize({required this.onChange, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _MeasureSizeRenderObject(onChange);

  @override
  void updateRenderObject(
      BuildContext context, _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}

class _MeasureSizeRenderObject extends RenderProxyBox {
  _OnSizeChange onChange;
  Size? _oldSize;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();
    final newSize = child?.size ?? Size.zero;
    if (_oldSize == newSize) return;
    _oldSize = newSize;
    onChange(newSize);
  }
}

// ─── Page Indicator ───────────────────────────────────────────────────────────

// FIX: Pagination dots — primary pill 24×8 active, border 8×8 inactive, 300ms anim
class _PageIndicator extends StatelessWidget {
  final int count;
  final int currentPage;

  const _PageIndicator({required this.count, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
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

// ─── Ticket Card ──────────────────────────────────────────────────────────────

// FIX: Ticket card — cardDarkElevated, radius 20, primary 12% shadow, border token
class _TicketCard extends ConsumerWidget {
  final AppStrings s;
  final Ticket ticket;

  const _TicketCard({required this.s, required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final dateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');
    final show = ticket.show;
    final isUsed = ticket.isCheckedIn;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // FIX: Header band — primary gradient, white icon+text, radius top 20
          _TicketHeaderBand(isUsed: isUsed, s: s),

          // Show info
          if (show != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // FIX: Show title — textPrimary w700 20px centered
                  Text(
                    show.localizedTitle(isAr),
                    style: AppTypography.h4.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

                  // FIX: Info rows — secondary icons, textSecondary text 14px
                  _TicketInfoRow(
                    icon: Icons.calendar_today,
                    iconColor: AppColors.secondary,
                    label: show.startsAt != null
                        ? dateFormat.format(show.startsAt!.toLocal())
                        : '—',
                  ),
                  const SizedBox(height: 8),
                  _TicketInfoRow(
                    icon: Icons.access_time,
                    iconColor: AppColors.secondary,
                    label: show.startsAt != null
                        ? timeFormat.format(show.startsAt!.toLocal())
                        : '—',
                  ),
                  const SizedBox(height: 8),
                  _TicketInfoRow(
                    icon: Icons.location_on,
                    iconColor: AppColors.secondary,
                    label: show.studio ?? show.city,
                  ),
                  if (show.channel != null) ...[
                    const SizedBox(height: 8),
                    _TicketInfoRow(
                      icon: Icons.tv,
                      iconColor: AppColors.secondary,
                      label: show.channel!,
                    ),
                  ],
                  const SizedBox(height: 8),
                  // FIX: Seat icon — primary color
                  _TicketInfoRow(
                    icon: Icons.event_seat,
                    iconColor: AppColors.primary,
                    label: s.ticketSeats(ticket.seats),
                  ),
                ],
              ),
            ),

          // FIX: Dashed divider with notch effect
          _DashedDivider(),

          // FIX: QR section — backgroundLight container, corner accents, 160px QR
          _TicketQrSection(s: s, ticket: ticket, isUsed: isUsed),

          // Checked-in footer
          if (isUsed && ticket.checkedInAt != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle,
                      size: 14, color: AppColors.successDark),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    s.ticketCheckinAt(
                      DateFormat('dd/MM/yyyy à HH:mm')
                          .format(ticket.checkedInAt!.toLocal()),
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
    )); // closes SingleChildScrollView + Container
  }
}

// ─── Header Band ──────────────────────────────────────────────────────────────

// FIX: Header band — primary gradient top→bottom, white icon + "Billet valide" w700 18px
class _TicketHeaderBand extends StatelessWidget {
  final bool isUsed;
  final AppStrings s;

  const _TicketHeaderBand({required this.isUsed, required this.s});

  @override
  Widget build(BuildContext context) {
    final Color bandColor = isUsed ? AppColors.textMuted : AppColors.primary;
    final Color bandColorEnd =
        isUsed ? AppColors.textMuted : AppColors.primaryDark;
    final IconData bandIcon =
        isUsed ? Icons.check_circle : Icons.confirmation_number;
    final String bandLabel = isUsed ? s.ticketUsed : s.ticketValid;

    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [bandColor, bandColorEnd],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(bandIcon, size: 28, color: Colors.white),
          const SizedBox(width: 10),
          Text(
            bandLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Row ─────────────────────────────────────────────────────────────────

class _TicketInfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _TicketInfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 15, color: iconColor),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── Dashed Divider ───────────────────────────────────────────────────────────

// FIX: Dashed divider — border token color, notch circles on edges (ticket feel)
class _DashedDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Notch circle size
    const double notchR = 13.0;

    return SizedBox(
      height: notchR * 2,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Left notch circle (uses backgroundLight to "cut" into card edge)
          Positioned(
            left: -notchR,
            child: Container(
              width: notchR * 2,
              height: notchR * 2,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
          // Right notch circle
          Positioned(
            right: -notchR,
            child: Container(
              width: notchR * 2,
              height: notchR * 2,
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
            ),
          ),
          // Dashed line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: notchR + 2),
            child: Row(
              children: List.generate(
                32,
                (i) => Expanded(
                  child: Container(
                    height: 1.5,
                    color: i.isEven ? AppColors.border : Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── QR Section ───────────────────────────────────────────────────────────────

// FIX: QR section — backgroundLight container, radius 16, border, 160px QR,
//      primary corner accents, secondary copy icon, primary snackbar
class _TicketQrSection extends StatelessWidget {
  final AppStrings s;
  final Ticket ticket;
  final bool isUsed;

  const _TicketQrSection({
    required this.s,
    required this.ticket,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
      child: Column(
        children: [
          // QR container with corner accents
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // QR code (blurred if used)
                _buildQrImage(),

                // Used overlay
                if (isUsed)
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.successLight.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successDark,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.ticketUsedLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.successDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                // FIX: Primary corner accents
                ..._buildCornerAccents(),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Ticket reference + copy
          _TicketCodeRow(s: s, ticketCode: ticket.ticketCode, isUsed: isUsed),
          const SizedBox(height: AppSpacing.sm),

          // FIX: Instructions — secondary info icon, textMuted 12px
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 14, color: AppColors.secondary),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  isUsed ? s.ticketQrHintUsed : s.ticketQrHintValid,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrImage() {
    final qrWidget = Container(
      width: 160,
      height: 160,
      color: Colors.white,
      child: QrImageView(
        data: ticket.qrToken,
        version: QrVersions.auto,
        size: 160,
        backgroundColor: Colors.white,
      ),
    );

    if (isUsed) {
      // FIX: Blur QR on used tickets (sigma 2.0) to signal invalidity
      return ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: Opacity(opacity: 0.4, child: qrWidget),
      );
    }
    return qrWidget;
  }

  // FIX: L-shaped corner accents — primary 60% opacity, 2px stroke, 16px arm
  List<Widget> _buildCornerAccents() {
    const double armLength = 16.0;
    const double stroke = 2.0;
    final Color accentColor = AppColors.primary.withValues(alpha: 0.60);

    Widget corner({
      bool top = false,
      bool bottom = false,
      bool left = false,
      bool right = false,
    }) {
      return Container(
        width: armLength,
        height: armLength,
        decoration: BoxDecoration(
          border: Border(
            top: top
                ? BorderSide(color: accentColor, width: stroke)
                : BorderSide.none,
            bottom: bottom
                ? BorderSide(color: accentColor, width: stroke)
                : BorderSide.none,
            left: left
                ? BorderSide(color: accentColor, width: stroke)
                : BorderSide.none,
            right: right
                ? BorderSide(color: accentColor, width: stroke)
                : BorderSide.none,
          ),
        ),
      );
    }

    return [
      Positioned(top: 0, left: 0, child: corner(top: true, left: true)),
      Positioned(top: 0, right: 0, child: corner(top: true, right: true)),
      Positioned(bottom: 0, left: 0, child: corner(bottom: true, left: true)),
      Positioned(bottom: 0, right: 0, child: corner(bottom: true, right: true)),
    ];
  }
}

// ─── Ticket Code Row ──────────────────────────────────────────────────────────

// FIX: Code row — backgroundGrey, border, radius 10, textPrimary w700 ls1.5,
//      secondary copy icon, primary snackbar
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
    return GestureDetector(
      onTap: () => _copyToClipboard(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.backgroundGrey,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              ticketCode,
              style: TextStyle(
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isUsed ? AppColors.textMuted : AppColors.textPrimary,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.copy, size: 18, color: AppColors.secondary),
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
          s.ticketCodeCopied(ticketCode),
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        // FIX: Copy snackbar — primary background
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Past Tickets Section ─────────────────────────────────────────────────────

// FIX: Past tickets — separate "Billets passés" section, vertical list, not hidden
class _PastTicketsSection extends ConsumerWidget {
  final AppStrings s;
  final List<Ticket> tickets;

  const _PastTicketsSection({required this.s, required this.tickets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // FIX: Section divider + header
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Icon(Icons.history, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              'Billets passés',
              style: AppTypography.labelMedium.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '(${tickets.length})',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Past ticket cards (vertical list, not swipeable)
        ...tickets.map(
          (ticket) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _PastTicketCard(s: s, ticket: ticket),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

// ─── Past Ticket Card ─────────────────────────────────────────────────────────

// FIX: Past ticket card — 50% opacity, UTILISÉ diagonal watermark, muted header
class _PastTicketCard extends ConsumerWidget {
  final AppStrings s;
  final Ticket ticket;

  const _PastTicketCard({required this.s, required this.ticket});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final dateFormat = DateFormat('EEE dd MMM yyyy', 'fr_FR');
    final show = ticket.show;

    return Opacity(
      opacity: 0.50,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Card body (same structure, muted header)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.cardDarkElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Muted header
                Container(
                  height: 52,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        s.ticketUsed,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Compact info
                if (show != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                show.localizedTitle(isAr),
                                style: AppTypography.labelLarge.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 12,
                                      color: AppColors.textMuted),
                                  const SizedBox(width: 4),
                                  Text(
                                    show.startsAt != null
                                        ? dateFormat
                                            .format(show.startsAt!.toLocal())
                                        : '—',
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
                        // Compact QR preview (blurred)
                        ImageFiltered(
                          imageFilter:
                              ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: AppColors.border),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: QrImageView(
                              data: ticket.qrToken,
                              version: QrVersions.auto,
                              size: 52,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // FIX: UTILISÉ diagonal watermark — primary 35% opacity, rotated -25deg
          IgnorePointer(
            child: Transform.rotate(
              angle: -25 * math.pi / 180,
              child: Text(
                'UTILISÉ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary.withValues(alpha: 0.35),
                  letterSpacing: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Rules Reminder Card ──────────────────────────────────────────────────────

// FIX: Rules card — cardDarkElevated, border, radius 16, shadow, redesigned header
class _RulesReminderCard extends StatelessWidget {
  final AppStrings s;

  const _RulesReminderCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final rules = s.rulesItems;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A1A).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX: Rules header — secondary left border accent, primary info icon
          Row(
            children: [
              Container(
                width: 3,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.info_outline,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                s.ticketRulesReminder,
                style: AppTypography.labelLarge.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // FIX: Rules — primary bullet 8px, title w600 14px, desc textMuted 13px
          ...rules.asMap().entries.map((entry) {
            final i = entry.key;
            final rule = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                  bottom: i < rules.length - 1 ? 14 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rule.description,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Offline Banner ───────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  final AppStrings s;

  const _OfflineBanner({required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
              style:
                  AppTypography.labelSmall.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}
