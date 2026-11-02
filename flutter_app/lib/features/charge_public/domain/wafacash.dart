/// Les retraits Wafacash du chargé public.
///
/// Le chargé public demande un montant et c'est ce montant exact que Wafacash
/// transfère : l'agence prend ses frais au guichet, quand il retire. L'équipe
/// fait le transfert et saisit le code ; le chargé public le lit ici et retire
/// l'argent avec sa CIN.
///
/// Vient de `GET /api/me/wafacash`. Le serveur reste juge : les contrôles d'ici
/// servent à guider la saisie, la demande est revérifiée là-bas.
library;

/// Un palier de la grille : des frais fixes [fee], ou un pourcentage [percent]
/// (Wafacash : 0,67 % au-delà de 10 000 DH).
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
  bool get isOpen =>
      this == requested || this == processing || this == codeSent;
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

  /// Jusqu'à quand le code se retire chez Wafacash. Après, l'argent revient sur
  /// le solde. Envoyé seulement tant que le code sert.
  final DateTime? collectBefore;
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
    this.collectBefore,
    this.collectedAt,
    this.closedAt,
  });

  bool get canCancel => status == WafacashWithdrawalStatus.requested;

  /// Le code par groupes de trois, comme il se dicte au guichet :
  /// `123 456 789 012`.
  String? get formattedCode {
    final raw = code;
    if (raw == null) return null;
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && i % 3 == 0) buffer.write(' ');
      buffer.write(raw[i]);
    }
    return buffer.toString();
  }

  /// Les jours pleins qu'il reste pour retirer : 0 le dernier jour, négatif une
  /// fois la date passée. Null si le serveur ne donne pas de date.
  int? daysLeft(DateTime now) {
    final limit = collectBefore;
    if (limit == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(limit.year, limit.month, limit.day);
    return last.difference(today).inDays;
  }

  /// Ce que le serveur écrit quand le chargé public annule lui-même.
  static const _cancelledByCp = 'Annulé par le chargé public';

  /// Annulée par le staff (solde à vérifier après un tournage) : ce n'est pas
  /// un refus, le chargé public refait sa demande sur le solde corrigé.
  bool get cancelledByStaff =>
      status == WafacashWithdrawalStatus.cancelled &&
      (closedReason ?? '').trim().isNotEmpty &&
      closedReason!.trim() != _cancelledByCp;

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
      collectBefore: at('collect_before'),
      collectedAt: at('collected_at'),
      closedAt: at('closed_at'),
    );
  }
}

/// Les jours du mois où une demande est possible, bornes comprises. Réglés dans
/// le panneau : l'app lit ce que dit le serveur, elle n'écrit aucune date en dur.
class WafacashWindow {
  final int startDay;
  final int endDay;

  /// Une demande passe maintenant : jour d'ouverture, ou exception en cours.
  final bool openNow;

  /// Le dernier jour de l'ouverture en cours ; null hors ouverture.
  final DateTime? closesAt;

  /// Le prochain premier jour d'ouverture.
  final DateTime? nextOpensAt;

  /// Une exception accordée par le staff, pour une urgence : une demande,
  /// jusqu'à cette date.
  final DateTime? exceptionUntil;

  const WafacashWindow({
    required this.startDay,
    required this.endDay,
    required this.openNow,
    this.closesAt,
    this.nextOpensAt,
    this.exceptionUntil,
  });

  /// Les jours de calendrier entre [now] et [day].
  static int daysUntil(DateTime day, DateTime now) =>
      DateTime(day.year, day.month, day.day)
          .difference(DateTime(now.year, now.month, now.day))
          .inDays;

  static WafacashWindow? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    DateTime? at(String key) =>
        DateTime.tryParse(json[key] as String? ?? '')?.toLocal();

    final start = (json['start_day'] as num?)?.toInt();
    final end = (json['end_day'] as num?)?.toInt();
    if (start == null || end == null) return null;

    return WafacashWindow(
      startDay: start,
      endDay: end,
      openNow: json['open_now'] as bool? ?? false,
      closesAt: at('closes_at'),
      nextOpensAt: at('next_opens_at'),
      exceptionUntil: at('exception_until'),
    );
  }
}

class WafacashBalance {
  final int earned;
  final int paid;

  /// Bloqué par une demande en cours, pas encore payé.
  final int reserved;

  /// Gagné sur un tournage fini depuis moins de 24 h : compté dans le solde,
  /// pas encore retirable, le temps de revoir les présences du soir.
  final int held;

  /// Gagné sur un tournage fait pendant l'ouverture en cours : se retire à
  /// l'ouverture suivante.
  final int deferred;
  final int available;

  const WafacashBalance({
    this.earned = 0,
    this.paid = 0,
    this.reserved = 0,
    this.held = 0,
    this.deferred = 0,
    this.available = 0,
  });

  factory WafacashBalance.fromJson(Object? json) {
    final m = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return WafacashBalance(
      earned: n('earned'),
      paid: n('paid'),
      reserved: n('reserved'),
      held: n('held'),
      deferred: n('deferred'),
      available: n('available'),
    );
  }
}

class WafacashOverview {
  /// L'interrupteur général : le staff a ouvert les retraits ET rempli la
  /// grille des frais. Les jours du mois sont dans [window].
  final bool open;

  /// Null : pas de fenêtre, ou serveur plus ancien. Les retraits sont alors
  /// ouverts tout le mois.
  final WafacashWindow? window;
  final int minAmount;
  final int maxAmount;
  final List<WafacashFeeBracket> fees;
  final WafacashBalance balance;
  final WafacashIdentity? identity;
  final List<WafacashWithdrawal> withdrawals;

  const WafacashOverview({
    this.open = false,
    this.window,
    this.minAmount = 50,
    this.maxAmount = 5000,
    this.fees = const [],
    this.balance = const WafacashBalance(),
    this.identity,
    this.withdrawals = const [],
  });

  /// La demande encore en route, s'il y en a une — une seule à la fois.
  WafacashWithdrawal? get current =>
      withdrawals.where((w) => w.status.isOpen).firstOrNull;

  /// La dernière demande, quand le staff l'a annulée et qu'aucune autre n'a
  /// suivi : sa raison s'affiche avec « Refaire une demande ».
  WafacashWithdrawal? get lastCancelledByStaff {
    final last = withdrawals.firstOrNull;
    return last != null && last.cancelledByStaff ? last : null;
  }

  /// Une demande passerait maintenant, côté calendrier.
  bool get canRequestNow => open && (window?.openNow ?? true);

  /// Le plus qu'on puisse demander maintenant.
  int get maxRequestable =>
      balance.available < maxAmount ? balance.available : maxAmount;

  /// Assez pour atteindre le minimum : sinon le bouton n'a pas de sens.
  bool get hasEnough => balance.available >= minAmount;

  /// Ce qu'il manque au disponible pour atteindre le minimum.
  int get missingForMin => hasEnough
      ? 0
      : minAmount - (balance.available < 0 ? 0 : balance.available);

  /// Les frais Wafacash pour un montant envoyé, ou null hors de la grille.
  int? feeFor(int sent) {
    final sorted = [...fees]..sort((a, b) => a.upTo.compareTo(b.upTo));
    final palier = sorted.where((b) => sent <= b.upTo).firstOrNull;
    return palier?.feeFor(sent);
  }

  /// La même règle que le serveur : le montant doit au moins couvrir les frais
  /// de l'agence, sinon il n'y aurait rien à retirer.
  bool covers(int amount) {
    final fee = feeFor(amount);
    return fee != null && fee < amount;
  }

  /// Les frais mangent au moins un cinquième du montant : ça vaut la peine de
  /// le dire, sans chiffrer ce qui reste le tarif de Wafacash.
  bool feesWeighHeavy(int amount) {
    final fee = feeFor(amount);
    return fee != null && fee < amount && fee * 5 >= amount;
  }

  factory WafacashOverview.fromJson(Map<String, dynamic> json) =>
      WafacashOverview(
        open: json['open'] as bool? ?? false,
        window: WafacashWindow.fromJson(json['window']),
        minAmount: (json['min_amount'] as num?)?.toInt() ?? 50,
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
