import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/on_site/domain/on_site_models.dart';

/// On-site ("inscription sur place") registration — staff at the door open a
/// real account for someone who turned up without booking, and check them in.
///
/// Backed by the same service as the admin dashboard, so both stay in step.
class OnSiteRepository {
  final ApiClient _apiClient;

  OnSiteRepository(this._apiClient);

  /// Shows + episodes currently open for registration.
  ///
  /// The backend keeps an episode listed for 12h after it starts: a recording
  /// under way is exactly when people are still turning up at the door.
  Future<List<OnSiteShow>> fetchEpisodes() async {
    try {
      final response = await _apiClient
          .get<Map<String, dynamic>>('/api/staff/on-site/episodes');
      final shows = response.data?['shows'] as List<dynamic>? ?? [];
      return shows
          .map((s) => OnSiteShow.fromJson(s as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Search chargés publics so staff can pick who brought the person.
  Future<List<ChargePublicOption>> searchChargePublics({String query = ''}) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/staff/charge-publics',
        queryParameters: query.isEmpty ? null : {'q': query},
      );
      final list = response.data?['charge_publics'] as List<dynamic>? ?? [];
      return list
          .map((e) => ChargePublicOption.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Register the person and check them in.
  ///
  /// [photoPath] is required — the door photo is the only picture the system
  /// gets of a walk-in, and face indexing depends on it.
  Future<OnSiteRegistrationResult> register({
    required int episodeId,
    required String firstName,
    required String lastName,
    required String gender,
    required DateTime birthday,
    required String cityName,
    required String district,
    required String photoPath,
    int? chargePublicId,
    int? returnPointId,
    String? phoneNumber,
    String? email,
  }) async {
    try {
      final form = FormData.fromMap({
        'episode_id': episodeId,
        'first_name': firstName,
        'last_name': lastName,
        'gender': gender,
        // The API expects a plain date, not an ISO timestamp.
        'birthday': _formatDate(birthday),
        'city_name': cityName,
        'district': district,
        if (chargePublicId != null) 'charge_public_id': chargePublicId,
        // Absent = « repart par ses propres moyens » : le serveur enregistre
        // null, ce qui est une réponse, pas une absence de réponse.
        if (returnPointId != null) 'return_point_id': returnPointId,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
        'photo': await MultipartFile.fromFile(photoPath, filename: 'door.jpg'),
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/staff/on-site-registration',
        data: form,
      );
      return OnSiteRegistrationResult.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

final onSiteRepositoryProvider = Provider<OnSiteRepository>((ref) {
  return OnSiteRepository(ref.watch(apiClientProvider));
});

/// Episodes open for on-site registration. Auto-disposed so re-entering the
/// screen re-fetches — seat counts move fast at the door.
final onSiteEpisodesProvider =
    FutureProvider.autoDispose<List<OnSiteShow>>((ref) {
  return ref.read(onSiteRepositoryProvider).fetchEpisodes();
});

/// Chargés publics matching a search term ('' = the first 20, alphabetical).
final chargePublicSearchProvider = FutureProvider.autoDispose
    .family<List<ChargePublicOption>, String>((ref, query) {
  return ref.read(onSiteRepositoryProvider).searchChargePublics(query: query);
});
