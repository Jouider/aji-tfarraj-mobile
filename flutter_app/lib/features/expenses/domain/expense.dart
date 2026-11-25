/// Les dépenses de Hamza : `GET /api/me/expenses/*` (règles d'Ayoub, 25/11/2026).
///
/// Hamza saisit, Ayoub valide dans le panneau. Une dépense payée de la caisse
/// en sort dès qu'elle est saisie ; refusée, elle y revient. Le serveur
/// calcule les totaux : l'app les affiche en direct pendant la saisie, mais
/// ne les envoie jamais.
library;

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

DateTime _date(Object? v) =>
    DateTime.tryParse(v as String? ?? '') ?? DateTime(2026, 11, 25);

List<Map<String, dynamic>> _list(Object? v) => (v as List? ?? const [])
    .whereType<Map>()
    .map((e) => Map<String, dynamic>.from(e))
    .toList();

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

/// Les catégories, dans l'ordre des tuiles.
abstract final class ExpenseCategory {
  static const transport = 'transport';
  static const fuel = 'fuel';
  static const vehicle = 'vehicle';
  static const catering = 'catering';
  static const audience = 'audience';
  static const staffDay = 'staff_day';
  static const taxi = 'taxi';
  static const indrive = 'indrive';
  static const other = 'other';

  static const all = [
    catering,
    audience,
    transport,
    fuel,
    taxi,
    indrive,
    vehicle,
    staffDay,
    other,
  ];

  /// Le programme est obligatoire.
  static bool needsEpisode(String c) =>
      c == transport || c == audience || c == staffDay;

  /// Payé avec l'argent de la caisse, sans choix possible.
  static bool alwaysCashBox(String c) => c == catering || c == audience;

  /// Hamza choisit si c'est sorti de la caisse.
  static bool asksCashBox(String c) =>
      c == taxi || c == indrive || c == other || c == vehicle;

  /// Un montant tapé à la main.
  static bool typedAmount(String c) =>
      c == fuel || c == taxi || c == indrive || c == other;
}

abstract final class ExpenseStatus {
  static const pending = 'pending';
  static const validated = 'validated';
  static const refused = 'refused';
}

/// La caisse : remis − rendu − dépensé.
class CashBox {
  const CashBox({
    this.given = 0,
    this.returned = 0,
    this.spent = 0,
    this.spentValidated = 0,
    this.spentPending = 0,
    this.balance = 0,
  });

  final int given;
  final int returned;
  final int spent;
  final int spentValidated;
  final int spentPending;

  /// Négatif : Hamza a avancé de sa poche.
  final int balance;

  factory CashBox.fromJson(Map<String, dynamic> j) => CashBox(
        given: _int(j['given']),
        returned: _int(j['returned']),
        spent: _int(j['spent']),
        spentValidated: _int(j['spent_validated']),
        spentPending: _int(j['spent_pending']),
        balance: _int(j['balance']),
      );
}

/// L'argent remis à la caisse (`deposit`) ou rendu (`return`).
class CashMovement {
  const CashMovement({
    required this.id,
    required this.kind,
    required this.amount,
    required this.date,
    this.note,
    this.by,
  });

  final int id;
  final String kind;
  final int amount;
  final DateTime date;
  final String? note;
  final String? by;

  bool get isDeposit => kind != 'return';

  factory CashMovement.fromJson(Map<String, dynamic> j) => CashMovement(
        id: _int(j['id']),
        kind: j['kind'] as String? ?? 'deposit',
        amount: _int(j['amount']),
        date: _date(j['date']),
        note: j['note'] as String?,
        by: j['by'] as String?,
      );
}

class ExpenseEpisodeRef {
  const ExpenseEpisodeRef({
    required this.id,
    this.title,
    this.show,
    this.date,
  });

  final int id;
  final String? title;
  final String? show;
  final DateTime? date;

  factory ExpenseEpisodeRef.fromJson(Map<String, dynamic> j) =>
      ExpenseEpisodeRef(
        id: _int(j['id']),
        title: j['title'] as String?,
        show: j['show'] as String?,
        date: DateTime.tryParse(j['date'] as String? ?? ''),
      );
}

class ExpensePhoto {
  const ExpensePhoto({required this.id, required this.url, this.isPdf = false});

  final int id;
  final String url;
  final bool isPdf;

  factory ExpensePhoto.fromJson(Map<String, dynamic> j) => ExpensePhoto(
        id: _int(j['id']),
        url: j['url'] as String? ?? '',
        isPdf: j['is_pdf'] as bool? ?? false,
      );
}

/// Une dépense, telle que le serveur la renvoie.
class Expense {
  const Expense({
    required this.id,
    required this.category,
    required this.status,
    required this.spentOn,
    required this.amount,
    required this.paidFrom,
    this.affectsCashBox = false,
    this.summary = '',
    this.episode,
    this.provider,
    this.fields = const {},
    this.staffName,
    this.note,
    this.reviewNote,
    this.reviewedBy,
    this.photos = const [],
    this.editable = true,
  });

  final int id;
  final String category;
  final String status;
  final DateTime spentOn;
  final int amount;

  /// `cash_box` | `company` | `fuel_card` | `app_balance`
  final String paidFrom;
  final bool affectsCashBox;
  final String summary;
  final ExpenseEpisodeRef? episode;
  final String? provider;

  /// Les champs du formulaire, pour corriger la dépense.
  final Map<String, dynamic> fields;
  final String? staffName;
  final String? note;

  /// Le motif d'Ayoub, quand il refuse.
  final String? reviewNote;
  final String? reviewedBy;
  final List<ExpensePhoto> photos;
  final bool editable;

  /// Le motif d'Ayoub entre guillemets, isolé (FSI … PDI) : écrit en
  /// français, il garde son sens de lecture dans l'app en arabe.
  String? get quotedReviewNote =>
      (reviewNote ?? '').isEmpty ? null : '\u2068« $reviewNote »\u2069';

  bool get isPending => status == ExpenseStatus.pending;
  bool get isValidated => status == ExpenseStatus.validated;
  bool get isRefused => status == ExpenseStatus.refused;

  int field(String key) => _int(fields[key]);
  bool flag(String key, {bool fallback = false}) =>
      fields[key] as bool? ?? fallback;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: _int(j['id']),
        category: j['category'] as String? ?? ExpenseCategory.other,
        status: j['status'] as String? ?? ExpenseStatus.pending,
        spentOn: _date(j['spent_on']),
        amount: _int(j['amount']),
        paidFrom: j['paid_from'] as String? ?? 'cash_box',
        affectsCashBox: j['affects_cash_box'] as bool? ?? false,
        summary: j['summary'] as String? ?? '',
        episode: j['episode'] is Map
            ? ExpenseEpisodeRef.fromJson(_map(j['episode']))
            : null,
        provider: j['provider'] as String?,
        fields: _map(j['fields']),
        staffName: _map(j['staff_user'])['name'] as String?,
        note: j['note'] as String?,
        reviewNote: j['review_note'] as String?,
        reviewedBy: j['reviewed_by'] as String?,
        photos: _list(j['photos']).map(ExpensePhoto.fromJson).toList(),
        editable: j['editable'] as bool? ?? true,
      );
}

/// L'écran « Ma caisse » : `GET /api/me/expenses/overview`.
class ExpensesOverview {
  const ExpensesOverview({
    this.cashBox = const CashBox(),
    this.pending = 0,
    this.validated = 0,
    this.refused = 0,
    this.movements = const [],
    this.recent = const [],
  });

  final CashBox cashBox;
  final int pending;
  final int validated;
  final int refused;
  final List<CashMovement> movements;
  final List<Expense> recent;

  factory ExpensesOverview.fromJson(Map<String, dynamic> j) {
    final counts = _map(j['counts']);
    return ExpensesOverview(
      cashBox: CashBox.fromJson(_map(j['cash_box'])),
      pending: _int(counts['pending']),
      validated: _int(counts['validated']),
      refused: _int(counts['refused']),
      movements: _list(j['movements']).map(CashMovement.fromJson).toList(),
      recent: _list(j['recent']).map(Expense.fromJson).toList(),
    );
  }
}

/// Une page de la liste : `GET /api/me/expenses?status=…&page=…`.
class ExpensePage {
  const ExpensePage({this.items = const [], this.page = 1, this.lastPage = 1});

  final List<Expense> items;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;

  factory ExpensePage.fromJson(Map<String, dynamic> j) {
    final meta = _map(j['meta']);
    return ExpensePage(
      items: _list(j['data']).map(Expense.fromJson).toList(),
      page: _int(meta['current_page']) == 0 ? 1 : _int(meta['current_page']),
      lastPage: _int(meta['last_page']) == 0 ? 1 : _int(meta['last_page']),
    );
  }
}

/// Un épisode qu'on peut choisir dans le formulaire.
class ExpenseEpisodeChoice {
  const ExpenseEpisodeChoice({
    required this.id,
    this.title,
    this.show,
    this.date,
    this.time,
    this.paysStaff = true,
    this.dayStaffName,
  });

  final int id;
  final String? title;
  final String? show;
  final DateTime? date;
  final String? time;

  /// Faux : l'émission ne paie pas son staff (Jemaatna Zina).
  final bool paysStaff;

  /// Le staff du jour déjà désigné sur cet épisode.
  final String? dayStaffName;

  factory ExpenseEpisodeChoice.fromJson(Map<String, dynamic> j) =>
      ExpenseEpisodeChoice(
        id: _int(j['id']),
        title: j['title'] as String?,
        show: j['show'] as String?,
        date: DateTime.tryParse(j['date'] as String? ?? ''),
        time: j['time'] as String?,
        paysStaff: j['pays_staff'] as bool? ?? true,
        dayStaffName: _map(j['day_staff'])['name'] as String?,
      );
}

class StaffChoice {
  const StaffChoice({required this.id, required this.name, this.phone});

  final int id;
  final String name;
  final String? phone;

  factory StaffChoice.fromJson(Map<String, dynamic> j) => StaffChoice(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String?,
      );
}

/// Ce que le formulaire propose : `GET /api/me/expenses/form`.
class ExpenseFormOptions {
  const ExpenseFormOptions({
    this.episodes = const [],
    this.staff = const [],
    this.providers = const {},
    this.dayStaffRate = 200,
    this.maxPhotos = 6,
  });

  final List<ExpenseEpisodeChoice> episodes;
  final List<StaffChoice> staff;
  final Map<String, List<String>> providers;
  final int dayStaffRate;
  final int maxPhotos;

  List<String> providersFor(String category) => providers[category] ?? const [];

  ExpenseEpisodeChoice? episode(int? id) {
    if (id == null) return null;
    for (final e in episodes) {
      if (e.id == id) return e;
    }
    return null;
  }

  factory ExpenseFormOptions.fromJson(Map<String, dynamic> j) {
    final providers = <String, List<String>>{};
    _map(j['providers']).forEach((key, value) {
      if (value is List) providers[key] = value.whereType<String>().toList();
    });
    return ExpenseFormOptions(
      episodes:
          _list(j['episodes']).map(ExpenseEpisodeChoice.fromJson).toList(),
      staff: _list(j['staff']).map(StaffChoice.fromJson).toList(),
      providers: providers,
      dayStaffRate:
          _int(j['day_staff_rate']) == 0 ? 200 : _int(j['day_staff_rate']),
      maxPhotos: _int(j['max_photos']) == 0 ? 6 : _int(j['max_photos']),
    );
  }
}

/// Ce que Hamza remplit. Le total affiché se calcule ici comme sur le
/// serveur ; c'est le serveur qui fait foi.
class ExpenseDraft {
  ExpenseDraft({
    required this.category,
    this.episodeId,
    DateTime? spentOn,
    this.note = '',
    this.withTransport = true,
    this.provider = '',
    this.minibuses = 0,
    this.coaches = 0,
    this.amount = 0,
    this.mission = '',
    this.indemnified = false,
    bool? fromCashBox,
    this.sandwiches = 0,
    this.sandwichPrice = 0,
    this.drinks = 0,
    this.paidPeople = 0,
    this.pricePerPerson = 0,
    this.freePeople = 0,
    this.staffUserId,
  })  : spentOn = spentOn ?? DateTime.now(),
        fromCashBox = fromCashBox ?? category != ExpenseCategory.vehicle;

  /// Pour corriger une dépense : le formulaire repart de ce qui a été saisi.
  factory ExpenseDraft.fromExpense(Expense e) => ExpenseDraft(
        category: e.category,
        episodeId: e.episode?.id,
        spentOn: e.spentOn,
        note: e.note ?? '',
        withTransport: e.flag('with_transport', fallback: true),
        provider: e.provider ?? '',
        minibuses: e.field('minibuses'),
        coaches: e.field('coaches'),
        amount: e.amount,
        mission: e.fields['mission'] as String? ?? '',
        indemnified: e.flag('indemnified'),
        fromCashBox: e.flag('from_cash_box'),
        sandwiches: e.field('sandwiches'),
        sandwichPrice: e.field('sandwich_price'),
        drinks: e.field('drinks'),
        paidPeople: e.field('paid_people'),
        pricePerPerson: e.field('price_per_person'),
        freePeople: e.field('free_people'),
        staffUserId: (e.fields['staff_user_id'] as num?)?.toInt(),
      );

  final String category;
  int? episodeId;
  DateTime spentOn;
  String note;
  bool withTransport;
  String provider;
  int minibuses;
  int coaches;
  int amount;
  String mission;
  bool indemnified;
  bool fromCashBox;
  int sandwiches;
  int sandwichPrice;
  int drinks;
  int paidPeople;
  int pricePerPerson;
  int freePeople;
  int? staffUserId;

  /// Le total, comme le serveur le calculera.
  int total({int dayStaffRate = 200}) => switch (category) {
        ExpenseCategory.catering => sandwiches * sandwichPrice + drinks,
        ExpenseCategory.audience => paidPeople * pricePerPerson,
        ExpenseCategory.staffDay => dayStaffRate,
        ExpenseCategory.transport => withTransport ? amount : 0,
        ExpenseCategory.vehicle => indemnified ? amount : 0,
        _ => amount,
      };

  /// Cette dépense sortira de la caisse.
  bool get takesFromCashBox {
    if (ExpenseCategory.alwaysCashBox(category)) return true;
    if (category == ExpenseCategory.vehicle) return indemnified && fromCashBox;
    if (ExpenseCategory.asksCashBox(category)) return fromCashBox;
    return false;
  }

  /// Ce qui manque, dans l'ordre du formulaire ; vide : prêt à envoyer.
  List<String> missing() {
    final m = <String>[];
    if (ExpenseCategory.needsEpisode(category) && episodeId == null) {
      m.add('episode');
    }
    switch (category) {
      case ExpenseCategory.transport:
        if (withTransport && provider.trim().isEmpty) m.add('provider');
        if (withTransport && minibuses + coaches == 0) m.add('vehicles');
      case ExpenseCategory.catering:
        if (provider.trim().isEmpty) m.add('provider');
        if (total() == 0) m.add('catering');
      case ExpenseCategory.audience:
        if (paidPeople + freePeople == 0) m.add('people');
        if (paidPeople > 0 && pricePerPerson == 0) m.add('price');
      case ExpenseCategory.staffDay:
        if (staffUserId == null) m.add('staff');
      case ExpenseCategory.vehicle:
        if (episodeId == null && mission.trim().isEmpty) m.add('mission');
        if (indemnified && amount == 0) m.add('amount');
      case ExpenseCategory.other:
        if (amount == 0) m.add('amount');
        if (note.trim().isEmpty) m.add('note');
      default:
        if (amount == 0) m.add('amount');
    }
    return m;
  }

  String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Les champs envoyés au serveur (multipart). Les booléens en 1 / 0 : le
  /// multipart n'a pas de vrai booléen.
  Map<String, dynamic> toFields() {
    final f = <String, dynamic>{
      'category': category,
      'spent_on': _day(spentOn),
      if (episodeId != null) 'episode_id': episodeId,
      if (note.trim().isNotEmpty) 'note': note.trim(),
    };
    switch (category) {
      case ExpenseCategory.transport:
        f['with_transport'] = withTransport ? 1 : 0;
        if (withTransport) {
          f['provider'] = provider.trim();
          f['minibuses'] = minibuses;
          f['coaches'] = coaches;
          if (amount > 0) f['amount'] = amount;
        }
      case ExpenseCategory.catering:
        f['provider'] = provider.trim();
        f['sandwiches'] = sandwiches;
        f['sandwich_price'] = sandwichPrice;
        f['drinks'] = drinks;
      case ExpenseCategory.audience:
        f['paid_people'] = paidPeople;
        f['price_per_person'] = pricePerPerson;
        f['free_people'] = freePeople;
      case ExpenseCategory.staffDay:
        f['staff_user_id'] = staffUserId;
      case ExpenseCategory.vehicle:
        f['indemnified'] = indemnified ? 1 : 0;
        f['from_cash_box'] = fromCashBox ? 1 : 0;
        if (mission.trim().isNotEmpty) f['mission'] = mission.trim();
        if (indemnified) f['amount'] = amount;
      case ExpenseCategory.fuel:
        f['amount'] = amount;
      default:
        f['amount'] = amount;
        f['from_cash_box'] = fromCashBox ? 1 : 0;
    }
    return f;
  }
}
