/// Les retraits Cash Plus du chargé public.
///
/// Le chargé public demande un montant ; les frais Cash Plus en sont retirés et
/// il voit le NET avant de confirmer. Le staff fait le transfert au guichet et
/// saisit le code ; le chargé public le lit ici et retire l'argent avec sa CIN.
///
/// Vient de `GET /api/me/cashplus`. Le serveur reste juge : le calcul des frais
/// ici sert à l'affichage pendant la saisie, la demande est recalculée là-bas.
library;

/// Un palier de la grille : « jusqu'à [upTo] DH → [fee] DH de frais ».
class CashPlusFeeBracket {
  final int upTo;
  final int fee;

  const CashPlusFeeBracket({required this.upTo, required this.fee});

  factory CashPlusFeeBracket.fromJson(Map<String, dynamic> json) =>
      CashPlusFeeBracket(
        upTo: (json['up_to'] as num?)?.toInt() ?? 0,
        fee: (json['fee'] as num?)?.toInt() ?? 0,
      );
}

/// Ce que coûte une demande et ce qu'on retire au guichet.
class CashPlusQuote {
  final int gross;
  final int fee;
  final int net;

  const CashPlusQuote({required this.gross, required this.fee, required this.net});
}

enum CashPlusIdentityStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const CashPlusIdentityStatus(this.key);
  final String key;

  static CashPlusIdentityStatus fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => pending);
}

/// L'identité envoyée pour les retraits, vérifiée une fois par le staff.
class CashPlusIdentity {
  final CashPlusIdentityStatus status;
  final String legalName;

  /// « AB1234•• » : jamais la CIN entière dans l'app.
  final String cinMasked;
  final String? rejectionReason;
  final DateTime? submittedAt;

  const CashPlusIdentity({
    required this.status,
    required this.legalName,
    required this.cinMasked,
    this.rejectionReason,
    this.submittedAt,
  });

  bool get isVerified => status == CashPlusIdentityStatus.verified;

  static CashPlusIdentity? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return CashPlusIdentity(
      status: CashPlusIdentityStatus.fromKey(json['status'] as String?),
      legalName: json['legal_name'] as String? ?? '',
      cinMasked: json['cin_masked'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt:
          DateTime.tryParse(json['submitted_at'] as String? ?? '')?.toLocal(),
    );
  }
}

enum CashPlusWithdrawalStatus {
  requested('requested'),
  processing('processing'),
  codeSent('code_sent'),
  collected('collected'),
  rejected('rejected'),
  cancelled('cancelled'),
  expired('expired'),

  /// Un statut que ce build ne connaît pas. Affiché sobrement, jamais deviné.
  unknown('');

  const CashPlusWithdrawalStatus(this.key);
  final String key;

  static CashPlusWithdrawalStatus fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => unknown);

  /// Encore en route : bloque une nouvelle demande.
  bool get isOpen => this == requested || this == processing || this == codeSent;
}

class CashPlusWithdrawal {
  final int id;
  final CashPlusWithdrawalStatus status;
  final int grossAmount;
  final int feeAmount;
  final int netAmount;
  final String legalName;

  /// Le code Cash Plus — présent seulement tant qu'il sert.
  final String? code;
  final String? closedReason;
  final DateTime? requestedAt;
  final DateTime? codeSentAt;
  final DateTime? collectedAt;
  final DateTime? closedAt;

  const CashPlusWithdrawal({
    required this.id,
    required this.status,
    required this.grossAmount,
    required this.feeAmount,
    required this.netAmount,
    required this.legalName,
    this.code,
    this.closedReason,
    this.requestedAt,
    this.codeSentAt,
    this.collectedAt,
    this.closedAt,
  });

  bool get canCancel => status == CashPlusWithdrawalStatus.requested;

  factory CashPlusWithdrawal.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) =>
        DateTime.tryParse(json[key] as String? ?? '')?.toLocal();

    return CashPlusWithdrawal(
      id: (json['id'] as num).toInt(),
      status: CashPlusWithdrawalStatus.fromKey(json['status'] as String?),
      grossAmount: (json['gross_amount'] as num?)?.toInt() ?? 0,
      feeAmount: (json['fee_amount'] as num?)?.toInt() ?? 0,
      netAmount: (json['net_amount'] as num?)?.toInt() ?? 0,
      legalName: json['legal_name'] as String? ?? '',
      code: json['code'] as String?,
      closedReason: json['closed_reason'] as String?,
      requestedAt: at('requested_at'),
      codeSentAt: at('code_sent_at'),
      collectedAt: at('collected_at'),
      closedAt: at('closed_at'),
    );
  }
}

class CashPlusBalance {
  final int earned;
  final int paid;

  /// Bloqué par une demande en cours, pas encore payé.
  final int reserved;
  final int available;

  const CashPlusBalance({
    this.earned = 0,
    this.paid = 0,
    this.reserved = 0,
    this.available = 0,
  });

  factory CashPlusBalance.fromJson(Object? json) {
    final m = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return CashPlusBalance(
      earned: n('earned'),
      paid: n('paid'),
      reserved: n('reserved'),
      available: n('available'),
    );
  }
}

class CashPlusOverview {
  /// Le staff a ouvert les retraits ET rempli la grille des frais.
  final bool open;
  final int minAmount;
  final int maxAmount;
  final List<CashPlusFeeBracket> fees;
  final CashPlusBalance balance;
  final CashPlusIdentity? identity;
  final List<CashPlusWithdrawal> withdrawals;

  const CashPlusOverview({
    this.open = false,
    this.minAmount = 100,
    this.maxAmount = 5000,
    this.fees = const [],
    this.balance = const CashPlusBalance(),
    this.identity,
    this.withdrawals = const [],
  });

  /// La demande encore en route, s'il y en a une — une seule à la fois.
  CashPlusWithdrawal? get current =>
      withdrawals.where((w) => w.status.isOpen).firstOrNull;

  /// Le plus qu'on puisse demander maintenant.
  int get maxRequestable =>
      balance.available < maxAmount ? balance.available : maxAmount;

  /// Assez pour atteindre le minimum : sinon le bouton n'a pas de sens.
  bool get hasEnough => balance.available >= minAmount;

  /// Même règle que le serveur : le premier palier qui couvre le montant.
  /// Null quand le montant dépasse la grille, ou que les frais l'avaleraient.
  CashPlusQuote? quote(int gross) {
    if (gross <= 0) return null;
    final sorted = [...fees]..sort((a, b) => a.upTo.compareTo(b.upTo));
    final palier = sorted.where((b) => gross <= b.upTo).firstOrNull;
    if (palier == null || palier.fee >= gross) return null;
    return CashPlusQuote(gross: gross, fee: palier.fee, net: gross - palier.fee);
  }

  factory CashPlusOverview.fromJson(Map<String, dynamic> json) =>
      CashPlusOverview(
        open: json['open'] as bool? ?? false,
        minAmount: (json['min_amount'] as num?)?.toInt() ?? 100,
        maxAmount: (json['max_amount'] as num?)?.toInt() ?? 5000,
        fees: (json['fees'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CashPlusFeeBracket.fromJson)
            .toList(),
        balance: CashPlusBalance.fromJson(json['balance']),
        identity: CashPlusIdentity.fromJson(json['identity']),
        withdrawals: (json['withdrawals'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(CashPlusWithdrawal.fromJson)
            .toList(),
      );
}
