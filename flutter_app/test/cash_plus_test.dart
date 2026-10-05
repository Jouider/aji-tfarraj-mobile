import 'package:aji_tfarraj/app/push/push_router.dart';
import 'package:aji_tfarraj/features/charge_public/domain/cash_plus.dart';
import 'package:flutter_test/flutter_test.dart';

/// Les retraits Cash Plus côté app.
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
        'fees': [
          {'up_to': 1000, 'fee': 25},
          {'up_to': 500, 'fee': 15}, // désordonné exprès
          {'up_to': 3000, 'fee': 40},
        ],
        'balance': {'earned': 1000, 'paid': 200, 'reserved': 0, 'available': available},
        'identity': identity,
        'withdrawals': withdrawals,
      };

  group('les frais', () {
    final o = CashPlusOverview.fromJson(etat());

    test('le premier palier qui couvre le montant, grille triée', () {
      expect(o.quote(500)!.fee, 15);
      expect(o.quote(501)!.fee, 25);
      expect(o.quote(600)!.net, 575);
    });

    test('au-delà de la grille, pas de devis', () {
      expect(o.quote(3001), isNull);
    });

    test('des frais qui avaleraient le montant ne donnent pas de devis', () {
      expect(o.quote(15), isNull);
      expect(o.quote(0), isNull);
    });
  });

  group('le solde', () {
    test('on ne demande jamais plus que le disponible ni que le maximum', () {
      expect(CashPlusOverview.fromJson(etat(available: 800)).maxRequestable, 800);
      expect(CashPlusOverview.fromJson(etat(available: 9000)).maxRequestable, 3000);
    });

    test('sous le minimum, rien à proposer', () {
      expect(CashPlusOverview.fromJson(etat(available: 80)).hasEnough, isFalse);
      expect(CashPlusOverview.fromJson(etat(available: 100)).hasEnough, isTrue);
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
      final o = CashPlusOverview.fromJson(etat(withdrawals: [
        retrait('code_sent', code: 'CP42'),
        retrait('collected'),
      ]));

      expect(o.current?.status, CashPlusWithdrawalStatus.codeSent);
      expect(o.current?.code, 'CP42');
    });

    test('plus rien en route une fois retiré', () {
      final o = CashPlusOverview.fromJson(etat(withdrawals: [retrait('collected')]));
      expect(o.current, isNull);
    });

    test('annulable seulement tant que le staff ne l\'a pas prise', () {
      expect(CashPlusWithdrawal.fromJson(retrait('requested')).canCancel, isTrue);
      expect(CashPlusWithdrawal.fromJson(retrait('processing')).canCancel, isFalse);
    });

    test('un statut inconnu ne passe pas pour une demande en route', () {
      final w = CashPlusWithdrawal.fromJson(retrait('quelque_chose_de_neuf'));
      expect(w.status, CashPlusWithdrawalStatus.unknown);
      expect(w.status.isOpen, isFalse);
    });
  });

  test('l\'identité arrive masquée et son statut se lit', () {
    final o = CashPlusOverview.fromJson(etat(identity: {
      'status': 'verified',
      'legal_name': 'Karim Ouali',
      'cin_masked': 'AB1234••',
    }));

    expect(o.identity!.isVerified, isTrue);
    expect(o.identity!.cinMasked, 'AB1234••');
  });

  test('un serveur sans Cash Plus laisse la fonction fermée', () {
    final o = CashPlusOverview.fromJson(const {});
    expect(o.open, isFalse);
    expect(o.current, isNull);
  });

  group('le push « ton argent est prêt »', () {
    test('ouvre l\'onglet des gains via le lien profond', () {
      expect(
        PushRouter.getRouteFromData({
          'type': 'cashplus',
          'deep_link': '/charge-public?tab=gains',
        }),
        '/charge-public?tab=gains',
      );
    });

    test('et même sans lien profond', () {
      expect(PushRouter.getRouteFromData({'type': 'cashplus'}),
          '/charge-public?tab=gains');
    });
  });
}
