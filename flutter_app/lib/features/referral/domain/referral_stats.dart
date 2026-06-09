/// Aggregated referral statistics for the current user
class ReferralStats {
  final int totalInvited;
  final int totalAttended;
  final int pending;
  final int totalRewards;
  final String rewardType;
  final int totalPoints;

  ReferralStats({
    this.totalInvited = 0,
    this.totalAttended = 0,
    this.pending = 0,
    this.totalRewards = 0,
    this.rewardType = 'points',
    this.totalPoints = 0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      totalInvited: json['total_invited'] as int? ?? 0,
      totalAttended: json['total_attended'] as int? ?? 0,
      pending: json['pending'] as int? ?? 0,
      totalRewards: json['total_rewards'] as int? ?? 0,
      rewardType: json['reward_type'] as String? ?? 'points',
      totalPoints: json['total_points'] as int? ?? 0,
    );
  }
}
