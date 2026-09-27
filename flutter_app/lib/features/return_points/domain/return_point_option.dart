/// Un arrêt que la navette dessert après un tournage.
///
/// La même liste sert à trois endroits : au moment de réserver (la personne dit
/// où elle rentre), à l'inscription sur place (le staff le demande à la porte),
/// et au scan (elle a changé d'avis). D'où ce modèle partagé plutôt que trois
/// copies qui divergent.
///
/// **Une liste vide veut dire qu'il n'y a pas de navette ce soir-là** : la
/// question ne doit alors pas être posée du tout.
class ReturnPointOption {
  final int id;
  final String name;
  final String? nameAr;

  /// Le repère qui permet de trouver l'arrêt — « devant la pharmacie ».
  final String? landmark;

  const ReturnPointOption({
    required this.id,
    required this.name,
    this.nameAr,
    this.landmark,
  });

  /// Nom localisé — retombe sur le français quand l'arabe n'est pas renseigné.
  String localizedName(bool isAr) =>
      (isAr && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  /// L'arrêt répond-il à ce qu'on tape ?
  ///
  /// Cherche dans les deux langues et dans le repère, pas seulement dans le
  /// nom affiché : un scanner marocain tape « ain » aussi bien que « عين »,
  /// et le membre se souvient souvent du repère — « la pharmacie » — plutôt
  /// que du nom officiel de l'arrêt.
  ///
  /// Les accents sont ignorés : « témara » doit trouver « Temara ».
  bool matches(String query) {
    final needle = _fold(query);
    if (needle.isEmpty) return true;

    return [name, nameAr, landmark]
        .whereType<String>()
        .any((field) => _fold(field).contains(needle));
  }

  static const _accents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ç': 'c',
  };

  static String _fold(String value) {
    final lower = value.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }

    return buffer.toString();
  }

  factory ReturnPointOption.fromJson(Map<String, dynamic> json) =>
      ReturnPointOption(
        id: json['id'] as int,
        name: json['name'] as String? ?? '',
        nameAr: json['name_ar'] as String?,
        landmark: json['landmark'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'name_ar': nameAr,
        'landmark': landmark,
      };

  /// Ce que le serveur renvoie sous `return_points`, tel quel.
  static List<ReturnPointOption> listFrom(Object? json) =>
      (json is List ? json : const [])
          .whereType<Map<String, dynamic>>()
          .map(ReturnPointOption.fromJson)
          .toList();
}
