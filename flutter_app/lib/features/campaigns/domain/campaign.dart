/// Les campagnes dans l'app : `GET /api/campaigns` (voir `docs/campaigns.md`,
/// et `docs/app-campaigns.md` côté backend).
///
/// Le serveur décide de tout — dates, âge, plateforme, version, nombre
/// d'affichages déjà vus. L'app affiche ce qu'il renvoie, et fait au toucher
/// ce que dit `action`.
library;

int? _int(Object? v) => (v as num?)?.toInt();

Map<String, dynamic> _map(Object? v) =>
    v is Map ? Map<String, dynamic>.from(v) : const <String, dynamic>{};

/// Un texte en deux langues : `{ "fr": …, "ar": … }`.
class CampaignText {
  const CampaignText({this.fr, this.ar});

  final String? fr;
  final String? ar;

  /// La langue de l'app ; vide, l'autre ; les deux vides : null.
  String? pick({required bool arabic}) {
    String? clean(String? s) =>
        (s == null || s.trim().isEmpty) ? null : s.trim();
    final first = clean(arabic ? ar : fr);
    return first ?? clean(arabic ? fr : ar);
  }

  factory CampaignText.fromJson(Object? json) {
    final m = _map(json);
    return CampaignText(fr: m['fr'] as String?, ar: m['ar'] as String?);
  }
}

/// Ce que fait l'app au toucher.
class CampaignAction {
  const CampaignAction({
    required this.type,
    this.url,
    this.showId,
    this.episodeId,
    this.screen,
  });

  static const none = CampaignAction(type: 'none');

  /// `url` | `show` | `episode` | `screen` | `none` — une autre valeur : rien.
  final String type;
  final String? url;
  final int? showId;
  final int? episodeId;
  final String? screen;

  factory CampaignAction.fromJson(Object? json) {
    final m = _map(json);
    return CampaignAction(
      type: (m['type'] as String?) ?? 'none',
      url: m['url'] as String?,
      showId: _int(m['show_id']),
      episodeId: _int(m['episode_id']),
      screen: m['screen'] as String?,
    );
  }
}

/// Une fenêtre (`popup`) ou une bannière (`banner`).
class Campaign {
  const Campaign({
    required this.id,
    required this.placement,
    required this.imageUrl,
    this.title = const CampaignText(),
    this.body = const CampaignText(),
    this.cta = const CampaignText(),
    this.action = CampaignAction.none,
    this.canHideForever = false,
  });

  static const popup = 'popup';
  static const banner = 'banner';

  final int id;
  final String placement;
  final String imageUrl;
  final CampaignText title;
  final CampaignText body;
  final CampaignText cta;
  final CampaignAction action;

  /// Le lien « Ne plus afficher » sous la fenêtre.
  final bool canHideForever;

  /// Sans id ni image, rien à afficher : l'entrée est ignorée.
  static Campaign? tryParse(Object? json, String placement) {
    final m = _map(json);
    final id = _int(m['id']);
    final image = m['image_url'] as String?;
    if (id == null || image == null || image.isEmpty) return null;
    return Campaign(
      id: id,
      placement: (m['placement'] as String?) ?? placement,
      imageUrl: image,
      title: CampaignText.fromJson(m['title']),
      body: CampaignText.fromJson(m['body']),
      cta: CampaignText.fromJson(m['cta']),
      action: CampaignAction.fromJson(m['action']),
      canHideForever: m['can_hide_forever'] as bool? ?? false,
    );
  }
}

/// La réponse : une fenêtre ou rien, et jusqu'à 5 bannières déjà triées.
class CampaignFeed {
  const CampaignFeed({this.popup, this.banners = const []});

  static const empty = CampaignFeed();

  final Campaign? popup;
  final List<Campaign> banners;

  factory CampaignFeed.fromJson(Map<String, dynamic> json) => CampaignFeed(
        popup: Campaign.tryParse(json['popup'], Campaign.popup),
        banners: (json['banners'] as List? ?? const [])
            .map((b) => Campaign.tryParse(b, Campaign.banner))
            .whereType<Campaign>()
            .take(5)
            .toList(),
      );
}
