import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:aji_tfarraj/app/analytics/analytics_service.dart';
import 'package:aji_tfarraj/app/app_bar_actions.dart';
import 'package:aji_tfarraj/app/copywriting/ticket_copy.dart';
import 'package:aji_tfarraj/app/design_system/primitives/app_logo.dart';
import 'package:aji_tfarraj/app/routes.dart';
import 'package:aji_tfarraj/app/design_system/colors.dart';
import 'package:aji_tfarraj/app/design_system/shadows.dart';
import 'package:aji_tfarraj/app/design_system/spacing.dart';
import 'package:aji_tfarraj/app/design_system/typography.dart';
import 'package:aji_tfarraj/app/design_system/buttons.dart';
import 'package:aji_tfarraj/app/design_system/states.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/tickets/data/ticket_repository.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';

/// The time the screen reads. A provider so tests can move it.
final ticketClockProvider =
    Provider<DateTime Function()>((ref) => DateTime.now);

// ─── Ticket ordering helpers ──────────────────────────────────────────────────

// A ticket stays "upcoming" until the END of the recording, not its start —
// see Ticket.isUpcomingAt / Ticket.grace. The two lists below are exact
// complements, so a ticket can never fall out of both and vanish.

// Ticket ordering — sort upcoming by show date ascending (nearest first)
List<Ticket> _upcomingTickets(List<Ticket> tickets, DateTime now) {
  return tickets.where((t) => t.isUpcomingAt(now)).toList()
    ..sort((a, b) {
      final aDate = a.show?.startsAt ?? DateTime(9999);
      final bDate = b.show?.startsAt ?? DateTime(9999);
      return aDate.compareTo(bDate);
    });
}

// Past tickets — separated into their own section, not hidden.
List<Ticket> _pastTickets(List<Ticket> tickets, DateTime now) {
  return tickets.where((t) => !t.isUpcomingAt(now)).toList()
    // Null-safe: a show can have ends_at without starts_at, so never bang.
    ..sort((a, b) {
      final aDate = a.show?.startsAt ?? a.validUntil ?? DateTime(1970);
      final bDate = b.show?.startsAt ?? b.validUntil ?? DateTime(1970);
      return bDate.compareTo(aDate);
    });
}

String _two(int n) => n.toString().padLeft(2, '0');

/// `2 j 04 h 12 min` while more than a day away, a running clock after that.
String _countdown(TicketScreenCopy copy, Duration left) {
  final minutes = left.inMinutes % 60;
  if (left.inDays > 0) {
    return copy.countdownDays(
        left.inDays, _two(left.inHours % 24), _two(minutes));
  }
  return '${_two(left.inHours)}:${_two(minutes)}:${_two(left.inSeconds % 60)}';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

/// The ticket tab. It keeps a clock running while it is on screen, so a ticket
/// counts down, changes state on its own at the start of the recording, and
/// turns green by itself when the door scans it.
class TicketScreen extends ConsumerStatefulWidget {
  const TicketScreen({super.key});

  @override
  ConsumerState<TicketScreen> createState() => _TicketScreenState();
}

class _TicketScreenState extends ConsumerState<TicketScreen>
    with WidgetsBindingObserver {
  /// How often to ask whether the door has scanned a ticket, in clock ticks.
  /// Only for tickets someone could be scanning about now, one request each.
  static const int _askDoorEveryTicks = 20;

  /// Coming back to the tab after this long reloads the tickets: one may have
  /// been approved in the meantime.
  static const Duration _staleAfter = Duration(minutes: 2);

  late final PageController _pageController;
  late final ValueNotifier<DateTime> _clock;
  Timer? _ticker;
  int _ticks = 0;
  int? _upcomingCount;
  bool _foreground = true;
  bool? _onScreen;
  late DateTime _lastRefresh;
  bool _ticketEventFired = false;
  bool _checkinEventFired = false;

  DateTime _now() => ref.read(ticketClockProvider)();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController =
        PageController(viewportFraction: _TicketSwiper.viewportFraction);
    _clock = ValueNotifier(_now());
    _lastRefresh = _now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A hidden tab of the shell has its tickers off: that is how it knows.
    final visible = TickerMode.of(context);
    if (visible == _onScreen) return;
    final cameBack = _onScreen == false && visible;
    _onScreen = visible;
    _restartClock();
    if (cameBack) _catchUpAfterFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    _restartClock();
    if (foreground) _catchUpAfterFrame();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _clock.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _restartClock() {
    _ticker?.cancel();
    _ticker = null;
    if (_onScreen != true || !_foreground) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    // Called during build too: move the hands after the frame, not in it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tick();
    });
  }

  void _tick() {
    final now = _now();
    _clock.value = now;

    final tickets = ref.read(myTicketsProvider).valueOrNull?.tickets;
    if (tickets == null) return;

    // A recording just ended: its ticket moves to the past section.
    final upcoming = tickets.where((t) => t.isUpcomingAt(now)).length;
    if (_upcomingCount != null && upcoming != _upcomingCount) setState(() {});

    if (++_ticks % _askDoorEveryTicks == 0) _askDoor(tickets, now);
  }

  void _askDoor(List<Ticket> tickets, DateTime now) {
    final notifier = ref.read(myTicketsProvider.notifier);
    for (final ticket in tickets.where((t) => t.awaitsCheckInAt(now)).take(3)) {
      notifier.syncCheckIn(ticket);
    }
  }

  void _catchUpAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = _now();
      final state = ref.read(myTicketsProvider).valueOrNull;
      if (state == null) return;
      if (now.difference(_lastRefresh) >= _staleAfter) {
        _refresh();
      } else {
        _askDoor(state.tickets, now);
      }
    });
  }

  Future<void> _refresh() async {
    _lastRefresh = _now();
    await ref.read(myTicketsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(myTicketsProvider);
    final s = ref.watch(stringsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: AppBarBrandTitle(s.ticketTitle),
        actions: const [AppBarActions()],
        centerTitle: false,
        titleSpacing: AppSpacing.lg,
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
          onRetry: _refresh,
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
            return _TicketEmptyView(
              s: s,
              isRefreshing: ticketsState.isRefreshing,
              onRefresh: _refresh,
            );
          }

          _upcomingCount = ticketsState.tickets
              .where((t) => t.isUpcomingAt(_clock.value))
              .length;

          return _TicketsContentView(
            s: s,
            ticketsState: ticketsState,
            clock: _clock,
            pageController: _pageController,
            onPageChanged: (page) {
              ref.read(myTicketsProvider.notifier).setCurrentPage(page);
            },
            onRefresh: _refresh,
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
          CircularProgressIndicator(color: AppColors.accentInk),
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

// ─── Empty View ───────────────────────────────────────────────────────────────

/// No ticket yet. Either a reservation is on its way, and we say where it
/// stands, or there is none, and the only useful thing is to go and make one.
class _TicketEmptyView extends ConsumerWidget {
  final AppStrings s;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;

  const _TicketEmptyView({
    required this.s,
    required this.isRefreshing,
    required this.onRefresh,
  });

  static const _onItsWay = {'pending_review', 'contacting', 'approved'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final copy = s.ticketScreen;
    final isAr = ref.watch(isRtlProvider);
    final now = ref.watch(ticketClockProvider)();
    // A recording long gone is no longer on its way, whatever its status says.
    final waiting = ref
        .watch(myReservationsProvider)
        .valueOrNull
        ?.where((r) => _onItsWay.contains(r.status))
        .where((r) {
      final start = r.show?.startsAt;
      return start == null || start.add(Ticket.grace).isAfter(now);
    }).firstOrNull;

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accentInk,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.lg + AppSpacing.navBarClearance(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (waiting != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.cardDarkElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      copy.pendingTitle(
                          waiting.show?.localizedTitle(isAr) ?? ''),
                      style: AppTypography.h4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _PendingSteps(
                      labels: copy.pendingSteps,
                      reached: waiting.status == 'approved' ? 3 : 2,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      copy.pendingBody,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButtonSecondary(
                text: s.ticketViewReservations,
                icon: Icons.list_alt_outlined,
                onPressed: () => context.go(Routes.myReservations),
              ),
              TextButton.icon(
                onPressed: isRefreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(copy.refresh),
              ),
            ] else ...[
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.confirmation_number_outlined,
                      size: 44, color: AppColors.accentInk),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(copy.emptyTitle,
                  style: AppTypography.h2, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(
                copy.emptyBody,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: copy.browseShows,
                icon: Icons.movie_outlined,
                onPressed: () => context.go(Routes.home),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButtonSecondary(
                text: s.ticketViewReservations,
                icon: Icons.list_alt_outlined,
                onPressed: () => context.go(Routes.myReservations),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            _RulesReminderCard(s: s),
          ],
        ),
      ),
    );
  }
}

/// Where a reservation stands on its way to becoming a ticket.
class _PendingSteps extends StatelessWidget {
  final List<String> labels;
  final int reached;

  const _PendingSteps({required this.labels, required this.reached});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 1; i <= labels.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= reached
                        ? AppColors.primaryAction
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  labels[i - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: i <= reached
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight:
                        i == reached ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          if (i < labels.length) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

// ─── Content View ─────────────────────────────────────────────────────────────

class _TicketsContentView extends StatelessWidget {
  final AppStrings s;
  final TicketsState ticketsState;
  final ValueNotifier<DateTime> clock;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;
  final Future<void> Function() onRefresh;

  const _TicketsContentView({
    required this.s,
    required this.ticketsState,
    required this.clock,
    required this.pageController,
    required this.onPageChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = clock.value;
    final upcoming = _upcomingTickets(ticketsState.tickets, now);
    final past = _pastTickets(ticketsState.tickets, now);
    const gutter = EdgeInsets.symmetric(horizontal: AppSpacing.lg);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.accentInk,
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          top: AppSpacing.lg,
          bottom: AppSpacing.lg + AppSpacing.navBarClearance(context),
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            if (ticketsState.isOffline)
              Padding(padding: gutter, child: _OfflineBanner(s: s)),
            if (upcoming.isEmpty)
              Padding(padding: gutter, child: _NoUpcomingCard(s: s))
            else if (upcoming.length == 1)
              Padding(
                padding: gutter,
                child: _TicketCard(
                  s: s,
                  ticket: upcoming.first,
                  clock: clock,
                ),
              )
            else
              // Full width: the next ticket peeks in from the edge, which says
              // "swipe" better than a line of text would.
              _TicketSwiper(
                s: s,
                tickets: upcoming,
                clock: clock,
                pageController: pageController,
                currentPage: ticketsState.currentPage,
                onPageChanged: onPageChanged,
              ),
            const SizedBox(height: AppSpacing.xl),
            if (past.isNotEmpty)
              Padding(
                padding: gutter,
                child: _PastTicketsSection(s: s, tickets: past, now: now),
              ),
            Padding(padding: gutter, child: _RulesReminderCard(s: s)),
          ],
        ),
      ),
    );
  }
}

/// Every ticket is behind us: a place to go next, not a dead end.
class _NoUpcomingCard extends StatelessWidget {
  final AppStrings s;

  const _NoUpcomingCard({required this.s});

  @override
  Widget build(BuildContext context) {
    final copy = s.ticketScreen;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.cardDarkElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(copy.noUpcomingTitle, style: AppTypography.h4),
          const SizedBox(height: AppSpacing.xs),
          Text(
            copy.noUpcomingBody,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: copy.browseShows,
            icon: Icons.movie_outlined,
            onPressed: () => context.go(Routes.home),
          ),
        ],
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
  /// Leaves the edge of the next ticket visible.
  static const double viewportFraction = 0.92;

  final AppStrings s;
  final List<Ticket> tickets;
  final ValueNotifier<DateTime> clock;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const _TicketSwiper({
    required this.s,
    required this.tickets,
    required this.clock,
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
  static const double _initialHeight = 960;

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
                    // Room below for the shadow: the page clips at its edge.
                    padding: const EdgeInsets.fromLTRB(AppSpacing.xs,
                        AppSpacing.sm, AppSpacing.xs, AppSpacing.xl),
                    child: _TicketCard(
                      s: widget.s,
                      ticket: widget.tickets[index],
                      clock: widget.clock,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _PageIndicator(count: widget.tickets.length, currentPage: _current),
        const SizedBox(height: AppSpacing.xs),
        Text(
          widget.s.ticketScreen.page(_current + 1, widget.tickets.length),
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ─── Measure Size helper ──────────────────────────────────────────────────────

typedef _OnSizeChange = void Function(Size size);

/// Reports its child's laid-out size via [onChange]. Used to size the ticket
/// PageView to the current card, and to place the ticket's tear line.
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

/// The outline of a paper ticket, with a real bite taken out of each side at
/// the tear line. One path for the clip, the border and the shadow, so the page
/// shows through the notches in both themes.
Path _ticketPath(Size size, double? tearY) {
  const radius = 20.0;
  const notch = 11.0;
  final outline = Path()
    ..addRRect(RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(radius),
    ));
  if (tearY == null) return outline;

  final bites = Path()
    ..addOval(Rect.fromCircle(center: Offset(0, tearY), radius: notch))
    ..addOval(
        Rect.fromCircle(center: Offset(size.width, tearY), radius: notch));
  return Path.combine(PathOperation.difference, outline, bites);
}

class _TicketClipper extends CustomClipper<Path> {
  final double? tearY;

  const _TicketClipper(this.tearY);

  @override
  Path getClip(Size size) => _ticketPath(size, tearY);

  @override
  bool shouldReclip(_TicketClipper oldClipper) => oldClipper.tearY != tearY;
}

class _TicketShadowPainter extends CustomPainter {
  final double? tearY;

  const _TicketShadowPainter(this.tearY);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      _ticketPath(size, tearY),
      AppColors.primary.withValues(alpha: 0.35),
      8,
      false,
    );
  }

  @override
  bool shouldRepaint(_TicketShadowPainter oldDelegate) =>
      oldDelegate.tearY != tearY;
}

class _TicketBorderPainter extends CustomPainter {
  final double? tearY;
  final Color color;

  const _TicketBorderPainter(this.tearY, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      _ticketPath(size, tearY),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_TicketBorderPainter oldDelegate) =>
      oldDelegate.tearY != tearY || oldDelegate.color != color;
}

class _TicketCard extends ConsumerStatefulWidget {
  final AppStrings s;
  final Ticket ticket;
  final ValueNotifier<DateTime> clock;

  const _TicketCard({
    required this.s,
    required this.ticket,
    required this.clock,
  });

  @override
  ConsumerState<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends ConsumerState<_TicketCard> {
  /// Half the height of [_TearLine]: the notches sit on the dashes.
  static const double _tearHalf = 12;

  late TicketPhase _phase;
  double? _tearY;

  @override
  void initState() {
    super.initState();
    _phase = widget.ticket.phaseAt(widget.clock.value);
    widget.clock.addListener(_onTick);
  }

  @override
  void didUpdateWidget(covariant _TicketCard old) {
    super.didUpdateWidget(old);
    if (old.clock != widget.clock) {
      old.clock.removeListener(_onTick);
      widget.clock.addListener(_onTick);
    }
    _phase = widget.ticket.phaseAt(widget.clock.value);
    // The door just scanned it, with the phone in the person's hand.
    if (!old.ticket.isCheckedIn && widget.ticket.isCheckedIn) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    widget.clock.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    final phase = widget.ticket.phaseAt(widget.clock.value);
    if (phase != _phase) setState(() => _phase = phase);
  }

  void _onTopMeasured(Size size) {
    final y = size.height + _tearHalf;
    if (_tearY == y) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tearY = y);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final copy = s.ticketScreen;
    final ticket = widget.ticket;
    final show = ticket.show;
    final isAr = ref.watch(isRtlProvider);
    final user = ref.watch(loginAuthStateProvider).user;

    return CustomPaint(
      painter: _TicketShadowPainter(_tearY),
      foregroundPainter: _TicketBorderPainter(_tearY, AppColors.border),
      child: ClipPath(
        clipper: _TicketClipper(_tearY),
        child: ColoredBox(
          color: AppColors.cardDarkElevated,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MeasureSize(
                onChange: _onTopMeasured,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (show != null) _Poster(show: show, isAr: isAr),
                    _PhaseBand(
                      copy: copy,
                      ticket: ticket,
                      phase: _phase,
                      clock: widget.clock,
                    ),
                    if (show != null)
                      _Facts(copy: copy, ticket: ticket, isAr: isAr),
                  ],
                ),
              ),
              const _TearLine(height: _tearHalf * 2),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // QR first: at the door it has to be on screen without
                    // scrolling, above the floating tab bar. A scanned QR has
                    // done its job: the check replaces it, and it is that swap
                    // you see at the door when it goes through.
                    AnimatedSwitcher(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 450),
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      ),
                      child: ticket.isCheckedIn
                          ? const _EntryConfirmed(key: ValueKey('confirmed'))
                          : _QrPanel(
                              key: const ValueKey('qr'),
                              copy: copy,
                              ticket: ticket,
                              onTap: () => _openFullscreenQr(context, ticket),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TicketHolder(
                      s: s,
                      name: user?.displayName ?? '',
                      avatarUrl: user?.avatarUrl,
                      isUsed: ticket.isCheckedIn,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _TicketCodeRow(
                      s: s,
                      ticketCode: ticket.ticketCode,
                      isUsed: ticket.isCheckedIn,
                    ),
                    TextButton(
                      onPressed: () => context.push(
                        Routes.reservationDetail('${ticket.reservationId}'),
                      ),
                      child: Text(copy.seeReservation),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Poster ───────────────────────────────────────────────────────────────────

/// The show's own image: you recognise your ticket before reading a word.
class _Poster extends StatelessWidget {
  final Show show;
  final bool isAr;

  const _Poster({required this.show, required this.isAr});

  @override
  Widget build(BuildContext context) {
    final channel = show.localizedChannel(isAr);
    const fallback = DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.hotGradient),
    );

    return SizedBox(
      height: 124,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (show.imageUrl != null && show.imageUrl!.isNotEmpty)
            CachedNetworkImage(
              imageUrl: show.imageUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => fallback,
              errorWidget: (_, __, ___) => fallback,
            )
          else
            fallback,
          // White text has to hold on any photo, in both themes.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.25, 1],
                colors: [
                  Colors.black.withValues(alpha: 0),
                  Colors.black.withValues(alpha: 0.78),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            start: 20,
            end: 20,
            bottom: 14,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (channel != null && channel.isNotEmpty)
                  Text(
                    channel,
                    style: AppTypography.labelSmall
                        .copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                Text(
                  show.localizedTitle(isAr),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3
                      .copyWith(color: Colors.white, height: 1.15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Phase Band ───────────────────────────────────────────────────────────────

/// The one thing that moves on the ticket: it counts down, then lights up like
/// a studio's on-air sign when the recording starts, then turns green at the
/// door.
class _PhaseBand extends StatelessWidget {
  final TicketScreenCopy copy;
  final Ticket ticket;
  final TicketPhase phase;
  final ValueNotifier<DateTime> clock;

  const _PhaseBand({
    required this.copy,
    required this.ticket,
    required this.phase,
    required this.clock,
  });

  @override
  Widget build(BuildContext context) {
    final style = _BandStyle.of(phase, hasDate: ticket.show?.startsAt != null);
    final ink = style.ink;
    final big = AppTypography.h3.copyWith(
      color: ink,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final small = AppTypography.bodySmall.copyWith(color: ink);

    final List<Widget> lines = switch (style.kind) {
      _BandKind.countdown => [
          Text(
            phase == TicketPhase.today ? copy.startsTodayIn : copy.startsIn,
            style: small,
          ),
          ValueListenableBuilder<DateTime>(
            valueListenable: clock,
            builder: (_, now, __) {
              final left = ticket.untilStart(now);
              return Text(
                left == null ? copy.liveTitle : _countdown(copy, left),
                style: big,
              );
            },
          ),
        ],
      _BandKind.live => [
          Text(copy.liveTitle, style: big),
          Text(copy.liveHint, style: small),
        ],
      _BandKind.confirmed => [
          Text(copy.checkedInTitle, style: big),
          if (ticket.checkedInAt != null)
            Text(
              copy.checkedInHint(
                  DateFormat('HH:mm').format(ticket.checkedInAt!.toLocal())),
              style: small,
            ),
        ],
      _BandKind.valid => [
          Text(copy.validTitle, style: big),
          Text(copy.validHint, style: small),
        ],
      _BandKind.missed => [Text(copy.missed, style: big)],
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: style.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (style.kind == _BandKind.live)
            _OnAirLamp(color: ink)
          else
            Icon(style.icon, size: 24, color: ink),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: lines,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BandKind { countdown, live, confirmed, valid, missed }

class _BandStyle {
  final _BandKind kind;
  final Color background;
  final Color ink;
  final IconData icon;

  const _BandStyle(this.kind, this.background, this.ink, this.icon);

  static _BandStyle of(TicketPhase phase, {required bool hasDate}) {
    return switch (phase) {
      TicketPhase.upcoming when !hasDate => _BandStyle(
          _BandKind.valid,
          AppColors.backgroundGrey,
          AppColors.textPrimary,
          Icons.confirmation_number_outlined,
        ),
      TicketPhase.upcoming => _BandStyle(
          _BandKind.countdown,
          AppColors.backgroundGrey,
          AppColors.textPrimary,
          Icons.hourglass_top_rounded,
        ),
      TicketPhase.today => const _BandStyle(
          _BandKind.countdown,
          AppColors.secondary,
          AppColors.onSecondary,
          Icons.today_rounded,
        ),
      TicketPhase.live => const _BandStyle(
          _BandKind.live,
          AppColors.primaryAction,
          Colors.white,
          Icons.fiber_manual_record,
        ),
      TicketPhase.checkedIn || TicketPhase.attended => _BandStyle(
          _BandKind.confirmed,
          AppColors.successLight,
          AppColors.successDark,
          Icons.check_circle,
        ),
      TicketPhase.missed => _BandStyle(
          _BandKind.missed,
          AppColors.backgroundGrey,
          AppColors.textMuted,
          Icons.event_busy_outlined,
        ),
    };
  }
}

/// A slow pulse, like the lamp above a studio door. Still when the phone asks
/// for reduced motion.
class _OnAirLamp extends StatefulWidget {
  final Color color;

  const _OnAirLamp({required this.color});

  @override
  State<_OnAirLamp> createState() => _OnAirLampState();
}

class _OnAirLampState extends State<_OnAirLamp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Center(
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
          child: Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: widget.color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

// ─── Facts ────────────────────────────────────────────────────────────────────

class _Facts extends StatelessWidget {
  final TicketScreenCopy copy;
  final Ticket ticket;
  final bool isAr;

  const _Facts({required this.copy, required this.ticket, required this.isAr});

  Future<void> _openDirections(String place) async {
    final uri = Uri.https(
        'www.google.com', '/maps/search/', {'api': '1', 'query': place});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final show = ticket.show!;
    final start = show.startsAt?.toLocal();
    final localeName = isAr ? 'ar' : 'fr_FR';
    final date = start != null
        ? DateFormat('EEEE d MMMM', localeName).format(start)
        : '—';
    final time = start != null ? DateFormat('HH:mm').format(start) : '—';
    final place = {show.studio, show.city}
        .whereType<String>()
        .where((p) => p.trim().isNotEmpty)
        .join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 5, child: _Fact(copy.factDate, date)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(flex: 2, child: _Fact(copy.factTime, time)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    flex: 2, child: _Fact(copy.factSeats, '${ticket.seats}')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 16, color: AppColors.accentInk),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  place.isEmpty ? '—' : place,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              if (place.isNotEmpty)
                TextButton(
                  onPressed: () => _openDirections(place),
                  child: Text(copy.directions),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

// ─── Tear Line ────────────────────────────────────────────────────────────────

/// Where the ticket would be torn at the door: everything above is about the
/// show, everything below is what gets you in.
class _TearLine extends StatelessWidget {
  final double height;

  const _TearLine({required this.height});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(painter: _DashesPainter(AppColors.border)),
    );
  }
}

class _DashesPainter extends CustomPainter {
  final Color color;

  const _DashesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 18.0;
    const dash = 6.0;
    const gap = 5.0;
    final y = size.height / 2;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    for (var x = margin; x < size.width - margin; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset(x + dash, y), paint);
    }
  }

  @override
  bool shouldRepaint(_DashesPainter oldDelegate) => oldDelegate.color != color;
}

// ─── Ticket Holder (identity) ────────────────────────────────────────────────

/// Live identity photo + name, so staff can visually confirm the ticket belongs
/// to the person presenting it.
class _TicketHolder extends StatelessWidget {
  final AppStrings s;
  final String name;
  final String? avatarUrl;
  final bool isUsed;

  const _TicketHolder({
    required this.s,
    required this.name,
    required this.avatarUrl,
    required this.isUsed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HolderAvatar(
            name: name, avatarUrl: avatarUrl, isUsed: isUsed, size: 56),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isNotEmpty ? name : s.ticketHolderLabel,
                style: AppTypography.h4.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined,
                      size: 13, color: AppColors.accentInk),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      s.ticketHolderLabel,
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HolderAvatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isUsed;
  final double size;

  const _HolderAvatar({
    required this.name,
    required this.avatarUrl,
    required this.isUsed,
    required this.size,
  });

  Widget _placeholder(String initial) {
    return Container(
      color: AppColors.backgroundGrey,
      alignment: Alignment.center,
      child: Text(initial,
          style: AppTypography.h3.copyWith(color: AppColors.textMuted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final ringColor = isUsed ? AppColors.successDark : AppColors.secondary;
    final url = avatarUrl;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(shape: BoxShape.circle, color: ringColor),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                // Cap only width — capping both distorts non-square photos.
                cacheWidth: 240,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : _placeholder(initial),
                errorBuilder: (_, __, ___) => _placeholder(initial),
              )
            : _placeholder(initial),
      ),
    );
  }
}

// ─── QR ───────────────────────────────────────────────────────────────────────

/// A QR the door camera reads on the first try, however dark the theme: always
/// black on white, and a tap away from filling the screen.
class _QrPanel extends StatelessWidget {
  final TicketScreenCopy copy;
  final Ticket ticket;
  final VoidCallback onTap;

  const _QrPanel({
    super.key,
    required this.copy,
    required this.ticket,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth * 0.8).clamp(170.0, 240.0);
        return Column(
          children: [
            Semantics(
              button: true,
              label: copy.qrSemantics,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: ticket.qrToken,
                    version: QrVersions.auto,
                    size: size,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.zoom_out_map, size: 14, color: AppColors.accentInk),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    copy.tapToEnlarge,
                    textAlign: TextAlign.center,
                    style: AppTypography.labelSmall
                        .copyWith(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Takes the QR's place once the door has scanned it.
class _EntryConfirmed extends StatelessWidget {
  const _EntryConfirmed({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check_rounded,
          size: 60, color: AppColors.successDark),
    );
  }
}

/// Above the shell's tab bar and its route, but not opaque: the screen below
/// keeps its clock, so a scan at the door still comes through while this is up.
void _openFullscreenQr(BuildContext context, Ticket ticket) {
  Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 150),
      pageBuilder: (_, __, ___) => _FullscreenQr(ticket: ticket),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}

/// The QR, as big as the phone allows, on white. The screen stays on while it
/// is up; it closes by itself once the door has scanned it.
class _FullscreenQr extends ConsumerStatefulWidget {
  final Ticket ticket;

  const _FullscreenQr({required this.ticket});

  @override
  ConsumerState<_FullscreenQr> createState() => _FullscreenQrState();
}

class _FullscreenQrState extends ConsumerState<_FullscreenQr> {
  static const Color _ink = Color(0xFF111111);
  static const Duration _closeAfterScan = Duration(milliseconds: 1600);

  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _keepScreenOn(true);
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _keepScreenOn(false);
    super.dispose();
  }

  /// A plugin failure must never stand between someone and their QR.
  void _keepScreenOn(bool on) {
    WakelockPlus.toggle(enable: on).catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final copy = s.ticketScreen;
    final isAr = ref.watch(isRtlProvider);
    final user = ref.watch(loginAuthStateProvider).user;
    final ticket = ref
            .watch(myTicketsProvider)
            .valueOrNull
            ?.tickets
            .where((t) => t.id == widget.ticket.id)
            .firstOrNull ??
        widget.ticket;

    if (ticket.isCheckedIn && _closeTimer == null) {
      _closeTimer = Timer(_closeAfterScan, () {
        if (mounted) Navigator.of(context).pop();
      });
    }

    final media = MediaQuery.sizeOf(context);
    final qrSize = (media.width - 48).clamp(200.0, media.height * 0.55);
    final title = ticket.show?.localizedTitle(isAr);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: IconButton(
                tooltip: copy.close,
                icon: const Icon(Icons.close, color: _ink),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3.copyWith(color: _ink),
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      ticket.isCheckedIn
                          ? SizedBox(
                              width: qrSize,
                              height: qrSize,
                              child: const Center(
                                child: Icon(Icons.check_circle_rounded,
                                    size: 120, color: AppColors.successDark),
                              ),
                            )
                          : QrImageView(
                              data: ticket.qrToken,
                              version: QrVersions.auto,
                              size: qrSize,
                              padding: EdgeInsets.zero,
                              backgroundColor: Colors.white,
                            ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _HolderAvatar(
                            name: user?.displayName ?? '',
                            avatarUrl: user?.avatarUrl,
                            isUsed: ticket.isCheckedIn,
                            size: 44,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Flexible(
                            child: Text(
                              user?.displayName ?? s.ticketHolderLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.h4.copyWith(color: _ink),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ticket.ticketCode,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ticket.isCheckedIn
                            ? copy.checkedInTitle
                            : s.ticketQrHintValid,
                        textAlign: TextAlign.center,
                        style: AppTypography.bodySmall.copyWith(color: _ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ticket Code Row ──────────────────────────────────────────────────────────

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
            Flexible(
              child: Text(
                ticketCode,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isUsed ? AppColors.textMuted : AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.copy, size: 18, color: AppColors.accentInk),
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
        backgroundColor: AppColors.primaryAction,
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

/// What already happened, kept short: the latest three, the rest on request.
class _PastTicketsSection extends StatefulWidget {
  final AppStrings s;
  final List<Ticket> tickets;
  final DateTime now;

  const _PastTicketsSection({
    required this.s,
    required this.tickets,
    required this.now,
  });

  @override
  State<_PastTicketsSection> createState() => _PastTicketsSectionState();
}

class _PastTicketsSectionState extends State<_PastTicketsSection> {
  static const int _collapsedCount = 3;

  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final copy = widget.s.ticketScreen;
    final tickets = widget.tickets;
    final canFold = tickets.length > _collapsedCount;
    final shown =
        _expanded || !canFold ? tickets : tickets.take(_collapsedCount);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(copy.pastTitle, style: AppTypography.h4),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${tickets.length}',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final ticket in shown)
            _PastTicketRow(copy: copy, ticket: ticket, now: widget.now),
          if (canFold)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded
                    ? copy.pastSeeLess
                    : copy.pastSeeAll(tickets.length)),
              ),
            ),
        ],
      ),
    );
  }
}

/// One past recording. Says plainly whether you were there: a QR that was never
/// scanned is not "used".
class _PastTicketRow extends ConsumerWidget {
  final TicketScreenCopy copy;
  final Ticket ticket;
  final DateTime now;

  const _PastTicketRow({
    required this.copy,
    required this.ticket,
    required this.now,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(isRtlProvider);
    final show = ticket.show;
    final start = show?.startsAt?.toLocal();
    final attended = ticket.phaseAt(now) == TicketPhase.attended;
    final date = start != null
        ? DateFormat('d MMM yyyy', isAr ? 'ar' : 'fr_FR').format(start)
        : '—';

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () =>
          context.push(Routes.reservationDetail('${ticket.reservationId}')),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            _ShowThumb(imageUrl: show?.imageUrl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    show?.localizedTitle(isAr) ?? ticket.ticketCode,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelLarge
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              attended ? Icons.check_circle : Icons.remove_circle_outline,
              size: 15,
              color: attended ? AppColors.successDark : AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              attended ? copy.attended : copy.missed,
              style: AppTypography.labelSmall.copyWith(
                color: attended ? AppColors.successDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShowThumb extends StatelessWidget {
  final String? imageUrl;

  const _ShowThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      color: AppColors.backgroundGrey,
      child: Icon(Icons.movie_outlined, size: 20, color: AppColors.textMuted),
    );
    final url = imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 52,
        height: 52,
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback,
                errorWidget: (_, __, ___) => fallback,
              )
            : fallback,
      ),
    );
  }
}

// ─── Rules Reminder Card ──────────────────────────────────────────────────────

/// Folded by default: the ticket is what you came for. One tap away when you
/// want them.
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
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.accentInk,
          collapsedIconColor: AppColors.textMuted,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading:
              Icon(Icons.info_outline, size: 20, color: AppColors.accentInk),
          title: Text(
            s.ticketRulesReminder,
            style: AppTypography.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          children: [
            for (var i = 0; i < rules.length; i++)
              Padding(
                padding: EdgeInsets.only(bottom: i < rules.length - 1 ? 14 : 0),
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
                            rules[i].title,
                            style: AppTypography.labelMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rules[i].description,
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
              ),
          ],
        ),
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
          const Icon(Icons.wifi_off, size: 18, color: AppColors.warning),
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
