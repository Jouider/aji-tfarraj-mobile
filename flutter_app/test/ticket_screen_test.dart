import 'package:aji_tfarraj/app/copywriting/ticket_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/reservations/data/reservations_repository.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';
import 'package:aji_tfarraj/features/shows/domain/show.dart';
import 'package:aji_tfarraj/features/support/data/support_service.dart';
import 'package:aji_tfarraj/features/ticket/ticket_screen.dart';
import 'package:aji_tfarraj/features/tickets/data/ticket_repository.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The ticket has to say the right thing at the right moment, and above all
/// never lose the QR of someone standing at the door.

final _start = DateTime(2026, 11, 8, 20, 0);

Ticket _ticket({
  int id = 1,
  String code = 'TCK-AJI-0001',
  DateTime? start,
  DateTime? end,
  DateTime? checkedInAt,
  bool withDate = true,
  String title = 'Planet Foot',
}) {
  return Ticket(
    id: id,
    reservationId: id,
    ticketCode: code,
    qrToken: 'qr-$id',
    checkedInAt: checkedInAt,
    reservationInfo: TicketReservationInfo(
      id: id,
      showId: id,
      seats: 2,
      status: 'approved',
      show: Show(
        id: id,
        title: title,
        titleAr: 'بلانيت فوت',
        channel: '2M',
        isActive: true,
        city: 'Casablanca',
        studio: 'Studio Ain Sebaa',
        capacity: 180,
        reservedSeats: 55,
        startsAt: withDate ? (start ?? _start) : null,
        endsAt: end,
      ),
    ),
  );
}

class _FakeTickets extends MyTicketsNotifier {
  _FakeTickets(this.initial);

  final TicketsState initial;
  int asked = 0;
  DateTime? scanAt;

  @override
  Future<TicketsState> build() async => initial;

  @override
  Future<void> refresh() async {}

  @override
  Future<void> syncCheckIn(Ticket ticket) async {
    asked++;
    final at = scanAt;
    if (at == null) return;
    final current = state.valueOrNull!;
    state = AsyncData(current.copyWith(tickets: [
      for (final t in current.tickets)
        t.id == ticket.id ? t.withCheckIn(at) : t,
    ]));
  }
}

class _NoReservations extends MyReservationsNotifier {
  _NoReservations(this.list);

  final List<Reservation> list;

  @override
  Future<List<Reservation>> build() async => list;
}

/// The ticket only reads the holder's name and photo.
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Clock {
  _Clock(this.now);
  DateTime now;
  DateTime read() => now;
}

Future<_FakeTickets> _pump(
  WidgetTester tester, {
  required List<Ticket> tickets,
  required _Clock clock,
  List<Reservation> reservations = const [],
  AppLocale locale = AppLocale.fr,
  Size size = const Size(390, 844),
  double textScale = 1,
}) async {
  await initializeDateFormatting('fr_FR', null);
  await initializeDateFormatting('ar', null);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final fake = _FakeTickets(TicketsState(tickets: tickets));
  await tester.pumpWidget(ProviderScope(
    overrides: [
      myTicketsProvider.overrideWith(() => fake),
      myReservationsProvider.overrideWith(() => _NoReservations(reservations)),
      ticketClockProvider.overrideWithValue(clock.read),
      stringsProvider.overrideWithValue(AppStrings(locale)),
      isRtlProvider.overrideWithValue(locale == AppLocale.ar),
      sharedPreferencesProvider.overrideWithValue(prefs),
      supportUnreadProvider.overrideWith((ref) async => 0),
      loginAuthStateProvider.overrideWith((ref) => _FakeAuth()),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Directionality(
          textDirection:
              locale == AppLocale.ar ? TextDirection.rtl : TextDirection.ltr,
          child: const TicketScreen(),
        ),
      ),
    ),
  ));
  // Resolve the provider, then settle the measured tear line.
  await tester.pump();
  await tester.pump();
  await tester.pump();
  return fake;
}

void main() {
  const fr = TicketScreenCopyFr();

  group('where a ticket stands', () {
    test('a later day, then today, then live', () {
      final t = _ticket();
      expect(t.phaseAt(DateTime(2026, 11, 7, 23)), TicketPhase.upcoming);
      expect(t.phaseAt(DateTime(2026, 11, 8, 9)), TicketPhase.today);
      expect(t.phaseAt(_start), TicketPhase.live);
      expect(t.phaseAt(DateTime(2026, 11, 9, 2)), TicketPhase.live);
    });

    test('over without a scan is missed, not "used"', () {
      final t = _ticket();
      expect(
          t.phaseAt(_start.add(const Duration(hours: 13))), TicketPhase.missed);
    });

    test('scanned: checked in during the recording, attended after', () {
      final t = _ticket(checkedInAt: _start);
      expect(t.phaseAt(_start.add(const Duration(hours: 1))),
          TicketPhase.checkedIn);
      expect(t.phaseAt(_start.add(const Duration(hours: 13))),
          TicketPhase.attended);
    });

    test('a ticket with no date stays upcoming, never lost', () {
      expect(_ticket(withDate: false).phaseAt(_start), TicketPhase.upcoming);
    });

    test('the server is only asked when the door could be scanning', () {
      final t = _ticket();
      expect(t.awaitsCheckInAt(DateTime(2026, 11, 7)), isFalse);
      expect(t.awaitsCheckInAt(DateTime(2026, 11, 8, 15, 59)), isFalse);
      expect(t.awaitsCheckInAt(DateTime(2026, 11, 8, 16)), isTrue);
      expect(t.awaitsCheckInAt(_start), isTrue);
      expect(_ticket(checkedInAt: _start).awaitsCheckInAt(_start), isFalse);
      expect(t.awaitsCheckInAt(_start.add(const Duration(hours: 13))), isFalse);
    });
  });

  group('the ticket on screen', () {
    testWidgets('counts down in days, with the QR ready', (tester) async {
      await _pump(tester,
          tickets: [_ticket()], clock: _Clock(DateTime(2026, 11, 6, 15, 48)));

      expect(find.text(fr.startsIn), findsOneWidget);
      expect(find.text('2 j 04 h 12 min'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the clock runs on the day, and the band lights up at the start',
        (tester) async {
      final clock = _Clock(DateTime(2026, 11, 8, 19, 59, 58));
      await _pump(tester, tickets: [_ticket()], clock: clock);

      expect(find.text(fr.startsTodayIn), findsOneWidget);
      expect(find.text('00:00:02'), findsOneWidget);

      clock.now = DateTime(2026, 11, 8, 19, 59, 59);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:00:01'), findsOneWidget);

      clock.now = _start;
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text(fr.liveTitle), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget,
          reason: 'latecomers still need their QR during the recording');
    });

    testWidgets('turns green by itself when the door scans it', (tester) async {
      final clock = _Clock(_start.add(const Duration(minutes: 10)));
      final fake = await _pump(tester, tickets: [_ticket()], clock: clock);

      expect(find.byType(QrImageView), findsOneWidget);

      fake.scanAt = _start.add(const Duration(minutes: 12));
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(fake.asked, greaterThan(0));
      expect(find.text(fr.checkedInTitle), findsOneWidget);
      expect(find.text(fr.checkedInHint('20:12')), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('does not ask the door days before the recording',
        (tester) async {
      final clock = _Clock(DateTime(2026, 11, 2));
      final fake = await _pump(tester, tickets: [_ticket()], clock: clock);

      await tester.pump(const Duration(minutes: 1));
      expect(fake.asked, 0);
    });

    testWidgets('the QR opens full screen, and closes after a scan',
        (tester) async {
      final clock = _Clock(_start);
      final fake = await _pump(tester, tickets: [_ticket()], clock: clock);

      await tester.tap(find.byType(QrImageView));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(QrImageView), findsNWidgets(2));

      fake.scanAt = _start.add(const Duration(minutes: 1));
      await tester.pump(const Duration(seconds: 20));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(fr.checkedInHint('20:01')), findsOneWidget);
      expect(find.byType(QrImageView), findsNothing);
    });

    testWidgets('moves to the past section when the recording ends',
        (tester) async {
      final clock = _Clock(_start.add(const Duration(hours: 11, minutes: 59)));
      await _pump(tester, tickets: [_ticket()], clock: clock);
      expect(find.byType(QrImageView), findsOneWidget);

      clock.now = _start.add(const Duration(hours: 12, minutes: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(find.byType(QrImageView), findsNothing);
      expect(find.text(fr.pastTitle), findsOneWidget);
      expect(find.text(fr.missed), findsOneWidget);
      expect(find.text(fr.noUpcomingTitle), findsOneWidget);
    });

    testWidgets('several tickets: the page is named, nothing overflows',
        (tester) async {
      await _pump(
        tester,
        tickets: [
          _ticket(),
          _ticket(id: 2, code: 'TCK-2', start: DateTime(2026, 11, 20, 18)),
        ],
        clock: _Clock(DateTime(2026, 11, 6, 15, 48)),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(fr.page(1, 2)), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('past tickets', () {
    testWidgets('say who was there, and fold after three', (tester) async {
      final tickets = [
        for (var i = 1; i <= 5; i++)
          _ticket(
            id: i,
            code: 'TCK-$i',
            start: DateTime(2026, 10, i, 20),
            checkedInAt: i.isEven ? DateTime(2026, 10, i, 19) : null,
          ),
      ];
      await _pump(tester,
          tickets: tickets, clock: _Clock(DateTime(2026, 11, 1)));

      expect(find.text(fr.pastSeeAll(5)), findsOneWidget);
      expect(find.text(fr.attended), findsOneWidget); // the 4th of October
      expect(find.text(fr.missed), findsNWidgets(2));

      await tester.ensureVisible(find.text(fr.pastSeeAll(5)));
      await tester.tap(find.text(fr.pastSeeAll(5)));
      await tester.pump();
      expect(find.text(fr.attended), findsNWidgets(2));
      expect(find.text(fr.missed), findsNWidgets(3));
    });
  });

  group('no ticket yet', () {
    testWidgets('no reservation: an invitation to reserve', (tester) async {
      await _pump(tester, tickets: const [], clock: _Clock(_start));
      await tester.pump();

      expect(find.text(fr.emptyTitle), findsOneWidget);
      expect(find.text(fr.browseShows), findsOneWidget);
    });

    testWidgets('a reservation on its way: where it stands', (tester) async {
      await _pump(
        tester,
        tickets: const [],
        clock: _Clock(_start),
        reservations: [
          Reservation(
            id: 1,
            userId: 1,
            showId: 1,
            seats: 1,
            status: 'pending_review',
            createdAt: DateTime(2026, 11, 1),
            show: _ticket().show,
          ),
        ],
      );
      await tester.pump();

      expect(find.text(fr.pendingTitle('Planet Foot')), findsOneWidget);
      expect(find.text(fr.pendingSteps[1]), findsOneWidget);
    });

    testWidgets('a reservation for a recording long gone is not on its way',
        (tester) async {
      await _pump(
        tester,
        tickets: const [],
        clock: _Clock(_start.add(const Duration(days: 3))),
        reservations: [
          Reservation(
            id: 1,
            userId: 1,
            showId: 1,
            seats: 1,
            status: 'pending_review',
            createdAt: DateTime(2026, 11, 1),
            show: _ticket().show,
          ),
        ],
      );
      await tester.pump();

      expect(find.text(fr.emptyTitle), findsOneWidget);
      expect(find.text(fr.pendingTitle('Planet Foot')), findsNothing);
    });
  });

  group('holds on small phones, big text and Arabic', () {
    final sizes = {
      'small phone': const Size(320, 568),
      'regular phone': const Size(390, 844),
    };
    final moments = {
      'days away': DateTime(2026, 11, 6, 15, 48),
      'today': DateTime(2026, 11, 8, 12),
      'live': _start.add(const Duration(minutes: 5)),
    };

    for (final locale in AppLocale.values) {
      for (final size in sizes.entries) {
        for (final moment in moments.entries) {
          testWidgets('${locale.name}, ${size.key}, ${moment.key}',
              (tester) async {
            await _pump(
              tester,
              tickets: [
                _ticket(
                    title:
                        'Une émission au titre vraiment très long pour voir'),
              ],
              clock: _Clock(moment.value),
              locale: locale,
              size: size.value,
              textScale: 1.3,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(QrImageView), findsOneWidget);
          });
        }
      }
    }
  });
}
