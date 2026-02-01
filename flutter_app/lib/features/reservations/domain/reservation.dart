import 'package:aji_tfarraj/features/shows/domain/show.dart';

/// Reservation model matching backend API response
class Reservation {
  final int id;
  final int userId;
  final int showId;
  final int seats;
  final String status;
  final String? rejectionReason;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Show? show;

  Reservation({
    required this.id,
    required this.userId,
    required this.showId,
    required this.seats,
    required this.status,
    this.rejectionReason,
    this.expiresAt,
    required this.createdAt,
    this.updatedAt,
    this.show,
  });

  /// Create Reservation from JSON (snake_case from API)
  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      showId: json['show_id'] as int,
      seats: json['seats'] as int,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      show: json['show'] != null
          ? Show.fromJson(json['show'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert Reservation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'show_id': showId,
      'seats': seats,
      'status': status,
      'rejection_reason': rejectionReason,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'show': show?.toJson(),
    };
  }

  @override
  String toString() => 'Reservation(id: $id, showId: $showId, status: $status)';
}
