// FEATURE: Support Tickets - Service Layer
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';

class SupportService {
  final ApiClient _apiClient;

  SupportService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<SupportTicket>> getTickets() async {
    try {
      final response = await _apiClient.get(AppConfig.mySupportTickets);
      final data = response.data as List<dynamic>;
      return data
          .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<SupportTicketDetail> getTicket(int id) async {
    try {
      final response =
          await _apiClient.get(AppConfig.supportTicketDetail(id));
      return SupportTicketDetail.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.supportTickets,
        data: {'subject': subject, 'message': message},
      );
      final data = response.data as Map<String, dynamic>;
      return SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final supportServiceProvider = Provider<SupportService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SupportService(apiClient: apiClient);
});
