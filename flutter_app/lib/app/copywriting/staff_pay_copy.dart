/// Copy for « Ma paie » — the staff's pay per episode.
///
/// A contract, so French and Arabic cannot drift apart. Addressed with « tu »,
/// like the charge public's space.
abstract class StaffPayCopy {
  String money(int amount);

  String get title;
  String get profileCardTitle;
  String get profileCardSubtitle;

  /// `cp_supervisor` | `warm_up` | `tech` | `door`
  String position(String code);

  /// Ce qu'un poste touche, en une ligne. `big` / `small` : le montant par
  /// épisode (par entrée pour `tech`) — le même quand il est convenu avec la
  /// personne. `show` : l'émission pour laquelle elle est recrutée.
  String rateLine(
    String code, {
    int? big,
    int? small,
    String? show,
    int doorDiscountPercent = 20,
  });

  /// `big` | `small` | null
  String size(String? code);

  String date(DateTime d);
  String month(DateTime d);
  String since(String date);
  String period(String from, String to);

  String get totalEarned;
  String episodes(int n);
  String entries(int n);
  String available(String amount);
  String get withdrawHint;
  String pendingNote(int n);
  String get pendingAmount;
  String get historyTitle;
  String get empty;
  String get loadError;
  String get retry;

  /// Le lien depuis l'onglet Gains du chargé public.
  String get gainsLink;
}

const _moisFr = [
  'janvier',
  'février',
  'mars',
  'avril',
  'mai',
  'juin',
  'juillet',
  'août',
  'septembre',
  'octobre',
  'novembre',
  'décembre',
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

String _dd(int n) => n.toString().padLeft(2, '0');

class StaffPayCopyFr implements StaffPayCopy {
  const StaffPayCopyFr();

  @override
  String money(int amount) => '$amount DH';

  @override
  String get title => 'Ma paie';
  @override
  String get profileCardTitle => 'Ma paie';
  @override
  String get profileCardSubtitle =>
      'Tes épisodes payés, et le retrait par Wafacash.';

  @override
  String position(String code) => switch (code) {
        'cp_supervisor' => 'Superviseur des chargés publics',
        'warm_up' => 'Chauffeur de salle',
        'tech' => 'Équipe technique',
        'door' => 'Inscription à la porte',
        _ => code,
      };

  @override
  String rateLine(
    String code, {
    int? big,
    int? small,
    String? show,
    int doorDiscountPercent = 20,
  }) {
    final amount = big ?? small;
    if (amount == null) return '';
    switch (code) {
      case 'tech':
        final on = show != null ? ' sur $show' : '';
        return '${money(amount)} par personne entrée$on : billet scanné ou walk-in.';
      case 'door':
        return 'Ta part de la remise de $doorDiscountPercent % sur les comptes ouverts à la porte, partagée à parts égales avec l\'équipe.';
    }
    if (big == null || small == null || big == small) {
      final on = show != null ? ' de $show' : '';
      return '${money(amount)} par épisode$on.';
    }
    final on = show != null ? '$show : ' : '';
    return '$on${money(big)} par épisode d\'une grande émission, ${money(small)} pour une petite.';
  }

  @override
  String size(String? code) => switch (code) {
        'big' => 'Grande émission',
        'small' => 'Petite émission',
        _ => 'Format à confirmer',
      };

  @override
  String date(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}';
  @override
  String month(DateTime d) {
    final m = _moisFr[d.month - 1];
    return '${m[0].toUpperCase()}${m.substring(1)} ${d.year}';
  }

  @override
  String since(String date) => 'Depuis le $date';
  @override
  String period(String from, String to) => 'Du $from au $to';

  @override
  String get totalEarned => 'Gagné en paie staff';
  @override
  String episodes(int n) => n <= 1 ? '$n épisode payé' : '$n épisodes payés';
  @override
  String entries(int n) => n <= 1 ? '$n entrée' : '$n entrées';
  @override
  String available(String amount) => 'Disponible au retrait : $amount';
  @override
  String get withdrawHint =>
      'Le retrait regroupe ta paie et, si tu en as, tes gains de chargé public.';
  @override
  String pendingNote(int n) => n <= 1
      ? '1 épisode en attente : son montant s\'affichera dès que l\'équipe aura choisi le format de l\'émission.'
      : '$n épisodes en attente : leur montant s\'affichera dès que l\'équipe aura choisi le format de l\'émission.';
  @override
  String get pendingAmount => 'En attente';
  @override
  String get historyTitle => 'Épisodes';
  @override
  String get empty =>
      'Aucun épisode payé pour l\'instant. Chaque épisode où tu es en poste s\'ajoutera ici.';
  @override
  String get loadError => 'Impossible de charger ta paie.';
  @override
  String get retry => 'Réessayer';
  @override
  String get gainsLink => 'Voir le détail de ma paie staff';
}

class StaffPayCopyAr implements StaffPayCopy {
  const StaffPayCopyAr();

  @override
  String money(int amount) => '$amount درهم';

  @override
  String get title => 'أجري';
  @override
  String get profileCardTitle => 'أجري';
  @override
  String get profileCardSubtitle => 'الحلقات المؤداة، والسحب عبر وفاكاش.';

  @override
  String position(String code) => switch (code) {
        'cp_supervisor' => 'مشرف المكلفين بالجمهور',
        'warm_up' => 'منشّط القاعة',
        'tech' => 'الفريق التقني',
        'door' => 'التسجيل عند الباب',
        _ => code,
      };

  @override
  String rateLine(
    String code, {
    int? big,
    int? small,
    String? show,
    int doorDiscountPercent = 20,
  }) {
    final amount = big ?? small;
    if (amount == null) return '';
    switch (code) {
      case 'tech':
        final on = show != null ? ' إلى $show' : '';
        return '${money(amount)} عن كل شخص دخل$on: تذكرة ممسوحة أو تسجيل في عين المكان.';
      case 'door':
        return 'نصيبك من تخفيض $doorDiscountPercent% على الحسابات المفتوحة عند الباب، يُقسَّم بالتساوي مع الفريق.';
    }
    if (big == null || small == null || big == small) {
      final on = show != null ? ' من $show' : '';
      return '${money(amount)} عن كل حلقة$on.';
    }
    final on = show != null ? '$show: ' : '';
    return '$on${money(big)} عن كل حلقة من برنامج كبير، و${money(small)} لبرنامج صغير.';
  }

  @override
  String size(String? code) => switch (code) {
        'big' => 'برنامج كبير',
        'small' => 'برنامج صغير',
        _ => 'الصيغة في انتظار التأكيد',
      };

  @override
  String date(DateTime d) => '${_dd(d.day)}/${_dd(d.month)}';
  @override
  String month(DateTime d) => '${_moisAr[d.month - 1]} ${d.year}';

  @override
  String since(String date) => 'منذ $date';
  @override
  String period(String from, String to) => 'من $from إلى $to';

  @override
  String get totalEarned => 'المكسب من أجر الطاقم';
  @override
  String episodes(int n) => n <= 1 ? '$n حلقة مؤداة' : '$n حلقات مؤداة';
  @override
  String entries(int n) => '$n دخول';
  @override
  String available(String amount) => 'متاح للسحب: $amount';
  @override
  String get withdrawHint =>
      'السحب يجمع أجرك، وأرباحك كمكلف بالجمهور إن وُجدت.';
  @override
  String pendingNote(int n) =>
      '$n حلقة في الانتظار: سيظهر المبلغ بمجرد أن يحدد الفريق صيغة البرنامج.';
  @override
  String get pendingAmount => 'في الانتظار';
  @override
  String get historyTitle => 'الحلقات';
  @override
  String get empty =>
      'لا توجد حلقة مؤداة إلى حدود الآن. كل حلقة تكون فيها في منصبك ستُضاف هنا.';
  @override
  String get loadError => 'تعذر تحميل أجرك.';
  @override
  String get retry => 'أعد المحاولة';
  @override
  String get gainsLink => 'عرض تفاصيل أجري في الطاقم';
}
