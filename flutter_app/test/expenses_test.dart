import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/copywriting/expenses_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/auth/domain/user.dart';
import 'package:aji_tfarraj/features/expenses/data/expenses_repository.dart';
import 'package:aji_tfarraj/features/expenses/domain/expense.dart';
import 'package:aji_tfarraj/features/expenses/presentation/expense_form_screen.dart';
import 'package:aji_tfarraj/features/expenses/presentation/expenses_screen.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart';

const _expenseJson = {
  'id': 12,
  'category': 'catering',
  'status': 'refused',
  'spent_on': '2026-11-26',
  'amount': 720,
  'paid_from': 'cash_box',
  'affects_cash_box': true,
  'summary': '40 sandwichs × 15 DH',
  'episode': {
    'id': 3,
    'title': 'Prime 6',
    'show': 'Une émission au titre vraiment très long pour un téléphone',
    'date': '2026-11-26'
  },
  'provider': 'Snack Atlas',
  'fields': {
    'with_transport': true,
    'minibuses': 0,
    'coaches': 0,
    'mission': null,
    'indemnified': false,
    'from_cash_box': true,
    'sandwiches': 40,
    'sandwich_price': 15,
    'drinks': 120,
    'paid_people': 0,
    'price_per_person': 0,
    'free_people': 0,
    'staff_user_id': null
  },
  'staff_user': null,
  'note': null,
  'review_note': 'Pas de reçu',
  'reviewed_by': 'Ayoub Serrakh',
  'photos': [],
  'editable': true,
};

const _overviewJson = {
  'cash_box': {
    'given': 2500,
    'returned': 0,
    'spent': 720,
    'spent_validated': 0,
    'spent_pending': 720,
    'balance': 1780
  },
  'counts': {'pending': 1, 'validated': 4, 'refused': 1},
  'movements': [
    {
      'id': 1,
      'kind': 'deposit',
      'amount': 2500,
      'date': '2026-11-25',
      'note': 'Pour le Prime 6',
      'by': 'Ayoub Serrakh'
    },
  ],
  'recent': [_expenseJson],
};

const _formJson = {
  'episodes': [
    {
      'id': 3,
      'title': 'Prime 6',
      'show': 'Starlight',
      'date': '2026-11-26',
      'time': '19:00',
      'pays_staff': true,
      'day_staff': null
    },
    {
      'id': 4,
      'title': 'Épisode 12',
      'show': 'Jemaatna Zina',
      'date': '2026-11-28',
      'time': '18:00',
      'pays_staff': false,
      'day_staff': {'expense_id': 9, 'name': 'Simo Akssa'}
    },
  ],
  'staff': [
    {'id': 7, 'name': 'Simo Akssa', 'phone': '06 12 34 56 78'},
  ],
  'providers': {
    'catering': ['Snack Atlas'],
    'transport': ['Trans Sud']
  },
  'day_staff_rate': 200,
  'max_photos': 6,
};

Widget _app(AppLocale locale, SharedPreferences prefs, Widget child) =>
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        stringsProvider.overrideWithValue(AppStrings(locale)),
        expensesOverviewProvider.overrideWith(
            (ref) async => ExpensesOverview.fromJson(_overviewJson)),
        expensesByStatusProvider.overrideWith((ref, status) async =>
            ExpensePage(
                items: status == 'refused' || status == 'pending'
                    ? [Expense.fromJson(_expenseJson)]
                    : const [])),
        expenseFormOptionsProvider.overrideWith(
            (ref) async => ExpenseFormOptions.fromJson(_formJson)),
      ],
      child: MaterialApp(
        home: Directionality(
          textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child,
        ),
      ),
    );

void main() {
  group('lecture des réponses', () {
    test('la caisse et les compteurs', () {
      final o = ExpensesOverview.fromJson(_overviewJson);
      expect(o.cashBox.balance, 1780);
      expect(o.cashBox.spentPending, 720);
      expect(o.refused, 1);
      expect(o.movements.single.isDeposit, isTrue);
      expect(o.recent.single.provider, 'Snack Atlas');
    });

    test('une dépense refusée garde son motif et ses champs', () {
      final e = Expense.fromJson(_expenseJson);
      expect(e.isRefused, isTrue);
      expect(e.reviewNote, 'Pas de reçu');
      final d = ExpenseDraft.fromExpense(e);
      expect(d.sandwiches, 40);
      expect(d.total(), 40 * 15 + 120);
    });

    test('le formulaire : programmes, staff, prestataires', () {
      final f = ExpenseFormOptions.fromJson(_formJson);
      expect(f.episode(4)!.paysStaff, isFalse);
      expect(f.episode(4)!.dayStaffName, 'Simo Akssa');
      expect(f.providersFor('transport'), ['Trans Sud']);
      expect(f.dayStaffRate, 200);
    });

    test('une réponse vide ne casse rien', () {
      expect(ExpensesOverview.fromJson(const {}).cashBox.balance, 0);
      expect(ExpenseFormOptions.fromJson(const {}).maxPhotos, 6);
      expect(ExpensePage.fromJson(const {}).items, isEmpty);
    });

    test('le profil porte le drapeau expenses', () {
      final json = {
        'id': 1,
        'name': 'Hamza',
        'email': 'h@example.com',
        'created_at': '2026-11-25T10:00:00Z',
        'updated_at': '2026-11-25T10:00:00Z',
        'expenses': true,
      };
      expect(User.fromJson(json).expenses, isTrue);
      expect(User.fromJson({...json}..remove('expenses')).expenses, isFalse);
      expect(User.fromJson(User.fromJson(json).toJson()).expenses, isTrue);
    });
  });

  group('le brouillon', () {
    test('les totaux se calculent comme sur le serveur', () {
      expect(
          ExpenseDraft(category: 'audience', paidPeople: 12, pricePerPerson: 50)
              .total(),
          600);
      expect(ExpenseDraft(category: 'staff_day').total(dayStaffRate: 200), 200);
      expect(
          ExpenseDraft(category: 'transport', withTransport: false, amount: 900)
              .total(),
          0);
      expect(
          ExpenseDraft(category: 'vehicle', indemnified: false, amount: 300)
              .total(),
          0);
    });

    test('ce qui sort de la caisse', () {
      expect(ExpenseDraft(category: 'catering').takesFromCashBox, isTrue);
      expect(ExpenseDraft(category: 'transport').takesFromCashBox, isFalse);
      expect(ExpenseDraft(category: 'fuel').takesFromCashBox, isFalse);
      expect(ExpenseDraft(category: 'taxi').takesFromCashBox, isTrue);
      expect(
          ExpenseDraft(category: 'taxi', fromCashBox: false).takesFromCashBox,
          isFalse);
      // La voiture : par défaut, la société paie l'indemnité.
      expect(
          ExpenseDraft(category: 'vehicle', indemnified: true).takesFromCashBox,
          isFalse);
    });

    test('ce qui manque, avant d\'envoyer', () {
      expect(ExpenseDraft(category: 'audience').missing(),
          containsAll(['episode', 'people']));
      expect(ExpenseDraft(category: 'transport', episodeId: 3).missing(),
          containsAll(['provider', 'vehicles']));
      expect(
          ExpenseDraft(
                  category: 'transport', episodeId: 3, withTransport: false)
              .missing(),
          isEmpty);
      expect(ExpenseDraft(category: 'other', amount: 50).missing(), ['note']);
      expect(ExpenseDraft(category: 'staff_day', episodeId: 4).missing(),
          ['staff']);
    });

    test('les champs envoyés', () {
      final f = ExpenseDraft(
        category: 'transport',
        episodeId: 3,
        spentOn: DateTime(2026, 11, 26),
        provider: ' Trans Sud ',
        minibuses: 2,
        coaches: 1,
      ).toFields();
      expect(f['spent_on'], '2026-11-26');
      expect(f['with_transport'], 1);
      expect(f['provider'], 'Trans Sud');
      expect(f.containsKey('amount'), isFalse);
    });
  });

  group('copy', () {
    for (final c in const <ExpensesCopy>[ExpensesCopyFr(), ExpensesCopyAr()]) {
      test('${c.runtimeType} nomme chaque catégorie et chaque état', () {
        for (final code in ExpenseCategory.all) {
          expect(c.category(code), isNot(code));
          expect(c.categoryHint(code), isNotEmpty);
        }
        for (final s in ['pending', 'validated', 'refused']) {
          expect(c.status(s), isNot(s));
        }
        for (final k in [
          'episode',
          'provider',
          'vehicles',
          'catering',
          'people',
          'price',
          'staff',
          'mission',
          'note',
          'amount'
        ]) {
          expect(c.missing(k), isNotEmpty);
        }
      });
    }
  });

  group('les écrans', () {
    for (final locale in AppLocale.values) {
      testWidgets('« Ma caisse » se dessine sans débordement (${locale.name})',
          (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(_app(locale, prefs, const ExpensesScreen()));
        await tester.pumpAndSettle();

        final c = AppStrings(locale).expenses;
        expect(tester.takeException(), isNull);
        expect(find.text(c.money(1780)), findsOneWidget);
        expect(find.text(c.category('catering')), findsWidgets);
        expect(find.text(c.refusedBanner), findsOneWidget);
      });

      testWidgets('le formulaire calcule le total en direct (${locale.name})',
          (tester) async {
        tester.view.physicalSize = const Size(375 * 3, 812 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();

        await tester.pumpWidget(_app(
            locale,
            prefs,
            ExpenseFormScreen(
                args: ExpenseFormArgs(
                    existing: Expense.fromJson(_expenseJson)))));
        await tester.pumpAndSettle();

        final c = AppStrings(locale).expenses;
        expect(tester.takeException(), isNull);
        // 40 × 15 + 120 : le total de la dépense refusée, à corriger.
        expect(find.text(c.money(720)), findsOneWidget);
        expect(find.text(c.saveChanges), findsOneWidget);

        // Un appui sur « + » : 5 sandwichs de plus, 75 DH de plus.
        await tester.tap(find.byIcon(Icons.add).first);
        await tester.pumpAndSettle();
        expect(find.text(c.money(795)), findsOneWidget);
      });
    }
  });
}
