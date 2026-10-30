/// Copy for « Suis-nous » : nos comptes officiels, dans le Profil.
///
/// A contract, so French and Arabic cannot drift apart. « tu », like the rest
/// of the member space.
abstract class FollowUsCopy {
  String get title;
  String get subtitle;

  /// Pour les lecteurs d'écran : « Suivre Aji Tfarraj sur Instagram ».
  String followOn(String network);
  String get cannotOpen;
}

class FollowUsCopyFr implements FollowUsCopy {
  const FollowUsCopyFr();

  @override
  String get title => 'Suis Aji Tfarraj';
  @override
  String get subtitle =>
      'Les prochaines émissions, les coulisses et les places en avant-première.';
  @override
  String followOn(String network) => 'Suivre Aji Tfarraj sur $network';
  @override
  String get cannotOpen => 'Le lien n\'a pas pu s\'ouvrir. Réessaie.';
}

class FollowUsCopyAr implements FollowUsCopy {
  const FollowUsCopyAr();

  @override
  String get title => 'تابع Aji Tfarraj';
  @override
  String get subtitle => 'البرامج الجاية، الكواليس والبلايص قبل الجميع.';
  @override
  String followOn(String network) => 'تابع Aji Tfarraj على $network';
  @override
  String get cannotOpen => 'ما قدرناش نفتحو الرابط. عاود المحاولة.';
}
