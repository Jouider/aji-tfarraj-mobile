/// A magic referral link generated for a specific show
class ReferralLink {
  final int? id;
  final String referralLink;
  final String token;
  final ReferralLinkShow show;
  final DateTime expiresAt;
  final int clickCount;
  final int conversionCount;
  final bool isExpired;

  ReferralLink({
    this.id,
    required this.referralLink,
    required this.token,
    required this.show,
    required this.expiresAt,
    this.clickCount = 0,
    this.conversionCount = 0,
    this.isExpired = false,
  });

  factory ReferralLink.fromJson(Map<String, dynamic> json) {
    return ReferralLink(
      id: json['id'] as int?,
      referralLink: json['referral_link'] as String,
      token: json['token'] as String,
      show: ReferralLinkShow.fromJson(json['show'] as Map<String, dynamic>),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      clickCount: json['click_count'] as int? ?? 0,
      conversionCount: json['conversion_count'] as int? ?? 0,
      isExpired: json['is_expired'] as bool? ?? false,
    );
  }
}

/// Minimal show info embedded in a referral link response
class ReferralLinkShow {
  final int id;
  final String title;
  final String? titleAr;
  final DateTime startsAt;

  ReferralLinkShow({
    required this.id,
    required this.title,
    this.titleAr,
    required this.startsAt,
  });

  String localizedTitle(bool isAr) =>
      (isAr && titleAr != null && titleAr!.isNotEmpty) ? titleAr! : title;

  factory ReferralLinkShow.fromJson(Map<String, dynamic> json) {
    return ReferralLinkShow(
      id: json['id'] as int,
      title: json['title'] as String,
      titleAr: json['title_ar'] as String?,
      startsAt: DateTime.parse(json['starts_at'] as String),
    );
  }
}
