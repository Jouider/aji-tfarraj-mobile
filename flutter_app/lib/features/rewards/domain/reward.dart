/// A single reward available for collection
class Reward {
  final int id;
  final String title;
  final String description;
  final String? imageUrl;
  final int pointsRequired;
  final bool canCollect;

  const Reward({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    required this.pointsRequired,
    required this.canCollect,
  });

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: _parseInt(json['id']),
      title: (json['title'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      imageUrl: json['image_url'] as String?,
      pointsRequired: _parseInt(json['points_required']),
      canCollect: json['can_collect'] == true,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// A user's reward request (from /api/me/rewards)
class RewardRequest {
  final int id;
  final String rewardTitle;
  final String status;
  final DateTime requestedAt;

  const RewardRequest({
    required this.id,
    required this.rewardTitle,
    required this.status,
    required this.requestedAt,
  });

  factory RewardRequest.fromJson(Map<String, dynamic> json) {
    final rewardMap = json['reward'] is Map<String, dynamic>
        ? json['reward'] as Map<String, dynamic>
        : <String, dynamic>{};

    return RewardRequest(
      id: _parseInt(json['id']),
      rewardTitle: (rewardMap['title'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      requestedAt: _parseDateTime(json['requested_at']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
