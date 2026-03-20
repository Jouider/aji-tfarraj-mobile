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
  final String? phoneCountryCode;
  final String? phoneNumber;
  final DateTime? phoneVerifiedAt;
  final DateTime? dateOfBirth;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// User role: 'client' | 'staff' | 'admin' (null treated as 'client')
  final String? role;

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
    this.phoneCountryCode,
    this.phoneNumber,
    this.phoneVerifiedAt,
    this.dateOfBirth,
    required this.createdAt,
    required this.updatedAt,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    DateTime? phoneVerifiedAt;
    final rawPhoneVerified = json['phone_verified_at'] as String?;
    if (rawPhoneVerified != null) {
      try {
        phoneVerifiedAt = DateTime.parse(rawPhoneVerified).toUtc();
      } catch (_) {}
    }
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
      phoneCountryCode: json['phone_country_code'] as String?,
      phoneNumber: json['phone_number'] as String?,
      phoneVerifiedAt: phoneVerifiedAt,
      dateOfBirth: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      role: json['role'] as String?,
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
      'phone_country_code': phoneCountryCode,
      'phone_number': phoneNumber,
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'birthday': dateOfBirth?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'role': role,
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
    String? phoneCountryCode,
    String? phoneNumber,
    DateTime? phoneVerifiedAt,
    DateTime? dateOfBirth,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? role,
    bool clearAvatar = false,
    bool clearPhoneVerification = false,
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
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneVerifiedAt: clearPhoneVerification ? null : (phoneVerifiedAt ?? this.phoneVerifiedAt),
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }

  /// Whether the phone number has been verified
  bool get isPhoneVerified => phoneVerifiedAt != null;

  bool get isStaff => role == 'staff';
  bool get isAdmin => role == 'admin';
  bool get isStaffOrAdmin => role == 'staff' || role == 'admin';

  /// Display name: first + last if available, otherwise full name
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName'.trim();
    }
    return name;
  }
}

/// Authentication response containing token, expiry, and user
class AuthResponse {
  final String token;
  final User user;
  /// UTC expiry from the server's `expires_at` field (null if backend omits it)
  final DateTime? expiresAt;

  AuthResponse({
    required this.token,
    required this.user,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    DateTime? expiresAt;
    final raw = json['expires_at'] as String?;
    if (raw != null) {
      try {
        expiresAt = DateTime.parse(raw).toUtc();
      } catch (_) {}
    }
    return AuthResponse(
      token: json['token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      expiresAt: expiresAt,
    );
  }
}
