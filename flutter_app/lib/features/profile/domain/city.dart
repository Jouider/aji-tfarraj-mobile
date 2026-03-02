/// City with its districts, from GET /api/cities
class City {
  final String name;
  final List<String> districts;

  const City({required this.name, required this.districts});

  factory City.fromJson(Map<String, dynamic> json) {
    // Backend returns: {city: "Casablanca", districts: [...]}
    // Legacy compat also has: {province: ..., cities: [...]}
    final name = (json['city'] ?? json['province']) as String;
    final rawDistricts =
        (json['districts'] ?? json['cities']) as List<dynamic>? ?? [];
    return City(
      name: name,
      districts: rawDistricts.map((e) => e as String).toList(),
    );
  }
}
