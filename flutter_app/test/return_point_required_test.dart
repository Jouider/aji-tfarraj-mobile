import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:aji_tfarraj/features/staff/data/staff_repository.dart';
import 'package:aji_tfarraj/features/staff/domain/ticket_preview.dart';
import 'package:aji_tfarraj/features/staff/presentation/ticket_preview_view.dart';

/// The drop-off question has to be *put*, not merely available.
///
/// `return_point_id: null` means both "makes their own way" and "nobody asked".
/// If the door can validate without answering, the two collapse into one, the
/// shuttle sheet under-counts, and somebody is left at the studio. With two or
/// three scanners at a busy door that is not a hypothetical.
class _FakeStaffRepository implements StaffRepository {
  _FakeStaffRepository(this.preview);

  final TicketPreview preview;
  final List<int?> saved = [];

  @override
  Future<TicketPreview> lookup({String? qrToken, String? ticketCode}) async =>
      preview;

  @override
  Future<void> setReturnPoint({
    required int reservationId,
    required int? pointId,
  }) async {
    saved.add(pointId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TicketPreview previewWith({required bool shuttle, int? alreadyChosen}) =>
    TicketPreview.fromJson({
      'status': 'can_check_in',
      'ticket_code': 'AT-2026-000002',
      'attendee': {'id': 71, 'name': 'Ahmed Bennani'},
      'reservation': {
        'id': 5933,
        'seats': 1,
        if (alreadyChosen != null)
          'return_point': {'id': alreadyChosen, 'name': 'Maarif'},
      },
      'episode': {'id': 10, 'title': 'episode 10'},
      'show': {'id': 1, 'title': 'Saat Saraha'},
      'return_points': shuttle
          ? [
              {'id': 3, 'name': 'Ain Sebaa', 'landmark': 'devant la gare'},
              {'id': 4, 'name': 'Maarif'},
            ]
          : <Map<String, dynamic>>[],
    });

Future<_FakeStaffRepository> pumpDoor(
  WidgetTester tester,
  TicketPreview preview,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  final fake = _FakeStaffRepository(preview);
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    staffRepositoryProvider.overrideWithValue(fake),
  ]);
  addTearDown(container.dispose);

  // Keep the autoDispose notifier alive while we seed it.
  container.listen(staffCheckInProvider, (_, __) {});
  await container.read(staffCheckInProvider.notifier).lookup(ticketCode: 'AT-1');

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: TicketPreviewView(preview: preview, onCancel: () {}),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return fake;
}

/// `FilledButton.icon` builds a private subclass, and `find.byType` matches the
/// exact runtime type — hence the predicate.
Finder confirmButton() => find
    .ancestor(
      of: find.text("Valider l'entrée"),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    )
    .first;

bool isEnabled(WidgetTester tester) =>
    (tester.widget(confirmButton()) as FilledButton).onPressed != null;

void main() {
  testWidgets('a shuttle runs and nobody asked: validating is blocked',
      (tester) async {
    await pumpDoor(tester, previewWith(shuttle: true));

    expect(confirmButton(), findsOneWidget,
        reason: 'the button stays, so the scanner sees what is expected');
    expect(isEnabled(tester), isFalse);
    expect(find.textContaining('Demandez où la personne rentre'), findsOneWidget);
  });

  /// Nothing may look answered before it is: a pre-ticked "makes their own way"
  /// reads as a recorded answer and the scanner moves on without asking.
  testWidgets('no option is pre-selected before the question is put',
      (tester) async {
    await pumpDoor(tester, previewWith(shuttle: true));

    final selected = tester
        .widgetList<Container>(find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ))
        .where((c) {
          final border = (c.decoration as BoxDecoration?)?.border;
          return border is Border && border.top.width >= 1.5;
        });

    expect(selected, isEmpty);
  });

  testWidgets('choosing a stop unblocks it', (tester) async {
    final fake = await pumpDoor(tester, previewWith(shuttle: true));

    await tester.tap(find.text('Ain Sebaa'));
    await tester.pumpAndSettle();

    expect(fake.saved, [3]);
    expect(isEnabled(tester), isTrue);
  });

  /// "They make their own way" is a real answer — it just has to be recorded
  /// deliberately rather than assumed.
  testWidgets('answering "makes their own way" unblocks it too', (tester) async {
    final fake = await pumpDoor(tester, previewWith(shuttle: true));

    await tester.tap(find.text('Repart par ses propres moyens'));
    await tester.pumpAndSettle();

    expect(fake.saved, [null]);
    expect(isEnabled(tester), isTrue);
  });

  /// No shuttle tonight means no question, so nothing should stand in the way.
  testWidgets('no shuttle: validating is available straight away',
      (tester) async {
    await pumpDoor(tester, previewWith(shuttle: false));

    expect(find.text('Repart par ses propres moyens'), findsNothing);
    expect(isEnabled(tester), isTrue);
  });

  /// An answer given on an earlier scan still counts as asked.
  testWidgets('an earlier answer does not have to be repeated', (tester) async {
    await pumpDoor(tester, previewWith(shuttle: true, alreadyChosen: 4));

    expect(isEnabled(tester), isTrue);
  });
}
