// The charge public taps a recording and sees who came, and what each one
// brought in. Pumped at phone width, in French and in Arabic, to catch a layout
// exception in the unfolded list as much as a wrong label.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aji_tfarraj/app/copywriting/copy_ar.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
import 'package:aji_tfarraj/features/charge_public/domain/cp_dashboard.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/charge_public_shell.dart';

Map<String, dynamic> _guest(String name,
        {int? amount, String resStatus = 'checked_in'}) =>
    {
      'name': name,
      'avatar_url': null,
      'attended': amount != null,
      'amount': amount,
      'visit': 1,
      'res_status': resStatus,
    };

/// Most recent first, as the server sends it: an upcoming recording, then one
/// that already happened.
CpShowRow _show({bool withGuests = true}) => CpShowRow.fromJson({
      'show_id': 4,
      'show_title': 'Saat Saraha',
      'invited': 6,
      'attended': 2,
      'not_attended': 4,
      'earnings': 35,
      'episodes': [
        {
          'episode_id': 12,
          'title': null,
          'starts_at':
              DateTime.now().add(const Duration(days: 3)).toUtc().toIso8601String(),
          'invited': 2,
          'attended': 0,
          'not_attended': 2,
          'earnings': 0,
          if (withGuests)
            'guests': [
              _guest('Imane', resStatus: 'approved'),
              _guest('Omar', resStatus: 'pending_review'),
            ],
        },
        {
          'episode_id': 11,
          'title': null,
          'starts_at': DateTime.now()
              .subtract(const Duration(days: 2))
              .toUtc()
              .toIso8601String(),
          'invited': 4,
          'attended': 2,
          'not_attended': 2,
          'earnings': 35,
          if (withGuests)
            'guests': [
              _guest('Salma', amount: 25),
              _guest('Youssef', amount: 10),
              _guest('Karim', resStatus: 'approved'),
              _guest('Nadia', resStatus: 'cancelled'),
            ],
        },
      ],
    });

Future<void> _pump(
  WidgetTester tester, {
  required CpShowRow row,
  required ChargePublicCopy cp,
  TextDirection dir = TextDirection.ltr,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: dir,
        child: Scaffold(body: CpEpisodeBreakdownSheet(row: row, cp: cp)),
      ),
    ),
  );
}

void main() {
  testWidgets('a past recording unfolds into names and what each one paid',
      (tester) async {
    const cp = ChargePublicCopyFr();
    await _pump(tester, row: _show(), cp: cp);

    expect(find.text(cp.episodeTapHint), findsOneWidget);
    expect(find.text('Salma'), findsNothing, reason: 'folded until tapped');

    await tester.tap(find.byIcon(Icons.expand_more).at(1));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Salma'), findsOneWidget);
    expect(find.text('+25 DH'), findsOneWidget);
    expect(find.text('+10 DH'), findsOneWidget);
    expect(find.text(cp.statusAbsent), findsOneWidget,
        reason: 'approved, did not come, and the night is over');
    expect(find.text(cp.statusCancelled), findsOneWidget,
        reason: 'a cancelled booking keeps its own label');

    await tester.tap(find.byIcon(Icons.expand_more).at(1));
    await tester.pumpAndSettle();
    expect(find.text('Salma'), findsNothing, reason: 'a second tap folds it');
  });

  testWidgets('an upcoming recording is not calling anyone absent yet',
      (tester) async {
    const cp = ChargePublicCopyFr();
    await _pump(tester, row: _show(), cp: cp);

    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Imane'), findsOneWidget);
    expect(find.text(cp.statusApproved), findsOneWidget);
    expect(find.text(cp.statusPending), findsOneWidget);
    expect(find.text(cp.statusAbsent), findsNothing);
  });

  testWidgets('in Arabic, right to left, the list unfolds without overflow',
      (tester) async {
    const cp = ChargePublicCopyAr();
    await _pump(tester, row: _show(), cp: cp, dir: TextDirection.rtl);

    await tester.tap(find.byIcon(Icons.expand_more).at(1));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Salma'), findsOneWidget);
    expect(find.text(cp.gain(25)), findsOneWidget);
    expect(find.text(cp.statusAbsent), findsOneWidget);
  });

  /// An older server sends no names: no chevron, no hint, nothing to open.
  testWidgets('without names from the server, episodes stay plain lines',
      (tester) async {
    const cp = ChargePublicCopyFr();
    await _pump(tester, row: _show(withGuests: false), cp: cp);

    expect(find.byIcon(Icons.expand_more), findsNothing);
    expect(find.text(cp.episodeTapHint), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
