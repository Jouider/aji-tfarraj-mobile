import 'package:aji_tfarraj/app/copywriting/wafacash_copy.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/locale_provider.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/features/charge_public/data/charge_public_repository.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/wafacash_news.dart';
import 'package:aji_tfarraj/features/charge_public/presentation/wafacash_section.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les retraits Wafacash côté app.
///
/// Les contrôles d'ici guident la saisie — le serveur revérifie — mais ils
/// doivent suivre SA règle : le montant demandé part tel quel, et l'agence prend
/// ses frais au guichet.
void main() {
  Map<String, dynamic> etat({
    bool open = true,
    int available = 800,
    Map<String, dynamic>? identity,
    List<Map<String, dynamic>> withdrawals = const [],
  }) =>
      {
        'open': open,
        'min_amount': 100,
        'max_amount': 3000,
        // La grille Wafacash, désordonnée exprès.
        'fees': [
          {'up_to': 3000, 'fee': 47},
          {'up_to': 1000, 'fee': 37},
          {'up_to': 80000, 'percent': 0.67},
          {'up_to': 5000, 'fee': 57},
          {'up_to': 10000, 'fee': 67},
        ],
        'balance': {
          'earned': 1000,
          'paid': 200,
          'reserved': 0,
          'available': available
        },
        'identity': identity,
        'withdrawals': withdrawals,
      };

  group('les frais, sur le montant ENVOYÉ', () {
    final o = WafacashOverview.fromJson(etat());

    test('la grille Wafacash, pourcentage compris', () {
      expect(o.feeFor(1000), 37);
      expect(o.feeFor(1001), 47);
      expect(o.feeFor(10001), 68); // 0,67 %, arrondi au dirham supérieur
      expect(o.feeFor(80001), isNull);
    });

    test('le montant doit couvrir les frais, comme le veut le serveur', () {
      expect(o.covers(37), isFalse);
      expect(o.covers(38), isTrue);
      expect(o.covers(80001), isFalse); // hors de la grille
    });

    test('on prévient quand les frais mangent un cinquième du montant', () {
      expect(o.feesWeighHeavy(50), isTrue);
      expect(o.feesWeighHeavy(185), isTrue);
      expect(o.feesWeighHeavy(186), isFalse);
      expect(o.feesWeighHeavy(37), isFalse); // déjà refusé par covers()
    });
  });

  group('le solde', () {
    test('on ne demande jamais plus que le disponible ni que le maximum', () {
      expect(
          WafacashOverview.fromJson(etat(available: 800)).maxRequestable, 800);
      expect(WafacashOverview.fromJson(etat(available: 9000)).maxRequestable,
          3000);
    });

    test('sous le minimum, rien à proposer', () {
      expect(WafacashOverview.fromJson(etat(available: 80)).hasEnough, isFalse);
      expect(WafacashOverview.fromJson(etat(available: 100)).hasEnough, isTrue);
    });

    test('ce qu\'il manque pour atteindre le minimum', () {
      expect(WafacashOverview.fromJson(etat(available: 80)).missingForMin, 20);
      expect(WafacashOverview.fromJson(etat(available: 100)).missingForMin, 0);
    });

    test('l\'argent du dernier tournage est compté à part', () {
      final o = WafacashOverview.fromJson({
        ...etat(available: 200),
        'balance': {'earned': 500, 'paid': 0, 'held': 300, 'available': 200},
      });
      expect(o.balance.held, 300);
      expect(o.maxRequestable, 200);
    });
  });

  group('une demande', () {
    Map<String, dynamic> retrait(String status,
            {String? code, String? reason}) =>
        {
          'id': 7,
          'status': status,
          'gross_amount': 600,
          'fee_amount': 25,
          'net_amount': 575,
          'legal_name': 'Karim Ouali',
          'code': code,
          'closed_reason': reason,
          'requested_at': '2026-10-05T10:00:00Z',
        };

    test('annulée par le staff : la raison, et on peut recommencer', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [
        retrait('cancelled',
            reason:
                'Ton solde est en cours de vérification après le tournage.'),
        retrait('collected'),
      ]));

      expect(o.current, isNull);
      expect(o.lastCancelledByStaff?.closedReason,
          'Ton solde est en cours de vérification après le tournage.');
    });

    test('annulée par le chargé public lui-même : rien à expliquer', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [
        retrait('cancelled', reason: 'Annulé par le chargé public'),
      ]));
      expect(o.lastCancelledByStaff, isNull);
    });

    test('une demande refaite depuis efface le message', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [
        retrait('requested'),
        retrait('cancelled', reason: 'Solde à vérifier'),
      ]));
      expect(o.lastCancelledByStaff, isNull);
      expect(o.current?.status, WafacashWithdrawalStatus.requested);
    });

    test('la demande en route est retrouvée, les closes non', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [
        retrait('code_sent', code: '123456789012'),
        retrait('collected'),
      ]));

      expect(o.current?.status, WafacashWithdrawalStatus.codeSent);
      expect(o.current?.code, '123456789012');
    });

    test('le code se lit par groupes de trois', () {
      final w = WafacashWithdrawal.fromJson(
          retrait('code_sent', code: '123456789012'));
      expect(w.formattedCode, '123 456 789 012');
      expect(w.code, '123456789012');
    });

    test('la date limite : les jours restants, sur le calendrier', () {
      final w = WafacashWithdrawal.fromJson({
        ...retrait('code_sent', code: '123456789012'),
        'collect_before': DateTime(2026, 12, 15, 9).toIso8601String(),
      });
      expect(w.daysLeft(DateTime(2026, 12, 10, 23)), 5);
      expect(w.daysLeft(DateTime(2026, 12, 15, 23)), 0);
      expect(w.daysLeft(DateTime(2026, 12, 16, 1)), -1);
      expect(
          WafacashWithdrawal.fromJson(retrait('requested'))
              .daysLeft(DateTime(2026)),
          isNull);
    });

    test('plus rien en route une fois retiré', () {
      final o =
          WafacashOverview.fromJson(etat(withdrawals: [retrait('collected')]));
      expect(o.current, isNull);
    });

    test('annulable seulement tant que le staff ne l\'a pas prise', () {
      expect(
          WafacashWithdrawal.fromJson(retrait('requested')).canCancel, isTrue);
      expect(WafacashWithdrawal.fromJson(retrait('processing')).canCancel,
          isFalse);
    });

    test('un statut inconnu ne passe pas pour une demande en route', () {
      final w = WafacashWithdrawal.fromJson(retrait('quelque_chose_de_neuf'));
      expect(w.status, WafacashWithdrawalStatus.unknown);
      expect(w.status.isOpen, isFalse);
    });
  });

  test('l\'identité arrive masquée et son statut se lit', () {
    final o = WafacashOverview.fromJson(etat(identity: {
      'status': 'verified',
      'legal_name': 'Karim Ouali',
      'cin_masked': 'AB1234••',
    }));

    expect(o.identity!.isVerified, isTrue);
    expect(o.identity!.cinMasked, 'AB1234••');
  });

  test('un serveur sans Wafacash laisse la fonction fermée', () {
    final o = WafacashOverview.fromJson(const {});
    expect(o.open, isFalse);
    expect(o.current, isNull);
  });

  group('le push « ton argent est prêt »', () {
    test('ouvre l\'onglet des gains via le lien profond', () {
      expect(
        PushRouter.getRouteFromData({
          'type': 'wafacash',
          'deep_link': '/charge-public?tab=gains',
        }),
        '/charge-public?tab=gains',
      );
    });

    test('et même sans lien profond', () {
      expect(PushRouter.getRouteFromData({'type': 'wafacash'}),
          '/charge-public?tab=gains');
    });
  });

  group('l\'ouverture du mois', () {
    Map<String, dynamic> identite() => {
          'status': 'verified',
          'legal_name': 'Karim Ouali',
          'cin_masked': 'AB12••',
        };

    Future<void> pump(WidgetTester tester, Map<String, dynamic> json) async {
      await initializeDateFormatting('fr_FR', null);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider
              .overrideWith((ref) async => WafacashOverview.fromJson(json)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WafacashSection(onChanged: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    final dansTroisMois = DateTime.now().add(const Duration(days: 90));

    // Du 5 au 10 et pas les vrais jours (du 10 au 15), exprès : c'est ce qui
    // prouve que l'app lit le serveur et n'écrit aucune date en dur.
    Map<String, dynamic> fenetre({
      bool openNow = false,
      DateTime? closes,
      DateTime? opens,
      DateTime? exception,
    }) =>
        {
          'start_day': 5,
          'end_day': 10,
          'open_now': openNow,
          'closes_at': closes?.toIso8601String(),
          'next_opens_at': (opens ?? dansTroisMois).toIso8601String(),
          'exception_until': exception?.toIso8601String(),
        };

    test('les jours et les dates viennent du serveur', () {
      final o = WafacashOverview.fromJson({...etat(), 'window': fenetre()});
      expect(o.window!.startDay, 5);
      expect(o.window!.endDay, 10);
      expect(o.canRequestNow, isFalse);
    });

    test('sans fenêtre, ouvert tout le mois — et un vieux serveur aussi', () {
      expect(
          WafacashOverview.fromJson({...etat(), 'window': null}).canRequestNow,
          isTrue);
      expect(WafacashOverview.fromJson(etat()).canRequestNow, isTrue);
    });

    test('l\'interrupteur général coupé l\'emporte sur le calendrier', () {
      final o = WafacashOverview.fromJson(
          {...etat(open: false), 'window': fenetre(openNow: true)});
      expect(o.canRequestNow, isFalse);
    });

    test('l\'argent du tournage fait pendant l\'ouverture est à part', () {
      final o = WafacashOverview.fromJson({
        ...etat(),
        'balance': {
          'earned': 500,
          'paid': 0,
          'deferred': 200,
          'available': 300
        },
      });
      expect(o.balance.deferred, 200);
      expect(o.maxRequestable, 300);
    });

    testWidgets('fermé : la règle, la date, et un bouton qui ne part pas',
        (tester) async {
      await pump(tester, {...etat(identity: identite()), 'window': fenetre()});
      const c = WafacashCopyFr();
      final date = c.date(dansTroisMois);

      expect(find.text(c.windowRule(5, 10)), findsOneWidget);
      expect(find.text(c.windowEmergency), findsOneWidget);
      expect(find.text(c.availableAtOpening), findsOneWidget);
      expect(find.text(c.windowClosedButton(date)), findsOneWidget);
      expect(find.text(c.cardWithdraw), findsNothing);

      final bouton = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text(c.windowClosedButton(date)),
        matching: find.byType(ElevatedButton),
      ));
      expect(bouton.onPressed, isNull);
    });

    testWidgets('fermé, sans identité : la CIN s\'envoie quand même',
        (tester) async {
      await pump(tester, {...etat(), 'window': fenetre()});
      const c = WafacashCopyFr();

      final bouton = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text(c.identityStart),
        matching: find.byType(ElevatedButton),
      ));
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('ouvert : le bouton marche et l\'argent reporté est annoncé',
        (tester) async {
      final closes = DateTime.now().add(const Duration(days: 3));
      await pump(tester, {
        ...etat(identity: identite()),
        'balance': {
          'earned': 500,
          'paid': 0,
          'deferred': 200,
          'available': 300
        },
        'window': fenetre(openNow: true, closes: closes),
      });
      const c = WafacashCopyFr();

      expect(find.text(c.windowClosesOn(c.date(closes), 3)), findsOneWidget);
      expect(find.text(c.windowEmergency), findsNothing);
      expect(find.text(c.availableNow), findsOneWidget);
      expect(find.text(c.deferredNote('200 DH', c.date(dansTroisMois))),
          findsOneWidget);

      final bouton = tester.widget<ElevatedButton>(find.ancestor(
        of: find.text(c.cardWithdraw),
        matching: find.byType(ElevatedButton),
      ));
      expect(bouton.onPressed, isNotNull);
    });

    testWidgets('une exception du staff ouvre le bouton hors ouverture',
        (tester) async {
      final until = DateTime(2030, 3, 2, 18, 30);
      await pump(tester, {
        ...etat(identity: identite()),
        'window': fenetre(openNow: true, exception: until),
      });
      const c = WafacashCopyFr();

      expect(find.text(c.exceptionOpen('${c.date(until)}, 18:30')),
          findsOneWidget);
      expect(find.text(c.cardWithdraw), findsOneWidget);
    });

    testWidgets('annuler hors ouverture prévient qu\'il faudra attendre',
        (tester) async {
      await pump(tester, {
        ...etat(identity: identite()),
        'window': fenetre(),
        'withdrawals': [
          {
            'id': 7,
            'status': 'requested',
            'gross_amount': 600,
            'fee_amount': 0,
            'net_amount': 600,
            'legal_name': 'Karim Ouali',
          },
        ],
      });
      const c = WafacashCopyFr();

      await tester.tap(find.text(c.cancel));
      await tester.pumpAndSettle();
      expect(find.text(c.cancelConfirmBodyClosed(c.date(dansTroisMois))),
          findsOneWidget);
    });
  });

  group('l\'annonce aux chargés publics', () {
    const c = WafacashCopyFr();
    final opens = DateTime.now().add(const Duration(days: 4));

    // Pas les vrais jours, exprès : voir le groupe sur l'ouverture du mois.
    Map<String, dynamic> fenetre() => {
          'start_day': 5,
          'end_day': 10,
          'open_now': false,
          'next_opens_at': opens.toIso8601String(),
        };

    Future<SharedPreferences> pump(
      WidgetTester tester,
      Map<String, dynamic> json, {
      Map<String, Object> saved = const {},
    }) async {
      await initializeDateFormatting('fr_FR', null);
      SharedPreferences.setMockInitialValues(saved);
      final prefs = await SharedPreferences.getInstance();
      await tester.binding.setSurfaceSize(const Size(390, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider
              .overrideWith((ref) async => WafacashOverview.fromJson(json)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: WafacashNewsBanner()),
        ),
      ));
      await tester.pumpAndSettle();
      return prefs;
    }

    testWidgets('le bandeau donne les jours, même hors ouverture',
        (tester) async {
      await pump(tester, {...etat(), 'window': fenetre()});
      expect(find.text(c.newsBannerBody(5, 10)), findsOneWidget);
    });

    testWidgets('rien tant que l\'interrupteur général est coupé',
        (tester) async {
      await pump(tester, {...etat(open: false), 'window': fenetre()});
      expect(find.text(c.newsBannerTitle), findsNothing);
    });

    testWidgets('lire le détail ferme le bandeau, pour de bon', (tester) async {
      final prefs = await pump(tester, {...etat(), 'window': fenetre()});

      await tester.tap(find.text(c.newsBannerAction));
      await tester.pumpAndSettle();

      final items = c.newsItems('100 DH', 5, 10);
      expect(find.text(c.newsTitle), findsOneWidget);
      expect(find.text(items[1].title), findsOneWidget);
      expect(find.text('Ouvert du 5 au 10 de chaque mois'), findsOneWidget);

      await tester.tap(find.text(c.newsDone));
      await tester.pumpAndSettle();

      expect(find.text(c.newsBannerTitle), findsNothing);
      expect(prefs.getBool('wafacash_news_v1_seen'), isTrue);
    });

    testWidgets('déjà lue : plus de bandeau', (tester) async {
      await pump(tester, {...etat(), 'window': fenetre()},
          saved: {'wafacash_news_v1_seen': true});
      expect(find.text(c.newsBannerTitle), findsNothing);
    });

    testWidgets('sans fenêtre, le détail ne parle pas de jours',
        (tester) async {
      await pump(tester, etat());

      await tester.tap(find.text(c.newsBannerAction));
      await tester.pumpAndSettle();

      expect(find.textContaining('de chaque mois'), findsNothing);
      expect(find.text(c.newsItems('100 DH', null, null).last.title),
          findsOneWidget);
    });
  });

  group('retraits fermés par l\'interrupteur', () {
    testWidgets('avec de l\'argent sur le solde : on le dit, sans bouton',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider.overrideWith(
              (ref) async => WafacashOverview.fromJson(etat(open: false))),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WafacashSection(onChanged: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      const c = WafacashCopyFr();

      expect(find.text(c.closedNotice), findsOneWidget);
      expect(find.text(c.cardWithdraw), findsNothing);
    });

    testWidgets('sans argent : rien du tout', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider.overrideWith((ref) async =>
              WafacashOverview.fromJson(etat(open: false, available: 0))),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WafacashSection(onChanged: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text(const WafacashCopyFr().cardTitle), findsNothing);
    });
  });

  group('le code prêt', () {
    testWidgets(
        'code par groupes, date limite, et confirmation avant de le '
        'faire disparaître', (tester) async {
      await initializeDateFormatting('fr_FR', null);
      final limite = DateTime.now().add(const Duration(days: 3));
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider
              .overrideWith((ref) async => WafacashOverview.fromJson({
                    ...etat(),
                    'withdrawals': [
                      {
                        'id': 7,
                        'status': 'code_sent',
                        'gross_amount': 600,
                        'fee_amount': 0,
                        'net_amount': 600,
                        'legal_name': 'Karim Ouali',
                        'code': '123456789012',
                        'collect_before': limite.toIso8601String(),
                      },
                    ],
                  })),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WafacashSection(onChanged: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      const c = WafacashCopyFr();

      expect(find.text('123 456 789 012'), findsOneWidget);
      expect(find.textContaining(c.daysLeft(3)), findsOneWidget);
      expect(find.text(c.bringCin('Karim Ouali')), findsOneWidget);

      await tester.tap(find.text(c.iCollected));
      await tester.pumpAndSettle();
      expect(find.text(c.collectedConfirmTitle), findsOneWidget);

      await tester.tap(find.text(c.notYet));
      await tester.pumpAndSettle();
      expect(find.text('123 456 789 012'), findsOneWidget);
    });
  });

  group('la carte, après une annulation du staff', () {
    Future<void> pump(WidgetTester tester, Map<String, dynamic> json) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          stringsProvider.overrideWithValue(const AppStrings(AppLocale.fr)),
          wafacashProvider
              .overrideWith((ref) async => WafacashOverview.fromJson(json)),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WafacashSection(onChanged: () {}),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    Map<String, dynamic> annule({bool open = true}) => etat(
          open: open,
          identity: {
            'status': 'verified',
            'legal_name': 'Karim Ouali',
            'cin_masked': 'AB12••',
          },
          withdrawals: [
            {
              'id': 9,
              'status': 'cancelled',
              'gross_amount': 600,
              'fee_amount': 25,
              'net_amount': 575,
              'legal_name': 'Karim Ouali',
              'closed_reason': 'Solde à vérifier après le tournage',
            },
          ],
        );

    testWidgets('dit pourquoi, et propose de refaire la demande',
        (tester) async {
      await pump(tester, annule());
      const c = WafacashCopyFr();

      expect(
          find.text(c.cancelledByStaff(
              '600 DH', 'Solde à vérifier après le tournage')),
          findsOneWidget);
      expect(find.text(c.requestAgain), findsOneWidget);
    });

    testWidgets('retraits fermés : la raison reste lisible, sans bouton',
        (tester) async {
      await pump(tester, annule(open: false));
      const c = WafacashCopyFr();

      expect(
          find.text(c.cancelledByStaff(
              '600 DH', 'Solde à vérifier après le tournage')),
          findsOneWidget);
      expect(find.text(c.requestAgain), findsNothing);
    });
  });
}
