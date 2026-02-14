import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';

/// Repository for fetching loyalty / points data from the API
class LoyaltyRepository {
  final ApiClient _apiClient;

  /// In-memory cache of the last successful response
  PointsSummary? _cachedSummary;

  LoyaltyRepository(this._apiClient);

  /// Fetch the authenticated user's points summary.
  /// Falls back to the in-memory cache when the network call fails.
  Future<PointsSummary> fetchMyPoints() async {
    try {
      final response = await _apiClient.get<dynamic>('/api/me/points');

      final dynamic rawData = response.data;
      final Map<String, dynamic> json;

      if (rawData is Map<String, dynamic>) {
        json = rawData;
      } else {
        throw ApiException(
          message: 'Format de réponse inattendu',
          statusCode: response.statusCode,
        );
      }

      final summary = PointsSummary.fromJson(json);
      _cachedSummary = summary; // update cache on success
      return summary;
    } on DioException catch (e) {
      // If we have a cached value, return it for offline-like UX
      if (_cachedSummary != null) {
        if (kDebugMode) {
          debugPrint('[LoyaltyRepository] Network error – returning cached data');
        }
        return _cachedSummary!;
      }
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for LoyaltyRepository (singleton per app lifecycle)
final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LoyaltyRepository(apiClient);
});

/// Provider that exposes the user's points as an AsyncValue.
/// Call `ref.invalidate(myPointsProvider)` to force a refresh.
final myPointsProvider = FutureProvider<PointsSummary>((ref) async {
  final repo = ref.watch(loyaltyRepositoryProvider);
  return repo.fetchMyPoints();
});
