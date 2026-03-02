/// User model for authentication
class User {
  final int id;
  final String name;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? cityName;
  final String? district;
  final String? avatarUrl;
  final bool profileComplete;
  final List<String> missingProfileFields;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.firstName,
    this.lastName,
    this.cityName,
    this.district,
    this.avatarUrl,
    this.profileComplete = true,
    this.missingProfileFields = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      cityName: json['city_name'] as String?,
      district: json['district'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      profileComplete: json['profile_complete'] as bool? ?? true,
      missingProfileFields: (json['missing_profile_fields'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'city_name': cityName,
      'district': district,
      'avatar_url': avatarUrl,
      'profile_complete': profileComplete,
      'missing_profile_fields': missingProfileFields,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? firstName,
    String? lastName,
    String? cityName,
    String? district,
    String? avatarUrl,
    bool? profileComplete,
    List<String>? missingProfileFields,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearAvatar = false,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cityName: cityName ?? this.cityName,
      district: district ?? this.district,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      profileComplete: profileComplete ?? this.profileComplete,
      missingProfileFields: missingProfileFields ?? this.missingProfileFields,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Display name: first + last if available, otherwise full name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return name;
  }
}

/// Authentication response containing token and user
class AuthResponse {
  final String token;
  final User user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
