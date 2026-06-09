import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/rewards/domain/reward.dart';

const _kRewardsCacheKey = 'rewards_list_cache';

class RewardsRepository {
  final ApiClient _apiClient;

  /// In-memory cache of the last successful rewards list
  List<Reward>? _cachedRewards;

  RewardsRepository(this._apiClient);

  /// Fetch all available rewards — GET /api/rewards
  /// Falls back to in-memory then disk cache on network failure.
  Future<List<Reward>> fetchRewards() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/rewards');
      final raw = response.data;
      final rewards = raw is List
          ? raw.whereType<Map<String, dynamic>>().map(Reward.fromJson).toList()
          : <Reward>[];
      _cachedRewards = rewards;
      _persistCache(rewards);
      return rewards;
    } on DioException catch (e) {
      if (_cachedRewards != null) {
        if (kDebugMode) {
          debugPrint('[RewardsRepository] Network error – returning in-memory cache');
        }
        return _cachedRewards!;
      }
      final disk = await _loadCachedRewards();
      if (disk != null) {
        if (kDebugMode) {
          debugPrint('[RewardsRepository] Network error – returning disk cache');
        }
        _cachedRewards = disk;
        return disk;
      }
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Collect a reward — POST /api/rewards/{id}/collect
  /// Throws [ApiException] with a user-facing [message] on known error codes.
  Future<void> collectReward(int rewardId) async {
    try {
      await _apiClient.post<dynamic>('/api/rewards/$rewardId/collect');
    } on DioException catch (e) {
      // ApiClient throws DioException; map it so the backend `code` is readable.
      final api = ApiException.fromDioError(e);
      switch (api.code) {
        case 'INSUFFICIENT_POINTS':
          throw ApiException(
            message: 'Vous n\'avez pas assez de points.',
            statusCode: api.statusCode,
            code: api.code,
          );
        case 'DUPLICATE_PENDING':
          throw ApiException(
            message: 'Vous avez déjà demandé cette récompense.',
            statusCode: api.statusCode,
            code: api.code,
          );
        case 'REWARD_INACTIVE':
          throw ApiException(
            message: 'Cette récompense n\'est plus disponible.',
            statusCode: api.statusCode,
            code: api.code,
          );
        default:
          throw api;
      }
    } catch (e) {
      throw ApiException.from(e);
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

  Future<void> _persistCache(List<Reward> rewards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kRewardsCacheKey,
        jsonEncode(rewards.map((r) => r.toJson()).toList()),
      );
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  Future<List<Reward>?> _loadCachedRewards() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kRewardsCacheKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<Map<String, dynamic>>().map(Reward.fromJson).toList();
    } catch (_) {
      return null;
    }
  }
}

final rewardsRepositoryProvider = Provider<RewardsRepository>((ref) {
  return RewardsRepository(ref.watch(apiClientProvider));
});

/// All available rewards — kept alive so it survives navigation
final rewardsListProvider = FutureProvider.autoDispose<List<Reward>>((ref) {
  ref.keepAlive();
  return ref.watch(rewardsRepositoryProvider).fetchRewards();
});

/// The authenticated user's reward requests
final myRewardsProvider = FutureProvider<List<RewardRequest>>((ref) {
  return ref.watch(rewardsRepositoryProvider).fetchMyRewards();
});
