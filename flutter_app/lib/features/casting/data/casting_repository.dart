import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_models.dart';
import 'package:aji_tfarraj/features/casting/domain/casting_pose.dart';

class CastingRepository {
  CastingRepository(this._api);

  final ApiClient _api;

  // ── The member's own book ─────────────────────────────────────────────────

  /// Throws an [ApiException] carrying `MINOR_NOT_ELIGIBLE` or
  /// `BIRTHDAY_REQUIRED` when the account may not hold a book — the screen
  /// tells those two apart, because only one of them the person can fix.
  Future<CastingBook> book() async {
    try {
      final response =
          await _api.get<Map<String, dynamic>>('/api/me/casting-profile');
      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CastingBook> saveMeasurements({
    int? heightCm,
    int? weightKg,
    String? clothingSize,
    int? shoeSize,
  }) async {
    try {
      final response = await _api.put<Map<String, dynamic>>(
        '/api/me/casting-profile',
        data: {
          'height_cm': heightCm,
          'weight_kg': weightKg,
          'clothing_size': clothingSize,
          'shoe_size': shoeSize,
        },
      );
      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Sends one shot into its slot. Re-sending a pose replaces what was there.
  Future<CastingBook> uploadPhoto({
    required CastingPose pose,
    required String photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'pose': pose.key,
        'photo': await MultipartFile.fromFile(
          photoPath,
          filename: '${pose.key}.jpg',
        ),
      });

      final response = await _api.post<Map<String, dynamic>>(
        '/api/me/casting-profile/photos',
        data: form,
      );
      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CastingBook> deletePhoto(CastingPose pose) async {
    try {
      final response = await _api.delete<Map<String, dynamic>>(
        '/api/me/casting-profile/photos/${pose.key}',
      );
      return CastingBook.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  // ── Calls ─────────────────────────────────────────────────────────────────

  Future<CastingFeed> feed({CastingType? type}) async {
    try {
      final response = await _api.get<Map<String, dynamic>>(
        '/api/castings',
        queryParameters: type != null ? {'type': type.key} : null,
      );
      return CastingFeed.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> apply({required int castingId, String? note}) async {
    try {
      await _api.post<Map<String, dynamic>>(
        '/api/castings/$castingId/apply',
        data: {if (note != null && note.isNotEmpty) 'note': note},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<MyApplication>> myApplications() async {
    try {
      final response = await _api
          .get<Map<String, dynamic>>('/api/me/casting-applications');
      return (response.data?['applications'] as List<dynamic>? ?? const [])
          .map((e) => MyApplication.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> withdraw(int applicationId) async {
    try {
      await _api.delete<Map<String, dynamic>>(
        '/api/me/casting-applications/$applicationId',
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final castingRepositoryProvider = Provider<CastingRepository>((ref) {
  return CastingRepository(ref.watch(apiClientProvider));
});

/// The book. autoDispose so re-entering the section re-reads it: photos are
/// added from this same screen and the state must not go stale behind them.
final castingBookProvider = FutureProvider.autoDispose<CastingBook>((ref) {
  return ref.watch(castingRepositoryProvider).book();
});

/// Open calls, optionally narrowed to one kind.
final castingFeedProvider =
    FutureProvider.autoDispose.family<CastingFeed, CastingType?>((ref, type) {
  return ref.watch(castingRepositoryProvider).feed(type: type);
});

final myApplicationsProvider =
    FutureProvider.autoDispose<List<MyApplication>>((ref) {
  return ref.watch(castingRepositoryProvider).myApplications();
});
