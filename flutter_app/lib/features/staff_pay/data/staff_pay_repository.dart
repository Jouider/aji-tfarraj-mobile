import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/staff_pay/domain/staff_pay.dart';

class StaffPayRepository {
  final ApiClient _apiClient;

  StaffPayRepository(this._apiClient);

  Future<StaffPayOverview> fetch() async {
    try {
      final response =
          await _apiClient.get<Map<String, dynamic>>(AppConfig.staffPay);
      return StaffPayOverview.fromJson(response.data ?? const {});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final staffPayRepositoryProvider = Provider<StaffPayRepository>((ref) {
  return StaffPayRepository(ref.watch(apiClientProvider));
});

final staffPayProvider = FutureProvider.autoDispose<StaffPayOverview>((ref) {
  return ref.watch(staffPayRepositoryProvider).fetch();
});
