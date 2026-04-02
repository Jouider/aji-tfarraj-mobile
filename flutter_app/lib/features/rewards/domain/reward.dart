/// A single reward available for collection
class Reward {
  final int id;
  final String title;
  final String? titleAr;
  final String description;
  final String? descriptionAr;
  final String? imageUrl;
  final int pointsRequired;
  final bool canCollect;

  const Reward({
    required this.id,
    required this.title,
    this.titleAr,
    required this.description,
    this.descriptionAr,
    this.imageUrl,
    required this.pointsRequired,
    required this.canCollect,
  });

  /// Localized title — falls back to French if AR is null
  String localizedTitle(bool isAr) =>
      (isAr && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : title;

  /// Localized description — falls back to French if AR is null
  String localizedDescription(bool isAr) =>
      (isAr && descriptionAr != null && descriptionAr!.isNotEmpty)
          ? descriptionAr!
          : description;

  factory Reward.fromJson(Map<String, dynamic> json) {
    return Reward(
      id: _parseInt(json['id']),
      title: (json['title'] as String?) ?? '',
      titleAr: json['title_ar'] as String?,
      description: (json['description'] as String?) ?? '',
      descriptionAr: json['description_ar'] as String?,
      imageUrl: json['image_url'] as String?,
      pointsRequired: _parseInt(json['points_required']),
      canCollect: json['can_collect'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'title_ar': titleAr,
        'description': description,
        'description_ar': descriptionAr,
        'image_url': imageUrl,
        'points_required': pointsRequired,
        'can_collect': canCollect,
      };

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
  final String? rewardTitleAr;
  final String status;
  final DateTime requestedAt;

  const RewardRequest({
    required this.id,
    required this.rewardTitle,
    this.rewardTitleAr,
    required this.status,
    required this.requestedAt,
  });

  /// Localized reward title — falls back to French if AR is null
  String localizedTitle(bool isAr) =>
      (isAr && rewardTitleAr != null && rewardTitleAr!.isNotEmpty)
          ? rewardTitleAr!
          : rewardTitle;

  factory RewardRequest.fromJson(Map<String, dynamic> json) {
    final rewardMap = json['reward'] is Map<String, dynamic>
        ? json['reward'] as Map<String, dynamic>
        : <String, dynamic>{};

    return RewardRequest(
      id: _parseInt(json['id']),
      rewardTitle: (rewardMap['title'] as String?) ?? '',
      rewardTitleAr: rewardMap['title_ar'] as String?,
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
