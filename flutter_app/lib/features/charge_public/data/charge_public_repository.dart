import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/charge_public/domain/wafacash.dart';
import 'package:aji_tfarraj/features/charge_public/domain/cp_dashboard.dart';

class ChargePublicRepository {
  final ApiClient _apiClient;

  ChargePublicRepository(this._apiClient);

  /// Fetch the charge-public dashboard.
  ///
  /// Prefers the rich `GET /api/me/charge-public/dashboard`. Until that
  /// endpoint is deployed it returns 404 — we then fall back to the existing
  /// `GET /api/me/referrals` and build a partial dashboard (no guest list /
  /// by-show / payments yet).
  Future<CpDashboard> fetchDashboard() async {
    try {
      final response = await _apiClient.get(AppConfig.chargePublicDashboard);
      return CpDashboard.fromRich(_asMap(response.data));
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 404 || code == 405) {
        return _fetchFallback();
      }
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<CpDashboard> _fetchFallback() async {
    try {
      final response = await _apiClient.get(AppConfig.myReferrals);
      return CpDashboard.fromReferralStats(_asMap(response.data));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
      return data['data'] as Map<String, dynamic>;
    }
    if (data is Map<String, dynamic>) return data;
    return const {};
  }
}

/// Les retraits Wafacash. Chaque appel renvoie l'état complet à jour : l'écran
/// n'a jamais à recoller des morceaux.
class WafacashRepository {
  final ApiClient _apiClient;

  WafacashRepository(this._apiClient);

  Future<WafacashOverview> fetch() =>
      _call(() => _apiClient.get<Map<String, dynamic>>(AppConfig.wafacash));

  Future<WafacashOverview> submitIdentity({
    required String legalName,
    required String cinNumber,
    required String frontPath,
    required String backPath,
  }) async {
    final form = FormData.fromMap({
      'legal_name': legalName.trim(),
      'cin_number': cinNumber.trim(),
      'front': await MultipartFile.fromFile(frontPath, filename: 'cin-recto.jpg'),
      'back': await MultipartFile.fromFile(backPath, filename: 'cin-verso.jpg'),
    });

    return _call(() => _apiClient.post<Map<String, dynamic>>(
          AppConfig.wafacashIdentity,
          data: form,
        ));
  }

  Future<WafacashOverview> request(int amount) =>
      _call(() => _apiClient.post<Map<String, dynamic>>(
            AppConfig.wafacashWithdrawals,
            data: {'amount': amount},
          ));

  Future<WafacashOverview> cancel(int withdrawalId) =>
      _call(() => _apiClient.post<Map<String, dynamic>>(
            '${AppConfig.wafacashWithdrawals}/$withdrawalId/cancel',
          ));

  Future<WafacashOverview> markCollected(int withdrawalId) =>
      _call(() => _apiClient.post<Map<String, dynamic>>(
            '${AppConfig.wafacashWithdrawals}/$withdrawalId/collected',
          ));

  Future<WafacashOverview> _call(
      Future<Response<Map<String, dynamic>>> Function() send) async {
    try {
      final response = await send();
      return WafacashOverview.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final wafacashRepositoryProvider = Provider<WafacashRepository>((ref) {
  return WafacashRepository(ref.watch(apiClientProvider));
});

/// L'état des retraits. Une erreur (serveur ancien, réseau) masque simplement
/// la carte : l'onglet Gains doit rester utilisable sans elle.
final wafacashProvider = FutureProvider.autoDispose<WafacashOverview>((ref) {
  return ref.watch(wafacashRepositoryProvider).fetch();
});

final chargePublicRepositoryProvider = Provider<ChargePublicRepository>((ref) {
  return ChargePublicRepository(ref.watch(apiClientProvider));
});

/// The current charge-public's dashboard data.
final cpDashboardProvider = FutureProvider<CpDashboard>((ref) async {
  return ref.watch(chargePublicRepositoryProvider).fetchDashboard();
});
