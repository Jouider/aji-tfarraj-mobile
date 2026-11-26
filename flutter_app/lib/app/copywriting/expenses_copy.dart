/// Copy for « Ma caisse » — Hamza's expenses and cash box.
///
/// A contract, so French and Arabic cannot drift apart. Addressed with « tu »,
/// like the rest of the staff space. Short words, big buttons: Hamza fills
/// this in on his phone, on set.
abstract class ExpensesCopy {
  String money(int amount);

  String get title;
  String get profileCardTitle;
  String get profileCardSubtitle;

  // ── La caisse ──
  String get balanceLabel;
  String advancedNote(String amount);
  String get given;
  String get spent;
  String get returned;
  String pendingSpent(String amount);
  String get newExpense;
  String get chooseCategory;
  String get moneyReceived;
  String movement(bool deposit);
  String get noMovement;

  // ── Les catégories ──
  String category(String code);
  String categoryHint(String code);

  // ── Les états ──
  String status(String code);
  String statusPlural(String code, int n);
  String get refusedBanner;
  String refusedBy(String? name);
  String get fix;
  String get emptyList;

  // ── Le formulaire ──
  String get programme;
  String get chooseProgramme;
  String get noProgramme;
  String get searchProgramme;
  String get date;
  String get provider;
  String get providerHint;
  String get withTransport;
  String get withoutTransport;
  String get minibuses;
  String get coaches;
  String get transportAmount;
  String get transportPaidBy;
  String get fuelPaidBy;
  String get amount;
  String get mission;
  String get missionHint;
  String get withIndemnity;
  String get withoutIndemnity;
  String get indemnity;
  String get sandwiches;
  String get sandwichPrice;
  String get drinks;
  String get paidPublic;
  String get freePublic;
  String get paidPeople;
  String get pricePerPerson;
  String get freePeople;
  String get staffPerson;
  String get chooseStaff;
  String dayStaffNote(String amount);
  String dayStaffTaken(String name);
  String get dayStaffNoEpisode;
  String get fromCashBox;
  String get fromCashBoxYes;
  String get fromCashBoxNo;
  String get note;
  String get noteRequired;
  String get total;
  String get totalFromCashBox;
  String get totalNotFromCashBox;
  String get totalToBalance;
  String get receipts;
  String receiptsHint(int max);
  String get camera;
  String get gallery;
  String get save;
  String get saveChanges;
  String get delete;
  String get deleteConfirm;
  String get cancel;
  String get saved;
  String get resubmitted;
  String get deleted;
  String get addAnotherProvider;
  String get addAnotherProviderBody;
  String get yes;
  String get no;
  String get locked;

  /// Ce qui manque, en une phrase, pour chaque clé de ExpenseDraft.missing().
  String missing(String key);

  String day(DateTime d);
  String get loadError;
  String get retry;
}

const _moisFr = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

const _moisAr = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'ماي',
  'يونيو',
  'يوليوز',
  'غشت',
  'شتنبر',
  'أكتوبر',
  'نونبر',
  'دجنبر',
];

class ExpensesCopyFr implements ExpensesCopy {
  const ExpensesCopyFr();

  @override
  String money(int amount) => '$amount DH';

  @override
  String get title => 'Ma caisse';
  @override
  String get profileCardTitle => 'Ma caisse et mes dépenses';
  @override
  String get profileCardSubtitle =>
      'L\'argent remis par Ayoub, et chaque dépense des tournages.';

  @override
  String get balanceLabel => 'Dans ta caisse';
  @override
  String advancedNote(String amount) => 'Tu as avancé $amount de ta poche.';
  @override
  String get given => 'Reçu';
  @override
  String get spent => 'Dépensé';
  @override
  String get returned => 'Rendu';
  @override
  String pendingSpent(String amount) => 'dont $amount en attente de validation';
  @override
  String get newExpense => 'Nouvelle dépense';
  @override
  String get chooseCategory => 'Qu\'as-tu payé ?';
  @override
  String get moneyReceived => 'Argent reçu';
  @override
  String movement(bool deposit) => deposit ? 'Remis par' : 'Rendu à';
  @override
  String get noMovement => 'Pas encore d\'argent reçu.';

  @override
  String category(String code) => switch (code) {
        'transport' => 'Transport du public',
        'fuel' => 'Gasoil',
        'vehicle' => 'Ma voiture',
        'catering' => 'Restauration',
        'audience' => 'Public payé',
        'staff_day' => 'Staff payé du jour',
        'taxi' => 'Taxi',
        'indrive' => 'InDrive',
        'other' => 'Autre dépense',
        _ => code,
      };

  @override
  String categoryHint(String code) => switch (code) {
        'transport' => 'Minibus, autocars · payé par la société',
        'fuel' => 'Carte Afriquia',
        'vehicle' => 'Voiture personnelle',
        'catering' => 'Sandwichs, eau, boissons',
        'audience' => 'Figuration, gratuit ou payé',
        'staff_day' => 'Jemaatna Zina · 200 DH',
        'taxi' => 'Course en taxi',
        'indrive' => 'Course InDrive',
        'other' => 'Tout le reste',
        _ => '',
      };

  @override
  String status(String code) => switch (code) {
        'pending' => 'En attente',
        'validated' => 'Validée',
        'refused' => 'Refusée',
        _ => code,
      };
  @override
  String statusPlural(String code, int n) => switch (code) {
        'pending' => 'En attente ($n)',
        'validated' => 'Validées ($n)',
        'refused' => 'Refusées ($n)',
        _ => '$code ($n)',
      };
  @override
  String get refusedBanner => 'À corriger : Ayoub a refusé ces dépenses.';
  @override
  String refusedBy(String? name) =>
      name == null ? 'Refusée' : 'Refusée par $name';
  @override
  String get fix => 'Corriger';
  @override
  String get emptyList => 'Rien ici pour l\'instant.';

  @override
  String get programme => 'Programme';
  @override
  String get chooseProgramme => 'Choisir le programme';
  @override
  String get noProgramme => 'Hors programme (dépense générale)';
  @override
  String get searchProgramme => 'Chercher un programme';
  @override
  String get date => 'Date';
  @override
  String get provider => 'Prestataire';
  @override
  String get providerHint => 'Nom du prestataire';
  @override
  String get withTransport => 'Avec transport';
  @override
  String get withoutTransport => 'Sans transport';
  @override
  String get minibuses => 'Minibus';
  @override
  String get coaches => 'Autocars';
  @override
  String get transportAmount => 'Montant (si tu le connais)';
  @override
  String get transportPaidBy =>
      'Payé directement par la société : ta caisse ne bouge pas.';
  @override
  String get fuelPaidBy =>
      'Payé avec la carte Afriquia : ta caisse ne bouge pas.';
  @override
  String get amount => 'Montant';
  @override
  String get mission => 'Mission';
  @override
  String get missionHint => 'Ex : aller chercher le matériel';
  @override
  String get withIndemnity => 'Avec indemnisation';
  @override
  String get withoutIndemnity => 'Sans indemnisation';
  @override
  String get indemnity => 'Montant de l\'indemnité';
  @override
  String get sandwiches => 'Sandwichs';
  @override
  String get sandwichPrice => 'Prix d\'un sandwich';
  @override
  String get drinks => 'Eau et boissons';
  @override
  String get paidPublic => 'Public payé';
  @override
  String get freePublic => 'Public gratuit';
  @override
  String get paidPeople => 'Personnes payées';
  @override
  String get pricePerPerson => 'Montant par personne';
  @override
  String get freePeople => 'Personnes gratuites';
  @override
  String get staffPerson => 'Personne du staff';
  @override
  String get chooseStaff => 'Choisir la personne';
  @override
  String dayStaffNote(String amount) =>
      'Sur cette émission, le staff n\'est pas payé : la personne choisie reçoit $amount dans sa paie, après validation d\'Ayoub.';
  @override
  String dayStaffTaken(String name) => 'Déjà désigné : $name.';
  @override
  String get dayStaffNoEpisode =>
      'Aucun programme récent sans paie du staff (Jemaatna Zina).';
  @override
  String get fromCashBox => 'Payé avec l\'argent de la caisse ?';
  @override
  String get fromCashBoxYes => 'Oui, la caisse';
  @override
  String get fromCashBoxNo => 'Non';
  @override
  String get note => 'Note';
  @override
  String get noteRequired => 'Qu\'as-tu acheté ?';
  @override
  String get total => 'Total';
  @override
  String get totalFromCashBox => 'Sort de ta caisse';
  @override
  String get totalNotFromCashBox => 'Ne touche pas ta caisse';
  @override
  String get totalToBalance => 'Ajouté à sa paie dans l\'app';
  @override
  String get receipts => 'Factures et reçus';
  @override
  String receiptsHint(int max) => 'Prends une photo du reçu ($max au plus).';
  @override
  String get camera => 'Photo';
  @override
  String get gallery => 'Galerie';
  @override
  String get save => 'Enregistrer';
  @override
  String get saveChanges => 'Renvoyer à Ayoub';
  @override
  String get delete => 'Supprimer';
  @override
  String get deleteConfirm =>
      'Supprimer cette dépense ? Son montant revient dans ta caisse.';
  @override
  String get cancel => 'Annuler';
  @override
  String get saved => 'Enregistrée. Ayoub va la valider.';
  @override
  String get resubmitted => 'Corrigée et renvoyée à Ayoub.';
  @override
  String get deleted => 'Dépense supprimée.';
  @override
  String get addAnotherProvider => 'Un autre prestataire ?';
  @override
  String get addAnotherProviderBody =>
      'Ajouter un autre prestataire de transport pour ce programme ?';
  @override
  String get yes => 'Oui';
  @override
  String get no => 'Non';
  @override
  String get locked => 'Validée par Ayoub : elle ne se modifie plus.';

  @override
  String missing(String key) => switch (key) {
        'episode' => 'Choisis le programme.',
        'provider' => 'Indique le prestataire.',
        'vehicles' => 'Indique le nombre de minibus ou d\'autocars.',
        'catering' =>
          'Indique les sandwichs et leur prix, ou l\'eau et les boissons.',
        'people' => 'Indique le public payé ou le public gratuit.',
        'price' => 'Indique le montant par personne.',
        'staff' => 'Choisis la personne du staff.',
        'mission' => 'Indique le programme ou la mission.',
        'note' => 'Écris ce que tu as acheté.',
        _ => 'Indique le montant.',
      };

  @override
  String day(DateTime d) => '${d.day} ${_moisFr[d.month - 1]} ${d.year}';
  @override
  String get loadError => 'Impossible de charger ta caisse.';
  @override
  String get retry => 'Réessayer';
}

class ExpensesCopyAr implements ExpensesCopy {
  const ExpensesCopyAr();

  @override
  String money(int amount) => '$amount درهم';

  @override
  String get title => 'صندوقي';
  @override
  String get profileCardTitle => 'الصندوق والمصاريف';
  @override
  String get profileCardSubtitle =>
      'الفلوس اللي سلمها أيوب، وكل مصاريف التصوير.';

  @override
  String get balanceLabel => 'في صندوقك';
  @override
  String advancedNote(String amount) => 'خلّصتي $amount من جيبك.';
  @override
  String get given => 'توصلت';
  @override
  String get spent => 'صرفت';
  @override
  String get returned => 'رجعت';
  @override
  String pendingSpent(String amount) => 'منها $amount في انتظار الموافقة';
  @override
  String get newExpense => 'مصروف جديد';
  @override
  String get chooseCategory => 'شنو خلّصتي؟';
  @override
  String get moneyReceived => 'الفلوس اللي توصلت بها';
  @override
  String movement(bool deposit) => deposit ? 'سلّمها' : 'رجعتها لـ';
  @override
  String get noMovement => 'مازال ما توصلتي بحتى فلوس.';

  @override
  String category(String code) => switch (code) {
        'transport' => 'نقل الجمهور',
        'fuel' => 'الغازوال',
        'vehicle' => 'سيارتي',
        'catering' => 'التغذية',
        'audience' => 'الجمهور المؤدى عنه',
        'staff_day' => 'أجر الستاف ديال النهار',
        'taxi' => 'طاكسي',
        'indrive' => 'InDrive',
        'other' => 'مصروف آخر',
        _ => code,
      };

  @override
  String categoryHint(String code) => switch (code) {
        'transport' => 'ميني بيس، أوطوكار · كتخلصو الشركة',
        'fuel' => 'بطاقة أفريقيا',
        'vehicle' => 'السيارة الشخصية',
        'catering' => 'سندويتشات، ماء، مشروبات',
        'audience' => 'فيغيراسيون، مجاني أو مؤدى عنه',
        'staff_day' => 'جماعتنا زينة · 200 درهم',
        'taxi' => 'طاكسي',
        'indrive' => 'InDrive',
        'other' => 'كل شي آخر',
        _ => '',
      };

  @override
  String status(String code) => switch (code) {
        'pending' => 'في الانتظار',
        'validated' => 'مقبول',
        'refused' => 'مرفوض',
        _ => code,
      };
  @override
  String statusPlural(String code, int n) => switch (code) {
        'pending' => 'في الانتظار ($n)',
        'validated' => 'مقبولة ($n)',
        'refused' => 'مرفوضة ($n)',
        _ => '$code ($n)',
      };
  @override
  String get refusedBanner => 'خاصك تصحح: أيوب رفض هاد المصاريف.';
  @override
  String refusedBy(String? name) => name == null ? 'مرفوض' : 'رفضو $name';
  @override
  String get fix => 'صحّح';
  @override
  String get emptyList => 'والو هنا دابا.';

  @override
  String get programme => 'البرنامج';
  @override
  String get chooseProgramme => 'اختار البرنامج';
  @override
  String get noProgramme => 'خارج البرامج (مصروف عام)';
  @override
  String get searchProgramme => 'قلّب على برنامج';
  @override
  String get date => 'التاريخ';
  @override
  String get provider => 'مقدم الخدمة';
  @override
  String get providerHint => 'سمية مقدم الخدمة';
  @override
  String get withTransport => 'مع النقل';
  @override
  String get withoutTransport => 'بلا نقل';
  @override
  String get minibuses => 'ميني بيس';
  @override
  String get coaches => 'أوطوكار';
  @override
  String get transportAmount => 'المبلغ (إلا كنتي عارفو)';
  @override
  String get transportPaidBy =>
      'كتخلصو الشركة مباشرة: الصندوق ديالك ما كيتنقصش.';
  @override
  String get fuelPaidBy => 'بالبطاقة ديال أفريقيا: الصندوق ديالك ما كيتنقصش.';
  @override
  String get amount => 'المبلغ';
  @override
  String get mission => 'المهمة';
  @override
  String get missionHint => 'مثلا: جيب المعدات';
  @override
  String get withIndemnity => 'بمقابل';
  @override
  String get withoutIndemnity => 'بلا مقابل';
  @override
  String get indemnity => 'مبلغ التعويض';
  @override
  String get sandwiches => 'سندويتشات';
  @override
  String get sandwichPrice => 'ثمن السندويتش';
  @override
  String get drinks => 'الماء والمشروبات';
  @override
  String get paidPublic => 'الجمهور المؤدى عنه';
  @override
  String get freePublic => 'الجمهور المجاني';
  @override
  String get paidPeople => 'عدد المؤدى عنهم';
  @override
  String get pricePerPerson => 'المبلغ لكل شخص';
  @override
  String get freePeople => 'عدد المجانيين';
  @override
  String get staffPerson => 'شخص من الستاف';
  @override
  String get chooseStaff => 'اختار الشخص';
  @override
  String dayStaffNote(String amount) =>
      'فهاد البرنامج الستاف ما كيتخلصش: الشخص اللي اخترتي كياخد $amount فالأجر ديالو، من بعد موافقة أيوب.';
  @override
  String dayStaffTaken(String name) => 'ديجا تختار: $name.';
  @override
  String get dayStaffNoEpisode =>
      'ما كاين حتى برنامج قريب بلا أجر الستاف (جماعتنا زينة).';
  @override
  String get fromCashBox => 'خلّصتي من فلوس الصندوق؟';
  @override
  String get fromCashBoxYes => 'إيه، من الصندوق';
  @override
  String get fromCashBoxNo => 'لا';
  @override
  String get note => 'ملاحظة';
  @override
  String get noteRequired => 'شنو شريتي؟';
  @override
  String get total => 'المجموع';
  @override
  String get totalFromCashBox => 'كيخرج من الصندوق ديالك';
  @override
  String get totalNotFromCashBox => 'ما كيمسّش الصندوق ديالك';
  @override
  String get totalToBalance => 'كيتزاد فالأجر ديالو فالتطبيق';
  @override
  String get receipts => 'الفواتير والتوصيلات';
  @override
  String receiptsHint(int max) => 'صوّر التوصيل ($max على الأكثر).';
  @override
  String get camera => 'تصويرة';
  @override
  String get gallery => 'المعرض';
  @override
  String get save => 'سجّل';
  @override
  String get saveChanges => 'عاود صيفطو لأيوب';
  @override
  String get delete => 'مسح';
  @override
  String get deleteConfirm => 'تمسح هاد المصروف؟ المبلغ ديالو كيرجع للصندوق.';
  @override
  String get cancel => 'إلغاء';
  @override
  String get saved => 'تسجّل. أيوب غادي يوافق عليه.';
  @override
  String get resubmitted => 'تصحّح وتصيفط لأيوب.';
  @override
  String get deleted => 'تمسح المصروف.';
  @override
  String get addAnotherProvider => 'مقدم خدمة آخر؟';
  @override
  String get addAnotherProviderBody =>
      'تزيد مقدم خدمة آخر ديال النقل لهاد البرنامج؟';
  @override
  String get yes => 'إيه';
  @override
  String get no => 'لا';
  @override
  String get locked => 'وافق عليه أيوب: ما بقاش كيتبدل.';

  @override
  String missing(String key) => switch (key) {
        'episode' => 'اختار البرنامج.',
        'provider' => 'كتب مقدم الخدمة.',
        'vehicles' => 'كتب عدد الميني بيس ولا الأوطوكار.',
        'catering' => 'كتب السندويتشات والثمن، ولا الماء والمشروبات.',
        'people' => 'كتب الجمهور المؤدى عنه ولا المجاني.',
        'price' => 'كتب المبلغ لكل شخص.',
        'staff' => 'اختار الشخص من الستاف.',
        'mission' => 'كتب البرنامج ولا المهمة.',
        'note' => 'كتب شنو شريتي.',
        _ => 'كتب المبلغ.',
      };

  @override
  String day(DateTime d) => '${d.day} ${_moisAr[d.month - 1]} ${d.year}';
  @override
  String get loadError => 'ما قدرناش نجيبو الصندوق ديالك.';
  @override
  String get retry => 'عاود';
}
