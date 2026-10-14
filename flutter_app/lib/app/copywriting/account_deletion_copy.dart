/// Copy for « Supprimer mon compte ».
///
/// Hidden on purpose: people tapped it instead of « Se déconnecter ». It stays
/// reachable (Apple 5.1.1(v)) but can no longer be hit by mistake — a small
/// link, then a sheet where the word has to be typed.
abstract class AccountDeletionCopy {
  String get link;
  String get title;
  String get body;
  String get keeps;

  /// The word to type, in the reader's language.
  String get confirmWord;
  String typeToConfirm(String word);
  String get confirm;
  String get cancel;
  String get error;
}

class AccountDeletionCopyFr implements AccountDeletionCopy {
  const AccountDeletionCopyFr();

  @override
  String get link => 'Supprimer mon compte';
  @override
  String get title => 'Supprimer ton compte ?';
  @override
  String get body =>
      'Ton nom, ton téléphone, ton e-mail et ta photo seront effacés, tes réservations à venir annulées, et tu ne pourras plus te connecter. C\'est définitif.';
  @override
  String get keeps =>
      'Tu veux juste quitter l\'app sur ce téléphone ? Utilise plutôt « Se déconnecter ».';
  @override
  String get confirmWord => 'SUPPRIMER';
  @override
  String typeToConfirm(String word) => 'Pour confirmer, écris $word';
  @override
  String get confirm => 'Supprimer définitivement';
  @override
  String get cancel => 'Annuler';
  @override
  String get error => 'La suppression n\'a pas abouti. Réessaie.';
}

class AccountDeletionCopyAr implements AccountDeletionCopy {
  const AccountDeletionCopyAr();

  @override
  String get link => 'حذف حسابي';
  @override
  String get title => 'حذف الحساب ديالك؟';
  @override
  String get body =>
      'غادي يتمسحو السمية، الهاتف، الإيميل والصورة ديالك، وتتلغى الحجوزات الجاية، وما غاديش تقدر تدخل من جديد. هادشي نهائي.';
  @override
  String get keeps =>
      'بغيتي غير تخرج من التطبيق فهاد التيليفون؟ استعمل « تسجيل الخروج ».';
  @override
  String get confirmWord => 'حذف';
  @override
  String typeToConfirm(String word) => 'باش تأكد، كتب $word';
  @override
  String get confirm => 'حذف نهائي';
  @override
  String get cancel => 'إلغاء';
  @override
  String get error => 'ما تمّش الحذف. عاود المحاولة.';
}
