/// Les retraits Wafacash du chargé public.
///
/// Le chargé public demande un montant ; les frais Wafacash en sont retirés et
/// il voit le NET avant de confirmer. Le staff fait le transfert au guichet et
/// saisit le code ; le chargé public le lit ici et retire l'argent avec sa CIN.
///
/// Vient de `GET /api/me/wafacash`. Le serveur reste juge : le calcul des frais
/// ici sert à l'affichage pendant la saisie, la demande est recalculée là-bas.
library;

/// Un palier de la grille : « jusqu'à [upTo] DH → [fee] DH de frais ».
/// Un palier de la grille, sur le montant ENVOYÉ : des frais fixes [fee], ou un
/// pourcentage [percent] (Wafacash : 0,67 % au-delà de 10 000 DH).
class WafacashFeeBracket {
  final int upTo;
  final int? fee;
  final double? percent;

  const WafacashFeeBracket({required this.upTo, this.fee, this.percent});

  /// Les frais de ce palier pour un montant envoyé, arrondis au dirham
  /// supérieur comme le serveur.
  int feeFor(int sent) => percent != null
      ? ((sent * percent! * 1000000).round() / 1000000 / 100).ceil()
      : fee ?? 0;

  factory WafacashFeeBracket.fromJson(Map<String, dynamic> json) =>
      WafacashFeeBracket(
        upTo: (json['up_to'] as num?)?.toInt() ?? 0,
        fee: (json['fee'] as num?)?.toInt(),
        percent: (json['percent'] as num?)?.toDouble(),
      );
}

/// Ce que coûte une demande et ce qu'on retire au guichet.
class WafacashQuote {
  /// Ce que le chargé public a tapé.
  final int requested;

  /// Ce qui part réellement du solde : envoyé + frais. Peut rester quelques
  /// dirhams sous [requested], au bord d'un palier.
  final int gross;
  final int fee;

  /// Ce qu'il retire au guichet.
  final int net;

  const WafacashQuote({
    required this.requested,
    required this.gross,
    required this.fee,
    required this.net,
  });

  /// Le débit diffère de la demande : il faut le dire avant la confirmation.
  bool get debitDiffers => gross != requested;
}

enum WafacashIdentityStatus {
  pending('pending'),
  verified('verified'),
  rejected('rejected');

  const WafacashIdentityStatus(this.key);
  final String key;

  static WafacashIdentityStatus fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => pending);
}

/// L'identité envoyée pour les retraits, vérifiée une fois par le staff.
class WafacashIdentity {
  final WafacashIdentityStatus status;
  final String legalName;

  /// « AB1234•• » : jamais la CIN entière dans l'app.
  final String cinMasked;
  final String? rejectionReason;
  final DateTime? submittedAt;

  const WafacashIdentity({
    required this.status,
    required this.legalName,
    required this.cinMasked,
    this.rejectionReason,
    this.submittedAt,
  });

  bool get isVerified => status == WafacashIdentityStatus.verified;

  static WafacashIdentity? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return WafacashIdentity(
      status: WafacashIdentityStatus.fromKey(json['status'] as String?),
      legalName: json['legal_name'] as String? ?? '',
      cinMasked: json['cin_masked'] as String? ?? '',
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt:
          DateTime.tryParse(json['submitted_at'] as String? ?? '')?.toLocal(),
    );
  }
}

enum WafacashWithdrawalStatus {
  requested('requested'),
  processing('processing'),
  codeSent('code_sent'),
  collected('collected'),
  rejected('rejected'),
  cancelled('cancelled'),
  expired('expired'),

  /// Un statut que ce build ne connaît pas. Affiché sobrement, jamais deviné.
  unknown('');

  const WafacashWithdrawalStatus(this.key);
  final String key;

  static WafacashWithdrawalStatus fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => unknown);

  /// Encore en route : bloque une nouvelle demande.
  bool get isOpen => this == requested || this == processing || this == codeSent;
}

class WafacashWithdrawal {
  final int id;
  final WafacashWithdrawalStatus status;
  final int grossAmount;
  final int feeAmount;
  final int netAmount;
  final String legalName;

  /// Le code Wafacash — présent seulement tant qu'il sert.
  final String? code;
  final String? closedReason;
  final DateTime? requestedAt;
  final DateTime? codeSentAt;
  final DateTime? collectedAt;
  final DateTime? closedAt;

  const WafacashWithdrawal({
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

  bool get canCancel => status == WafacashWithdrawalStatus.requested;

  factory WafacashWithdrawal.fromJson(Map<String, dynamic> json) {
    DateTime? at(String key) =>
        DateTime.tryParse(json[key] as String? ?? '')?.toLocal();

    return WafacashWithdrawal(
      id: (json['id'] as num).toInt(),
      status: WafacashWithdrawalStatus.fromKey(json['status'] as String?),
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

class WafacashBalance {
  final int earned;
  final int paid;

  /// Bloqué par une demande en cours, pas encore payé.
  final int reserved;
  final int available;

  const WafacashBalance({
    this.earned = 0,
    this.paid = 0,
    this.reserved = 0,
    this.available = 0,
  });

  factory WafacashBalance.fromJson(Object? json) {
    final m = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return WafacashBalance(
      earned: n('earned'),
      paid: n('paid'),
      reserved: n('reserved'),
      available: n('available'),
    );
  }
}

class WafacashOverview {
  /// Le staff a ouvert les retraits ET rempli la grille des frais.
  final bool open;
  final int minAmount;
  final int maxAmount;
  final List<WafacashFeeBracket> fees;
  final WafacashBalance balance;
  final WafacashIdentity? identity;
  final List<WafacashWithdrawal> withdrawals;

  const WafacashOverview({
    this.open = false,
    this.minAmount = 100,
    this.maxAmount = 5000,
    this.fees = const [],
    this.balance = const WafacashBalance(),
    this.identity,
    this.withdrawals = const [],
  });

  /// La demande encore en route, s'il y en a une — une seule à la fois.
  WafacashWithdrawal? get current =>
      withdrawals.where((w) => w.status.isOpen).firstOrNull;

  /// Le plus qu'on puisse demander maintenant.
  int get maxRequestable =>
      balance.available < maxAmount ? balance.available : maxAmount;

  /// Assez pour atteindre le minimum : sinon le bouton n'a pas de sens.
  bool get hasEnough => balance.available >= minAmount;

  /// Les frais Wafacash pour un montant ENVOYÉ, ou null hors de la grille.
  int? feeFor(int sent) {
    final sorted = [...fees]..sort((a, b) => a.upTo.compareTo(b.upTo));
    final palier = sorted.where((b) => sent <= b.upTo).firstOrNull;
    return palier?.feeFor(sent);
  }

  /// La même règle que le serveur : Wafacash facture sur ce qui PART, donc on
  /// cherche le plus grand envoi N tel que N + frais(N) tienne dans la demande.
  ///
  /// Calculer sur la demande surfacturait aux bords : 1 020 DH demandés
  /// tombaient dans le palier à 47 DH alors que les 983 DH envoyés ne coûtent
  /// que 37. Null quand les frais avaleraient tout.
  WafacashQuote? quote(int requested) {
    if (requested <= 0) return null;
    final sorted = [...fees]..sort((a, b) => a.upTo.compareTo(b.upTo));

    int? meilleur;
    var bas = 1;
    for (final b in sorted) {
      int n;
      if (b.percent != null) {
        n = (requested / (1 + b.percent! / 100)).floor();
        if (n > b.upTo) n = b.upTo;
        while (n >= bas && n + b.feeFor(n) > requested) {
          n--;
        }
      } else {
        n = requested - (b.fee ?? 0);
        if (n > b.upTo) n = b.upTo;
      }
      if (n >= bas && n >= 1 && (meilleur == null || n > meilleur)) {
        meilleur = n;
      }
      bas = b.upTo + 1;
    }

    if (meilleur == null) return null;
    final frais = feeFor(meilleur)!;
    return WafacashQuote(
      requested: requested,
      gross: meilleur + frais,
      fee: frais,
      net: meilleur,
    );
  }

  factory WafacashOverview.fromJson(Map<String, dynamic> json) =>
      WafacashOverview(
        open: json['open'] as bool? ?? false,
        minAmount: (json['min_amount'] as num?)?.toInt() ?? 100,
        maxAmount: (json['max_amount'] as num?)?.toInt() ?? 5000,
        fees: (json['fees'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WafacashFeeBracket.fromJson)
            .toList(),
        balance: WafacashBalance.fromJson(json['balance']),
        identity: WafacashIdentity.fromJson(json['identity']),
        withdrawals: (json['withdrawals'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(WafacashWithdrawal.fromJson)
            .toList(),
      );
}
