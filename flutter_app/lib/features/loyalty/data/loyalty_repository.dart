import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/loyalty/domain/points_summary.dart';

const _kCacheKey = 'loyalty_points_cache';

/// Repository for fetching loyalty / points data from the API
class LoyaltyRepository {
  final ApiClient _apiClient;

  /// In-memory cache of the last successful response
  PointsSummary? _cachedSummary;

  LoyaltyRepository(this._apiClient);

  /// Fetch the authenticated user's points summary.
  /// Falls back to disk cache (then in-memory) when the network call fails.
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
      _cachedSummary = summary;
      _persistCache(summary);
      return summary;
    } on DioException catch (e) {
      // Prefer in-memory cache, then fall back to disk
      if (_cachedSummary != null) {
        if (kDebugMode) {
          debugPrint('[LoyaltyRepository] Network error – returning in-memory cache');
        }
        return _cachedSummary!;
      }
      final disk = await _loadCachedSummary();
      if (disk != null) {
        if (kDebugMode) {
          debugPrint('[LoyaltyRepository] Network error – returning disk cache');
        }
        _cachedSummary = disk;
        return disk;
      }
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> _persistCache(PointsSummary summary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kCacheKey, jsonEncode(summary.toJson()));
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  Future<PointsSummary?> _loadCachedSummary() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kCacheKey);
      if (raw == null) return null;
      return PointsSummary.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
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
