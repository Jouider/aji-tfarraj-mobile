/// Un compte officiel d'Aji Tfarraj, tapé par un admin dans le tableau de bord
/// et servi par `GET /api/app-config → social_links`.
class SocialLink {
  const SocialLink({required this.network, required this.url});

  /// `instagram`, `tiktok`, `facebook`, `youtube`, `snapchat` ou `whatsapp`.
  final String network;
  final Uri url;

  static const known = [
    'instagram',
    'tiktok',
    'facebook',
    'youtube',
    'snapchat',
    'whatsapp',
  ];

  String get label => switch (network) {
        'instagram' => 'Instagram',
        'tiktok' => 'TikTok',
        'facebook' => 'Facebook',
        'youtube' => 'YouTube',
        'snapchat' => 'Snapchat',
        'whatsapp' => 'WhatsApp',
        _ => network,
      };

  /// Lit le bloc `social_links` d'`app-config`, dans l'ordre du serveur.
  ///
  /// Un réseau que cette version ne connaît pas, une adresse qui n'est pas en
  /// https ou un vieux serveur sans le bloc : rien, plutôt qu'un bouton qui
  /// n'ouvre rien.
  static List<SocialLink> fromAppConfig(Object? json) {
    final raw = json is Map ? json['social_links'] : null;
    if (raw is! List) return const [];

    final links = <SocialLink>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final network = item['network'];
      final url = Uri.tryParse('${item['url'] ?? ''}');
      if (network is! String || !known.contains(network)) continue;
      if (url == null || url.scheme != 'https' || url.host.isEmpty) continue;
      if (links.any((l) => l.network == network)) continue;
      links.add(SocialLink(network: network, url: url));
    }
    return links;
  }
}
