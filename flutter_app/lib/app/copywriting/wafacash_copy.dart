/// Copy for Wafacash withdrawals — the charge public asking for their money.
///
/// A contract, so French and Arabic cannot drift apart: a string added here and
/// missing in one language does not compile. Addressed with « tu », like the
/// rest of the charge public's space.
abstract class WafacashCopy {
  String money(int amount);

  // The card in « Gains »
  String get cardTitle;
  String cardAvailable(String amount);
  String get cardWithdraw;
  String cardBelowMin(String min);
  String get cardHowItWorks;

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
  String feeLine(String fee);
  String netLine(String net);
  String debitedLine(String amount);
  String get feeExplainer;
  String get beyondGrid;
  String belowMin(String min);
  String aboveAvailable(String available);
  String aboveMax(String max);
  String get confirm;
  String get requested;

  // Following it
  String get statusRequested;
  String get statusRequestedHint;
  String get statusProcessing;
  String get statusProcessingHint;
  String get statusCodeSent;
  String get codeLabel;
  String get codeCopied;
  String codeInstructions(String name);
  String get iCollected;
  String get cancel;
  String get cancelConfirmTitle;
  String get cancelConfirmBody;
  String get keep;
  String amounts(String gross, String fee, String net);
  String get historyTitle;

  /// Closed outcomes, as the history list shows them.
  String get statusCollected;
  String get statusRejected;
  String get statusCancelled;
  String get statusExpired;

  String get genericError;
}

class WafacashCopyFr implements WafacashCopy {
  const WafacashCopyFr();

  @override
  String money(int amount) => '$amount DH';

  @override
  String get cardTitle => 'Retirer via Wafacash';
  @override
  String cardAvailable(String amount) => 'Disponible : $amount';
  @override
  String get cardWithdraw => 'Retirer mes gains';
  @override
  String cardBelowMin(String min) => 'Retrait possible à partir de $min';
  @override
  String get cardHowItWorks =>
      'Tu retires en espèces dans n\'importe quelle agence Wafacash, avec ta CIN.';

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
  String get identitySent => 'CIN envoyée. On te prévient dès qu\'elle est vérifiée.';

  @override
  String get requestTitle => 'Combien veux-tu retirer ?';
  @override
  String get amountLabel => 'Montant';
  @override
  String get all => 'Tout';
  @override
  String feeLine(String fee) => 'Frais Wafacash : $fee';
  @override
  String netLine(String net) => 'Tu retireras : $net';
  @override
  String debitedLine(String amount) =>
      'Débité de ton solde : $amount (le palier suivant coûterait plus cher)';
  @override
  String get feeExplainer =>
      'Les frais Wafacash sont déduits du montant demandé.';
  @override
  String get beyondGrid => 'Montant hors de la grille des frais.';
  @override
  String belowMin(String min) => 'Minimum $min';
  @override
  String aboveAvailable(String available) => 'Disponible : $available';
  @override
  String aboveMax(String max) => 'Maximum $max par demande';
  @override
  String get confirm => 'Confirmer la demande';
  @override
  String get requested => 'Demande envoyée.';

  @override
  String get statusRequested => 'Demande envoyée';
  @override
  String get statusRequestedHint => 'L\'équipe va faire le transfert Wafacash.';
  @override
  String get statusProcessing => 'Transfert en cours';
  @override
  String get statusProcessingHint =>
      'Un membre de l\'équipe est au guichet Wafacash.';
  @override
  String get statusCodeSent => 'Ton argent est prêt';
  @override
  String get codeLabel => 'Code Wafacash';
  @override
  String get codeCopied => 'Code copié';
  @override
  String codeInstructions(String name) =>
      'Présente-toi dans une agence Wafacash avec ta CIN originale et ce code. Le transfert est au nom de $name.';
  @override
  String get iCollected => 'J\'ai retiré l\'argent';
  @override
  String get cancel => 'Annuler la demande';
  @override
  String get cancelConfirmTitle => 'Annuler cette demande ?';
  @override
  String get cancelConfirmBody => 'Le montant revient sur ton solde.';
  @override
  String get keep => 'Garder';
  @override
  String amounts(String gross, String fee, String net) =>
      '$gross demandés · $fee de frais · $net à retirer';
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
  String get genericError => 'Impossible pour le moment. Réessaie.';
}

class WafacashCopyAr implements WafacashCopy {
  const WafacashCopyAr();

  @override
  String money(int amount) => '$amount درهم';

  @override
  String get cardTitle => 'اسحب عبر وفاكاش';
  @override
  String cardAvailable(String amount) => 'المتاح: $amount';
  @override
  String get cardWithdraw => 'اسحب أرباحي';
  @override
  String cardBelowMin(String min) => 'السحب ممكن ابتداءً من $min';
  @override
  String get cardHowItWorks =>
      'كتسحب الفلوس كاش من أي وكالة وفاكاش، بالبطاقة الوطنية ديالك.';

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
  String feeLine(String fee) => 'رسوم وفاكاش: $fee';
  @override
  String netLine(String net) => 'غادي تسحب: $net';
  @override
  String debitedLine(String amount) =>
      'غادي يتنقص من الرصيد ديالك: $amount (الشريحة الجاية غالية كثر)';
  @override
  String get feeExplainer => 'رسوم وفاكاش كتنقص من المبلغ اللي طلبتي.';
  @override
  String get beyondGrid => 'المبلغ خارج جدول الرسوم.';
  @override
  String belowMin(String min) => 'الحد الأدنى $min';
  @override
  String aboveAvailable(String available) => 'المتاح: $available';
  @override
  String aboveMax(String max) => 'الحد الأقصى $max ف كل طلب';
  @override
  String get confirm => 'أكد الطلب';
  @override
  String get requested => 'تصيفط الطلب.';

  @override
  String get statusRequested => 'تصيفط الطلب';
  @override
  String get statusRequestedHint => 'الفريق غادي يدير التحويل ف وفاكاش.';
  @override
  String get statusProcessing => 'التحويل جاري';
  @override
  String get statusProcessingHint => 'واحد من الفريق ف الشباك ديال وفاكاش.';
  @override
  String get statusCodeSent => 'الفلوس ديالك واجدين';
  @override
  String get codeLabel => 'رمز وفاكاش';
  @override
  String get codeCopied => 'تنسخ الرمز';
  @override
  String codeInstructions(String name) =>
      'سير لشي وكالة وفاكاش بالبطاقة الأصلية وهاد الرمز. التحويل باسم $name.';
  @override
  String get iCollected => 'سحبت الفلوس';
  @override
  String get cancel => 'لغي الطلب';
  @override
  String get cancelConfirmTitle => 'تلغي هاد الطلب؟';
  @override
  String get cancelConfirmBody => 'المبلغ غادي يرجع للرصيد ديالك.';
  @override
  String get keep => 'خليه';
  @override
  String amounts(String gross, String fee, String net) =>
      'طلبتي $gross · رسوم $fee · غادي تسحب $net';
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
  String get genericError => 'ما قدرناش دابا. عاود جرب.';
}
