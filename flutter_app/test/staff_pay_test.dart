import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/copywriting/staff_pay_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';
import 'package:aji_tfarraj/features/staff_pay/data/staff_pay_repository.dart';
import 'package:aji_tfarraj/features/staff_pay/domain/staff_pay.dart';
import 'package:aji_tfarraj/features/staff_pay/presentation/staff_pay_screen.dart';

const _payJson = {
  'positions': [
    {
      'position': 'tech',
      'starts_on': '2026-10-08',
      'ends_on': null,
      'current': true
    },
  ],
  'total': 245,
  'episodes': 3,
  'pending': 0,
  'balance': {'available': 245, 'staff': 245},
  'lines': [
    {
      'episode_id': 9,
      'date': '2026-11-02',
      'show': 'Une émission au titre vraiment très long pour un téléphone',
      'position': 'tech',
      'size': null,
      'entries': 120,
      'amount': 120,
      'pending': false
    },
    {
      'episode_id': 8,
      'date': '2026-10-12',
      'show': 'Rachid Show',
      'position': 'tech',
      'size': 'big',
      'entries': 80,
      'amount': 80,
      'pending': false
    },
    {
      'episode_id': 7,
      'date': '2026-10-10',
      'show': 'Lalla Laaroussa',
      'position': 'tech',
      'size': 'small',
      'entries': 45,
      'amount': 45,
      'pending': false
    },
  ],
};

/// Retraits fermés : la carte Wafacash, inchangée et déjà en production, ne
/// passe pas dans la police de test (chaque lettre y est un carré plein,
/// « Retirer mes gains » double de largeur). Ce test vérifie l'écran de paie.
const _wafacashJson = {
  'open': false,
  'min_amount': 50,
  'max_amount': 5000,
  'fees': [
    {'up_to': 1000, 'fee': 37},
  ],
  'balance': {
    'earned': 245,
    'paid': 0,
    'reserved': 0,
    'unpaid': 245,
    'available': 245
  },
  'identity': {
    'status': 'verified',
    'legal_name': 'Mouad Baamrane',
    'cin_masked': 'AB••••56'
  },
  'withdrawals': [],
};

void main() {
  group('StaffPayOverview.fromJson', () {
    test('lit la réponse de /api/me/staff-pay', () {
      final pay = StaffPayOverview.fromJson({
        'since': '2026-10-08',
        'positions': [
          {
            'position': 'cp_supervisor',
            'starts_on': '2026-10-08',
            'ends_on': null,
            'current': true
          },
        ],
        'total': 500,
        'episodes': 3,
        'pending': 1,
        'balance': {
          'earned': 740,
          'paid': 0,
          'reserved': 0,
          'unpaid': 740,
          'available': 740,
          'staff': 500
        },
        'lines': [
          {
            'episode_id': 9,
            'date': '2026-10-12',
            'show': 'Lalla Laaroussa',
            'episode': null,
            'position': 'cp_supervisor',
            'size': null,
            'entries': 120,
            'amount': 0,
            'pending': true
          },
          {
            'episode_id': 7,
            'date': '2026-10-10',
            'show': 'Rachid Show',
            'episode': null,
            'position': 'cp_supervisor',
            'size': 'big',
            'entries': 80,
            'amount': 300,
            'pending': false
          },
        ],
      });

      expect(pay.total, 500);
      expect(pay.episodes, 3);
      expect(pay.pending, 1);
      expect(pay.available, 740);
      expect(pay.currentPositions.single.position, 'cp_supervisor');
      expect(pay.lines.first.pending, isTrue);
      expect(pay.lines.last.amount, 300);
      expect(pay.lines.last.date, DateTime(2026, 10, 10));
    });

    test('une réponse vide ne casse rien', () {
      final pay = StaffPayOverview.fromJson(const {});

      expect(pay.total, 0);
      expect(pay.lines, isEmpty);
      expect(pay.currentPositions, isEmpty);
    });
  });

  test('le profil porte le drapeau staff_pay', () {
    final json = {
      'id': 1,
      'name': 'Mouad',
      'email': 'm@example.com',
      'created_at': '2026-10-08T10:00:00Z',
      'updated_at': '2026-10-08T10:00:00Z',
      'staff_pay': true,
    };

    expect(User.fromJson(json).staffPay, isTrue);
    expect(User.fromJson({...json}..remove('staff_pay')).staffPay, isFalse);
    expect(User.fromJson(User.fromJson(json).toJson()).staffPay, isTrue);
  });

  group('copy', () {
    for (final c in const <StaffPayCopy>[StaffPayCopyFr(), StaffPayCopyAr()]) {
      test('${c.runtimeType} nomme chaque poste et chaque format', () {
        for (final code in ['cp_supervisor', 'warm_up', 'tech']) {
          expect(c.position(code), isNot(code));
          expect(c.rateLine(code), isNotEmpty);
        }
        expect(c.size('big'), isNot(c.size('small')));
        expect(c.size(null), isNot(c.size('big')));
        expect(c.month(DateTime(2026, 10, 1)), contains('2026'));
      });
    }
  });

  group('l\'écran', () {
    for (final locale in AppLocale.values) {
      testWidgets('se dessine sans débordement (${locale.name})',
          (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            stringsProvider.overrideWithValue(AppStrings(locale)),
            staffPayProvider.overrideWith(
                (ref) async => StaffPayOverview.fromJson(_payJson)),
            wafacashProvider.overrideWith(
                (ref) async => WafacashOverview.fromJson(_wafacashJson)),
          ],
          child: MaterialApp(
            home: Directionality(
              textDirection:
                  locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
              child: const StaffPayScreen(),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        final c = AppStrings(locale).staffPay;
        expect(tester.takeException(), isNull);
        expect(find.text(c.money(245)), findsWidgets);
        expect(find.text(c.position('tech')), findsOneWidget);
        expect(find.text(c.entries(120)), findsOneWidget);
        expect(find.text(c.month(DateTime(2026, 10))), findsOneWidget);
      });
    }
  });
}
