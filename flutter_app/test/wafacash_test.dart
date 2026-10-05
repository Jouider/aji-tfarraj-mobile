import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les retraits Wafacash côté app.
///
/// Le calcul des frais ici ne sert qu'à l'affichage pendant la saisie — le
/// serveur recalcule — mais il doit donner le MÊME net : c'est ce chiffre que
/// le chargé public lit avant de confirmer.
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
        'balance': {'earned': 1000, 'paid': 200, 'reserved': 0, 'available': available},
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

    test('1 020 demandés : 983 envoyés, 37 de frais — pas 47', () {
      final q = o.quote(1020)!;
      expect([q.net, q.fee, q.gross], [983, 37, 1020]);
      expect(q.debitDiffers, isFalse);
    });

    test('au bord d\'un palier, on ne débite que ce qui sert', () {
      final q = o.quote(1040)!;
      expect([q.net, q.fee, q.gross], [1000, 37, 1037]);
      expect(q.debitDiffers, isTrue);
    });

    test('passé le bord, le palier suivant', () {
      final q = o.quote(1050)!;
      expect([q.net, q.fee], [1003, 47]);
    });

    test('le palier en pourcentage', () {
      final q = o.quote(12000)!;
      expect([q.net, q.fee, q.gross], [11920, 80, 12000]);
    });

    test('des frais qui avaleraient tout ne donnent pas de devis', () {
      expect(o.quote(30), isNull);
      expect(o.quote(0), isNull);
    });
  });

  group('le solde', () {
    test('on ne demande jamais plus que le disponible ni que le maximum', () {
      expect(WafacashOverview.fromJson(etat(available: 800)).maxRequestable, 800);
      expect(WafacashOverview.fromJson(etat(available: 9000)).maxRequestable, 3000);
    });

    test('sous le minimum, rien à proposer', () {
      expect(WafacashOverview.fromJson(etat(available: 80)).hasEnough, isFalse);
      expect(WafacashOverview.fromJson(etat(available: 100)).hasEnough, isTrue);
    });
  });

  group('une demande', () {
    Map<String, dynamic> retrait(String status, {String? code}) => {
          'id': 7,
          'status': status,
          'gross_amount': 600,
          'fee_amount': 25,
          'net_amount': 575,
          'legal_name': 'Karim Ouali',
          'code': code,
          'requested_at': '2026-10-05T10:00:00Z',
        };

    test('la demande en route est retrouvée, les closes non', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [
        retrait('code_sent', code: 'CP42'),
        retrait('collected'),
      ]));

      expect(o.current?.status, WafacashWithdrawalStatus.codeSent);
      expect(o.current?.code, 'CP42');
    });

    test('plus rien en route une fois retiré', () {
      final o = WafacashOverview.fromJson(etat(withdrawals: [retrait('collected')]));
      expect(o.current, isNull);
    });

    test('annulable seulement tant que le staff ne l\'a pas prise', () {
      expect(WafacashWithdrawal.fromJson(retrait('requested')).canCancel, isTrue);
      expect(WafacashWithdrawal.fromJson(retrait('processing')).canCancel, isFalse);
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
}
