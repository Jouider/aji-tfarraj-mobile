import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/referral/domain/referral_link.dart';
import 'package:aji_tfarraj/features/referral/domain/referral_stats.dart';
import 'package:aji_tfarraj/features/referral/domain/resolved_referral.dart';

class ReferralRepository {
  final ApiClient _apiClient;

  ReferralRepository(this._apiClient);

  /// Generate (or retrieve existing) magic link for a show
  Future<ReferralLink> generateLink({required int showId}) async {
    try {
      final response = await _apiClient.post(
        AppConfig.myReferralLinks,
        data: {'show_id': showId},
      );
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return ReferralLink.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ReferralLink.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch all magic links created by the current user
  Future<List<ReferralLink>> fetchMyLinks() async {
    try {
      final response = await _apiClient.get(AppConfig.myReferralLinks);
      final data = response.data;

      final List<dynamic> list;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        list = data['data'] as List<dynamic>;
      } else if (data is List<dynamic>) {
        list = data;
      } else {
        return [];
      }

      return list
          .map((json) => ReferralLink.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Resolve a magic link token (public — no auth required).
  /// Uses a raw Dio instance to skip the auth interceptor.
  Future<ResolvedReferral> resolveLink(String token) async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.currentBaseUrl));
      final response =
          await dio.get(AppConfig.resolveReferralLink(token));
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return ResolvedReferral.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ResolvedReferral.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Fetch the current user's referral stats
  Future<ReferralStats> fetchMyReferralStats() async {
    try {
      final response = await _apiClient.get(AppConfig.myReferrals);
      final data = response.data;
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        return ReferralStats.fromJson(data['data'] as Map<String, dynamic>);
      }
      return ReferralStats.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Singleton provider for [ReferralRepository]
final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReferralRepository(apiClient);
});

/// Provider for the user's referral links list
final myReferralLinksProvider = FutureProvider<List<ReferralLink>>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.fetchMyLinks();
});

/// Provider for the user's referral stats
final myReferralStatsProvider = FutureProvider<ReferralStats>((ref) async {
  final repo = ref.watch(referralRepositoryProvider);
  return repo.fetchMyReferralStats();
});

/// State provider to hold a pending referral code from a deep link
/// so it persists through auth flow and gets pre-filled on reservation
final pendingReferralCodeProvider = StateProvider<String?>((ref) => null);
