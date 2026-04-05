/// City with its districts, from GET /api/cities
class City {
  final String name;
  final String? nameAr;
  final List<String> districts;
  final List<String> districtsAr;

  const City({
    required this.name,
    this.nameAr,
    required this.districts,
    this.districtsAr = const [],
  });

  /// Localized city name — falls back to French if Arabic is null.
  String localizedName(bool isAr) =>
      (isAr && nameAr != null && nameAr!.isNotEmpty) ? nameAr! : name;

  /// Localized district name — falls back to French if Arabic list is absent or index missing.
  String localizedDistrict(String district, bool isAr) {
    if (!isAr || districtsAr.isEmpty) return district;
    final idx = districts.indexOf(district);
    if (idx >= 0 && idx < districtsAr.length) return districtsAr[idx];
    return district;
  }

  factory City.fromJson(Map<String, dynamic> json) {
    // Backend returns: {city: "Casablanca", city_ar: "...", districts: [...], districts_ar: [...]}
    // Legacy compat also has: {province: ..., cities: [...]}
    final name = (json['city'] ?? json['province']) as String;
    final rawDistricts =
        (json['districts'] ?? json['cities']) as List<dynamic>? ?? [];
    final rawDistrictsAr =
        (json['districts_ar']) as List<dynamic>? ?? [];
    return City(
      name: name,
      nameAr: json['city_ar'] as String?,
      districts: rawDistricts.map((e) => e as String).toList(),
      districtsAr: rawDistrictsAr.map((e) => e as String).toList(),
    );
  }
}
