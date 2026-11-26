/// Copy for the in-app campaigns (pop-up at launch, home banners). Most of
/// the text comes from the server, in both languages; these are the app's
/// own words around it.
abstract class CampaignsCopy {
  /// Le bouton quand la campagne n'a pas de texte.
  String get defaultCta;
  String get neverShowAgain;
  String get close;
}

class CampaignsCopyFr implements CampaignsCopy {
  const CampaignsCopyFr();

  @override
  String get defaultCta => 'Voir';
  @override
  String get neverShowAgain => 'Ne plus afficher';
  @override
  String get close => 'Fermer';
}

class CampaignsCopyAr implements CampaignsCopy {
  const CampaignsCopyAr();

  @override
  String get defaultCta => 'شوف';
  @override
  String get neverShowAgain => 'ما تبقاش تبين ليا هادي';
  @override
  String get close => 'سد';
}
