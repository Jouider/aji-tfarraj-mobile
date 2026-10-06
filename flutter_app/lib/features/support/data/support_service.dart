// FEATURE: Support — conversations with the Aji Tfarraj team.
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/support/domain/support_ticket.dart';

class SupportService {
  final ApiClient _apiClient;

  SupportService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<List<SupportTicket>> getTickets() => _guard(() async {
        final response = await _apiClient.get(AppConfig.mySupportTickets);
        return (response.data as List<dynamic>)
            .map((json) => SupportTicket.fromJson(json as Map<String, dynamic>))
            .toList();
      });

  /// Opens a conversation: a subject and its first message.
  Future<SupportTicket> createTicket({
    required String subject,
    required String message,
  }) =>
      _guard(() async {
        final response = await _apiClient.post(
          AppConfig.supportTickets,
          data: {'subject': subject, 'message': message},
        );
        final data = response.data as Map<String, dynamic>;
        return SupportTicket.fromJson(data['ticket'] as Map<String, dynamic>);
      });

  /// The messages after [after] — all of them with 0. Opening the thread
  /// marks the team's replies as read.
  Future<SupportThreadUpdate> getMessages(int ticketId, {int after = 0}) =>
      _guard(() async {
        final response = await _apiClient.get(
          AppConfig.supportTicketMessages(ticketId),
          queryParameters: {'after': after},
        );
        return SupportThreadUpdate.fromJson(
            response.data as Map<String, dynamic>);
      });

  Future<({String status, SupportMessage message})> sendMessage(
    int ticketId,
    String body,
  ) =>
      _guard(() async {
        final response = await _apiClient.post(
          AppConfig.supportTicketMessages(ticketId),
          data: {'body': body},
        );
        final data = response.data as Map<String, dynamic>;
        return (
          status: data['status'] as String,
          message:
              SupportMessage.fromJson(data['message'] as Map<String, dynamic>),
        );
      });

  /// Replies from the team not opened yet, across all conversations.
  Future<int> unreadCount() => _guard(() async {
        final response = await _apiClient.get(AppConfig.supportUnread);
        return ((response.data as Map<String, dynamic>)['count'] as num)
            .toInt();
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
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

/// The badge on the way into support. Refreshed by a support push.
final supportUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  ref.watch(supportPushTickProvider);
  try {
    return await ref.read(supportServiceProvider).unreadCount();
  } catch (_) {
    // A badge is not worth an error: no count, no badge.
    return 0;
  }
});

/// Bumped by every support push, so whatever shows support refreshes.
final supportPushTickProvider = StateProvider<int>((ref) => 0);

/// The conversation on screen right now, if any: its push needs no banner.
final openSupportTicketProvider = StateProvider<int?>((ref) => null);
