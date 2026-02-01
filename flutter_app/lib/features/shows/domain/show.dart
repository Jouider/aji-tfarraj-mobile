/// Show model matching backend API response
class Show {
  final int id;
  final String title;
  final String? description;
  final String city;
  final String? channel;
  final String? studio;
  final DateTime startsAt;
  final int capacity;
  final int reservedSeats;
  final bool isActive;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Show({
    required this.id,
    required this.title,
    this.description,
    required this.city,
    this.channel,
    this.studio,
    required this.startsAt,
    required this.capacity,
    required this.reservedSeats,
    required this.isActive,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Available seats count
  int get availableSeats => capacity - reservedSeats;

  /// Check if show is sold out
  bool get isSoldOut => availableSeats <= 0;

  /// Create Show from JSON (snake_case from API)
  factory Show.fromJson(Map<String, dynamic> json) {
    return Show(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      city: json['city'] as String,
      channel: json['channel'] as String?,
      studio: json['studio'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
      capacity: json['capacity'] as int,
      reservedSeats: json['reserved_seats'] as int,
      isActive: json['is_active'] as bool,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert Show to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'city': city,
      'channel': channel,
      'studio': studio,
      'starts_at': startsAt.toIso8601String(),
      'capacity': capacity,
      'reserved_seats': reservedSeats,
      'is_active': isActive,
      'image_url': imageUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() => 'Show(id: $id, title: $title, city: $city)';
}
