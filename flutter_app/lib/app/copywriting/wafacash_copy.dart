import 'package:intl/intl.dart' show DateFormat;

/// Copy for Wafacash withdrawals — the charge public asking for their money.
///
/// A contract, so French and Arabic cannot drift apart: a string added here and
/// missing in one language does not compile. Addressed with « tu », like the
/// rest of the charge public's space.
abstract class WafacashCopy {
  String money(int amount);

  /// A date in words: « 5 novembre ».
  String date(DateTime day);

  // The card in « Gains »
  String get cardTitle;
  String get availableNow;

  /// The money is there, but today is not an opening day.
  String get availableAtOpening;
  String get cardWithdraw;

  /// Under the minimum: how far they are, not just where the bar sits.
  String cardBelowMin(String missing, String min);
  String get howItWorksLink;

  /// Earned on a recording that ended less than 24 h ago.
  String heldNote(String amount);

  /// The switch is off: the money is safe, it just can't leave right now.
  String get closedNotice;

  // The monthly window. Days and dates always come from the server.
  String windowRule(int start, int end);
  String windowOpensOn(String date, int days);
  String windowClosesOn(String date, int days);
  String windowClosedButton(String date);
  String get windowEmergency;
  String exceptionOpen(String until);

  /// Earned on a recording made during the current opening.
  String deferredNote(String amount, String date);

  /// The first withdrawal, in order. Gone once they have done one.
  List<String> get firstTimeSteps;

  // Identity — once
  String get identityTitle;
  String get identityIntro;
  String get identityStart;
  String get legalNameLabel;
  String get cinLabel;
  String get cinHint;
  String get front;
  String get back;
  String get takePhoto;
  String get fromGallery;
  String get retake;
  String get photoTip;
  String get submit;
  String get privacy;
  String get identityPending;
  String identityRejected(String reason);
  String get resend;
  String get nameRequired;
  String get cinInvalid;
  String get photosRequired;
  String get identitySent;

  // Asking
  String get requestTitle;
  String get amountLabel;
  String get all;

  /// The one line about fees: they are Wafacash's, and the charge public's.
  /// No figure — Wafacash sets its prices, not us.
  String get feesOnYou;

  /// On a small amount the fees take a big share. Still no figure.
  String get feesWeighHeavy;
  String get doesNotCoverFees;
  String belowMin(String min);
  String aboveAvailable(String available);
  String aboveMax(String max);
  String get afterConfirm;
  String get confirm;
  String get requested;

  // Following it
  List<String> get stepLabels;
  String get statusRequested;
  String get statusRequestedHint;
  String get statusProcessing;
  String get statusProcessingHint;
  String get statusCodeSent;
  String get codeLabel;
  String get codeCopied;
  String get bringTitle;
  String bringCin(String name);
  String get bringCode;
  String collectBefore(String date);
  String daysLeft(int days);
  String get afterDeadline;
  String get iCollected;
  String get collectedConfirmTitle;
  String get collectedConfirmBody;
  String get collectedConfirmYes;
  String get notYet;
  String get cancel;
  String get cancelConfirmTitle;
  String get cancelConfirmBody;

  /// Cancelling outside the window means waiting for the next one.
  String cancelConfirmBodyClosed(String date);
  String get keep;
  String requestedAmount(String amount);
  String get historyTitle;

  /// Closed outcomes, as the history list shows them.
  String get statusCollected;
  String get statusRejected;
  String get statusCancelled;
  String get statusExpired;

  /// Une demande annulée par le staff : la raison, et de quoi recommencer.
  String cancelledByStaff(String amount, String reason);
  String get requestAgain;

  // The news: what changed for the charge public
  String get newsBannerTitle;

  /// [startDay] and [endDay] are null when withdrawals are open all month.
  String newsBannerBody(int? startDay, int? endDay);
  String get newsBannerAction;
  String get newsTitle;
  List<WafacashNewsItem> newsItems(String min, int? startDay, int? endDay);
  String get newsDone;

  String get genericError;
}

/// One point of the news: the rule, then what it means for them.
class WafacashNewsItem {
  const WafacashNewsItem(this.title, this.body);

  final String title;
  final String body;
}

class WafacashCopyFr implements WafacashCopy {
  const WafacashCopyFr();

  @override
  String money(int amount) => '$amount DH';
  @override
  String date(DateTime day) => DateFormat('d MMMM', 'fr_FR').format(day);

  @override
  String get cardTitle => 'Retirer via Wafacash';
  @override
  String get availableNow => 'Disponible maintenant';
  @override
  String get availableAtOpening => 'À retirer à la prochaine ouverture';
  @override
  String get cardWithdraw => 'Retirer mes gains';
  @override
  String cardBelowMin(String missing, String min) =>
      'Encore $missing pour atteindre le minimum de $min.';
  @override
  String get howItWorksLink => 'Comment ça marche ?';
  @override
  String heldNote(String amount) =>
      '$amount en attente : disponibles 24 h après la fin du tournage.';
  @override
  String get closedNotice =>
      'Les retraits sont fermés pour le moment. Ton solde ne bouge pas : reviens un peu plus tard.';
  @override
  String windowRule(int start, int end) =>
      'Retraits ouverts du $start au $end de chaque mois.';
  @override
  String windowOpensOn(String date, int days) => days <= 1
      ? 'Prochaine ouverture : demain, le $date.'
      : 'Prochaine ouverture : le $date, dans $days jours.';
  @override
  String windowClosesOn(String date, int days) => switch (days) {
        <= 0 => 'Dernier jour pour demander : aujourd\'hui.',
        1 => 'Tu peux demander jusqu\'à demain, le $date.',
        _ => 'Tu peux demander jusqu\'au $date, encore $days jours.',
      };
  @override
  String windowClosedButton(String date) => 'Ouverture le $date';
  @override
  String get windowEmergency =>
      'Pour une urgence, contacte le responsable de la caisse.';
  @override
  String exceptionOpen(String until) =>
      'Retrait exceptionnel ouvert jusqu\'au $until : une seule demande, sur tout ton disponible.';
  @override
  String deferredNote(String amount, String date) =>
      '$amount des tournages faits pendant l\'ouverture : à retirer à partir du $date.';
  @override
  List<String> get firstTimeSteps => const [
        'Envoie ta CIN, une seule fois',
        'Demande le montant que tu veux',
        'Retire en espèces avec ton code et ta CIN',
      ];

  @override
  String get identityTitle => 'Vérifier ton identité';
  @override
  String get identityIntro =>
      'Une seule fois. Wafacash ne remet l\'argent qu\'au titulaire de la CIN, sur son nom exact.';
  @override
  String get identityStart => 'Envoyer ma CIN';
  @override
  String get legalNameLabel => 'Nom complet, exactement comme sur ta CIN';
  @override
  String get cinLabel => 'Numéro de CIN';
  @override
  String get cinHint => 'ex. AB123456';
  @override
  String get front => 'Recto';
  @override
  String get back => 'Verso';
  @override
  String get takePhoto => 'Prendre en photo';
  @override
  String get fromGallery => 'Choisir dans la galerie';
  @override
  String get retake => 'Reprendre';
  @override
  String get photoTip =>
      'Toute la carte dans le cadre, bien lisible, sans reflet.';
  @override
  String get submit => 'Envoyer pour vérification';
  @override
  String get privacy =>
      'Ta CIN est chiffrée et n\'est visible que par l\'équipe qui fait les paiements.';
  @override
  String get identityPending =>
      'Identité en cours de vérification. Tu pourras retirer dès qu\'elle est validée.';
  @override
  String identityRejected(String reason) => 'Identité refusée : $reason';
  @override
  String get resend => 'Renvoyer ma CIN';
  @override
  String get nameRequired => 'Indique ton nom complet.';
  @override
  String get cinInvalid =>
      'Le numéro commence par une ou deux lettres suivies de chiffres.';
  @override
  String get photosRequired => 'Ajoute les deux faces de ta CIN.';
  @override
  String get identitySent =>
      'CIN envoyée. On te prévient dès qu\'elle est vérifiée.';

  @override
  String get requestTitle => 'Combien veux-tu retirer ?';
  @override
  String get amountLabel => 'Montant';
  @override
  String get all => 'Tout';
  @override
  String get feesOnYou =>
      'Wafacash transfère ce montant et prend ses frais au guichet : tu recevras un peu moins en espèces.';
  @override
  String get feesWeighHeavy =>
      'Sur un petit montant, les frais pèsent lourd. Si tu peux, attends d\'avoir plus.';
  @override
  String get doesNotCoverFees => 'Ce montant ne couvre pas les frais Wafacash.';
  @override
  String belowMin(String min) => 'Le minimum est de $min.';
  @override
  String aboveAvailable(String available) => 'Tu as $available disponibles.';
  @override
  String aboveMax(String max) => 'Le maximum est de $max par demande.';
  @override
  String get afterConfirm =>
      'L\'équipe prépare le transfert. Ton code arrive ici et on te prévient par notification.';
  @override
  String get confirm => 'Confirmer la demande';
  @override
  String get requested => 'Demande envoyée.';

  @override
  List<String> get stepLabels => const ['Demandé', 'Transfert', 'Code prêt'];
  @override
  String get statusRequested => 'Demande envoyée';
  @override
  String get statusRequestedHint =>
      'L\'équipe va préparer ton transfert. Tu peux encore annuler.';
  @override
  String get statusProcessing => 'Transfert en cours';
  @override
  String get statusProcessingHint =>
      'L\'équipe prépare ton transfert avec Wafacash. Ton code arrive bientôt ici.';
  @override
  String get statusCodeSent => 'Ton argent est prêt';
  @override
  String get codeLabel => 'Code Wafacash';
  @override
  String get codeCopied => 'Code copié';
  @override
  String get bringTitle => 'À apporter dans une agence Wafacash';
  @override
  String bringCin(String name) => 'Ta CIN originale, au nom de $name';
  @override
  String get bringCode => 'Ce code de 12 chiffres';
  @override
  String collectBefore(String date) => 'À retirer avant le $date';
  @override
  String daysLeft(int days) => switch (days) {
        <= 0 => 'Dernier jour',
        1 => 'Plus qu\'1 jour',
        _ => 'Plus que $days jours',
      };
  @override
  String get afterDeadline =>
      'Passé cette date, le montant revient sur ton solde.';
  @override
  String get iCollected => 'J\'ai retiré l\'argent';
  @override
  String get collectedConfirmTitle => 'Tu as bien retiré l\'argent ?';
  @override
  String get collectedConfirmBody => 'Le code disparaîtra de l\'app.';
  @override
  String get collectedConfirmYes => 'Oui, c\'est retiré';
  @override
  String get notYet => 'Pas encore';
  @override
  String get cancel => 'Annuler la demande';
  @override
  String get cancelConfirmTitle => 'Annuler cette demande ?';
  @override
  String get cancelConfirmBody => 'Le montant revient sur ton solde.';
  @override
  String cancelConfirmBodyClosed(String date) =>
      'Le montant revient sur ton solde, mais tu ne pourras refaire une demande qu\'à partir du $date.';
  @override
  String get keep => 'Garder';
  @override
  String requestedAmount(String amount) =>
      'Retrait de $amount · frais d\'agence à ta charge';
  @override
  String get historyTitle => 'Mes retraits Wafacash';

  @override
  String get statusCollected => 'Retiré';
  @override
  String get statusRejected => 'Refusé';
  @override
  String get statusCancelled => 'Annulé';
  @override
  String get statusExpired => 'Non retiré — rendu';

  @override
  String cancelledByStaff(String amount, String reason) =>
      'Ta demande de $amount a été annulée : $reason';
  @override
  String get requestAgain => 'Refaire une demande';

  @override
  String get newsBannerTitle => 'Nouveau : comment tu es payé';
  @override
  String newsBannerBody(int? startDay, int? endDay) => startDay != null
      ? 'Tes gains se retirent uniquement via Wafacash, du $startDay au $endDay de chaque mois.'
      : 'Tes gains se retirent uniquement via Wafacash, 24 h après le tournage.';
  @override
  String get newsBannerAction => 'Voir ce qui change';
  @override
  String get newsTitle => 'Retraits Wafacash : ce qui change';
  @override
  List<WafacashNewsItem> newsItems(String min, int? startDay, int? endDay) => [
        WafacashNewsItem(
          'Plus d\'espèces ni d\'avance',
          'Tu es payé uniquement par retrait Wafacash, depuis l\'onglet Gains, à partir de $min.',
        ),
        if (startDay != null)
          WafacashNewsItem(
            'Ouvert du $startDay au $endDay de chaque mois',
            'En dehors de ces jours, aucune demande ne passe. Pour une urgence, contacte le responsable de la caisse.',
          ),
        WafacashNewsItem(
          'Disponible 24 h après le tournage',
          startDay != null
              ? 'Le temps de vérifier les présences du soir. L\'argent des tournages faits pendant l\'ouverture se retire à l\'ouverture suivante.'
              : 'Le temps de vérifier les présences du soir. Ensuite, l\'argent passe dans ton disponible.',
        ),
        const WafacashNewsItem(
          'Les frais se paient au guichet',
          'Wafacash transfère le montant demandé et prend ses frais quand tu le retires. Chaque retrait a ses frais : mieux vaut une grosse somme que plusieurs petites.',
        ),
        const WafacashNewsItem(
          'Un code de 12 chiffres, avec une date limite',
          'Le code s\'affiche uniquement dans l\'app. Va au guichet avec ta CIN originale avant la date indiquée ; après, le montant revient sur ton solde.',
        ),
        const WafacashNewsItem(
          'Une demande à la fois',
          'Après un tournage, l\'équipe peut annuler une demande pour corriger le solde. Le montant revient et tu refais ta demande.',
        ),
      ];
  @override
  String get newsDone => 'J\'ai compris';

  @override
  String get genericError => 'Impossible pour le moment. Réessaie.';
}

class WafacashCopyAr implements WafacashCopy {
  const WafacashCopyAr();

  @override
  String money(int amount) => '$amount درهم';
  @override
  String date(DateTime day) => DateFormat('d MMMM', 'ar').format(day);

  @override
  String get cardTitle => 'اسحب عبر وفاكاش';
  @override
  String get availableNow => 'متاح دابا';
  @override
  String get availableAtOpening => 'تسحبو ف الفتح الجاي';
  @override
  String get cardWithdraw => 'اسحب أرباحي';
  @override
  String cardBelowMin(String missing, String min) =>
      'باقي ليك $missing باش توصل للحد الأدنى $min.';
  @override
  String get howItWorksLink => 'كيفاش خدامة؟';
  @override
  String heldNote(String amount) =>
      '$amount فالانتظار: غادي يكونو متاحين 24 ساعة من بعد نهاية التصوير.';
  @override
  String get closedNotice =>
      'السحوبات مسدودة دابا. الرصيد ديالك ما كيتبدلش: رجع من بعد شوية.';
  @override
  String windowRule(int start, int end) =>
      'السحوبات مفتوحة من $start حتى $end ف كل شهر.';
  @override
  String windowOpensOn(String date, int days) => days <= 1
      ? 'الفتح الجاي: غدا، $date.'
      : 'الفتح الجاي: $date، من هنا $days أيام.';
  @override
  String windowClosesOn(String date, int days) => switch (days) {
        <= 0 => 'اليوم آخر نهار باش تطلب.',
        1 => 'تقدر تطلب حتى غدا، $date.',
        _ => 'تقدر تطلب حتى $date، باقي $days أيام.',
      };
  @override
  String windowClosedButton(String date) => 'الفتح نهار $date';
  @override
  String get windowEmergency => 'ف حالة مستعجلة، تاصل بالمسؤول على الصندوق.';
  @override
  String exceptionOpen(String until) =>
      'سحب استثنائي مفتوح حتى $until: طلب واحد، على كل المتاح ديالك.';
  @override
  String deferredNote(String amount, String date) =>
      '$amount ديال التصويرات اللي تدارو ف وقت الفتح: تقدر تسحبهم ابتداءً من $date.';
  @override
  List<String> get firstTimeSteps => const [
        'صيفط البطاقة ديالك، مرة وحدة برك',
        'طلب المبلغ اللي بغيتي',
        'سحب الفلوس كاش بالرمز والبطاقة ديالك',
      ];

  @override
  String get identityTitle => 'تحقق من الهوية ديالك';
  @override
  String get identityIntro =>
      'مرة وحدة برك. وفاكاش ما كيعطي الفلوس غير لمول البطاقة، بسميتو بالضبط.';
  @override
  String get identityStart => 'صيفط البطاقة ديالي';
  @override
  String get legalNameLabel => 'الاسم الكامل، بحال اللي ف البطاقة بالضبط';
  @override
  String get cinLabel => 'رقم البطاقة الوطنية';
  @override
  String get cinHint => 'مثلا AB123456';
  @override
  String get front => 'الوجه';
  @override
  String get back => 'الظهر';
  @override
  String get takePhoto => 'صوّر';
  @override
  String get fromGallery => 'ختار من الصور';
  @override
  String get retake => 'عاود';
  @override
  String get photoTip => 'البطاقة كاملة ف الإطار، واضحة، بلا ضو كيلمع.';
  @override
  String get submit => 'صيفط للتحقق';
  @override
  String get privacy =>
      'البطاقة ديالك مشفرة، وما كيشوفهاش غير الفريق اللي كيخلص.';
  @override
  String get identityPending =>
      'الهوية ديالك كتراجع. غادي تقدر تسحب ملي تتأكد.';
  @override
  String identityRejected(String reason) => 'ترفضات الهوية: $reason';
  @override
  String get resend => 'عاود صيفط البطاقة';
  @override
  String get nameRequired => 'كتب سميتك الكاملة.';
  @override
  String get cinInvalid => 'الرقم كيبدا بحرف ولا جوج، من بعدهم أرقام.';
  @override
  String get photosRequired => 'زيد الوجهين ديال البطاقة.';
  @override
  String get identitySent => 'تصيفطات البطاقة. غادي نعلموك ملي تتأكد.';

  @override
  String get requestTitle => 'شحال بغيتي تسحب؟';
  @override
  String get amountLabel => 'المبلغ';
  @override
  String get all => 'كلشي';
  @override
  String get feesOnYou =>
      'وفاكاش كيحول هاد المبلغ وكياخد المصاريف ديالو ف الشباك: غادي توصل بشوية أقل كاش.';
  @override
  String get feesWeighHeavy =>
      'ف مبلغ صغير، المصاريف كتبان كبيرة. إلا قدرتي، تسنى حتى يكون عندك كثر.';
  @override
  String get doesNotCoverFees => 'هاد المبلغ ما كيغطيش مصاريف وفاكاش.';
  @override
  String belowMin(String min) => 'الحد الأدنى هو $min.';
  @override
  String aboveAvailable(String available) => 'عندك $available متاحين.';
  @override
  String aboveMax(String max) => 'الحد الأقصى هو $max ف كل طلب.';
  @override
  String get afterConfirm =>
      'الفريق كيوجد التحويل. الرمز غادي يوصلك هنا، ونعلموك بإشعار.';
  @override
  String get confirm => 'أكد الطلب';
  @override
  String get requested => 'تصيفط الطلب.';

  @override
  List<String> get stepLabels => const ['تطلب', 'التحويل', 'الرمز واجد'];
  @override
  String get statusRequested => 'تصيفط الطلب';
  @override
  String get statusRequestedHint =>
      'الفريق غادي يوجد التحويل ديالك. مازال تقدر تلغي.';
  @override
  String get statusProcessing => 'التحويل جاري';
  @override
  String get statusProcessingHint =>
      'الفريق كيوجد التحويل ديالك مع وفاكاش. الرمز غادي يوصلك هنا قريب.';
  @override
  String get statusCodeSent => 'الفلوس ديالك واجدين';
  @override
  String get codeLabel => 'رمز وفاكاش';
  @override
  String get codeCopied => 'تنسخ الرمز';
  @override
  String get bringTitle => 'شنو تدي معاك لوكالة وفاكاش';
  @override
  String bringCin(String name) => 'البطاقة الأصلية، باسم $name';
  @override
  String get bringCode => 'هاد الرمز ديال 12 رقم';
  @override
  String collectBefore(String date) => 'سحبو قبل $date';
  @override
  String daysLeft(int days) => switch (days) {
        <= 0 => 'آخر نهار',
        1 => 'باقي نهار واحد',
        2 => 'باقي جوج أيام',
        _ => 'باقي $days أيام',
      };
  @override
  String get afterDeadline => 'من بعد هاد التاريخ، المبلغ كيرجع للرصيد ديالك.';
  @override
  String get iCollected => 'سحبت الفلوس';
  @override
  String get collectedConfirmTitle => 'واش بصح سحبتي الفلوس؟';
  @override
  String get collectedConfirmBody => 'الرمز غادي يختفي من التطبيق.';
  @override
  String get collectedConfirmYes => 'إيه، سحبتهم';
  @override
  String get notYet => 'مازال';
  @override
  String get cancel => 'لغي الطلب';
  @override
  String get cancelConfirmTitle => 'تلغي هاد الطلب؟';
  @override
  String get cancelConfirmBody => 'المبلغ غادي يرجع للرصيد ديالك.';
  @override
  String cancelConfirmBodyClosed(String date) =>
      'المبلغ غادي يرجع للرصيد ديالك، ولكن ما تقدرش تعاود الطلب حتى $date.';
  @override
  String get keep => 'خليه';
  @override
  String requestedAmount(String amount) =>
      'سحب $amount · مصاريف الوكالة على حسابك';
  @override
  String get historyTitle => 'السحوبات ديالي ف وفاكاش';

  @override
  String get statusCollected => 'تسحب';
  @override
  String get statusRejected => 'ترفض';
  @override
  String get statusCancelled => 'تلغى';
  @override
  String get statusExpired => 'ما تسحبش — رجع';

  @override
  String cancelledByStaff(String amount, String reason) =>
      'الطلب ديال $amount تلغى: $reason';
  @override
  String get requestAgain => 'دير طلب جديد';

  @override
  String get newsBannerTitle => 'جديد: كيفاش كتخلص';
  @override
  String newsBannerBody(int? startDay, int? endDay) => startDay != null
      ? 'الأرباح ديالك كتسحب غير عبر وفاكاش، من $startDay حتى $endDay ف كل شهر.'
      : 'الأرباح ديالك كتسحب غير عبر وفاكاش، 24 ساعة من بعد التصوير.';
  @override
  String get newsBannerAction => 'شوف شنو تبدل';
  @override
  String get newsTitle => 'سحب وفاكاش: شنو تبدل';
  @override
  List<WafacashNewsItem> newsItems(String min, int? startDay, int? endDay) => [
        WafacashNewsItem(
          'ما بقاش الكاش ولا التسبيق',
          'كتخلص غير بالسحب من وفاكاش، من خانة الأرباح، ابتداءً من $min.',
        ),
        if (startDay != null)
          WafacashNewsItem(
            'مفتوح من $startDay حتى $endDay ف كل شهر',
            'برا هاد الأيام، حتى طلب ما كيدوز. ف حالة مستعجلة، تاصل بالمسؤول على الصندوق.',
          ),
        WafacashNewsItem(
          'متاح 24 ساعة من بعد التصوير',
          startDay != null
              ? 'باش نراجعو الحضور ديال ديك الليلة. الفلوس ديال التصويرات اللي تدارو ف وقت الفتح كتسحب ف الفتح اللي من بعد.'
              : 'باش نراجعو الحضور ديال ديك الليلة. من بعد، الفلوس كيدوزو للمتاح.',
        ),
        const WafacashNewsItem(
          'المصاريف كتخلص ف الشباك',
          'وفاكاش كيحول المبلغ اللي طلبتي وكياخد المصاريف ملي كتسحب. كل سحب عندو المصاريف ديالو: الأحسن مبلغ كبير مرة وحدة بلا بزاف ديال المبالغ الصغار.',
        ),
        const WafacashNewsItem(
          'رمز ديال 12 رقم، وتاريخ نهاية',
          'الرمز كيبان غير ف التطبيق. سير للشباك بالبطاقة الأصلية قبل التاريخ المكتوب؛ من بعد، المبلغ كيرجع للرصيد ديالك.',
        ),
        const WafacashNewsItem(
          'طلب واحد ف المرة',
          'من بعد شي تصوير، يقدر الفريق يلغي طلب باش يصحح الرصيد. المبلغ كيرجع ليك وكتعاود الطلب.',
        ),
      ];
  @override
  String get newsDone => 'فهمت';

  @override
  String get genericError => 'ما قدرناش دابا. عاود جرب.';
}
