import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/rewards/domain/reward.dart';

class RewardsRepository {
  final ApiClient _apiClient;

  RewardsRepository(this._apiClient);

  /// Fetch all available rewards — GET /api/rewards
  Future<List<Reward>> fetchRewards() async {
    final response = await _apiClient.get<dynamic>('/api/rewards');
    final raw = response.data;
    if (raw is List) {
      return raw.whereType<Map<String, dynamic>>().map(Reward.fromJson).toList();
    }
    return [];
  }

  /// Collect a reward — POST /api/rewards/{id}/collect
  /// Throws [ApiException] with a user-facing [message] on known error codes.
  Future<void> collectReward(int rewardId) async {
    try {
      await _apiClient.post<dynamic>('/api/rewards/$rewardId/collect');
    } on ApiException catch (e) {
      switch (e.code) {
        case 'INSUFFICIENT_POINTS':
          throw ApiException(
            message: 'Vous n\'avez pas assez de points.',
            statusCode: e.statusCode,
            code: e.code,
          );
        case 'DUPLICATE_PENDING':
          throw ApiException(
            message: 'Vous avez déjà demandé cette récompense.',
            statusCode: e.statusCode,
            code: e.code,
          );
        case 'REWARD_INACTIVE':
          throw ApiException(
            message: 'Cette récompense n\'est plus disponible.',
            statusCode: e.statusCode,
            code: e.code,
          );
        default:
          rethrow;
      }
    }
  }

  /// Fetch the authenticated user's reward requests — GET /api/me/rewards
  Future<List<RewardRequest>> fetchMyRewards() async {
    final response = await _apiClient.get<dynamic>('/api/me/rewards');
    final raw = response.data;
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(RewardRequest.fromJson)
          .toList();
    }
    return [];
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository(ref.watch(apiClientProvider));
});

/// All available rewards
final rewardsListProvider = FutureProvider<List<Reward>>((ref) {
  return ref.watch(rewardsRepositoryProvider).fetchRewards();
});

/// The authenticated user's reward requests
final myRewardsProvider = FutureProvider<List<RewardRequest>>((ref) {
  return ref.watch(rewardsRepositoryProvider).fetchMyRewards();
});
