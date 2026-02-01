import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/tickets/domain/ticket.dart';

/// Repository for Ticket-related API calls
class TicketRepository {
  final ApiClient _apiClient;

  TicketRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch the user's current ticket (returns null if no approved ticket)
  Future<Ticket?> fetchMyTicket() async {
    try {
      final response = await _apiClient.get(AppConfig.myTicket);
      
      // API returns null if no ticket exists
      if (response.data == null) {
        return null;
      }
      
      return Ticket.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // Handle 404 as no ticket
      if (e.response?.statusCode == 404) {
        return null;
      }
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for TicketRepository
final ticketRepositoryProvider = Provider<TicketRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TicketRepository(apiClient: apiClient);
});

/// AsyncNotifier for user's ticket
class MyTicketNotifier extends AsyncNotifier<Ticket?> {
  @override
  Future<Ticket?> build() async {
    return await _fetchMyTicket();
  }

  Future<Ticket?> _fetchMyTicket() async {
    final repository = ref.read(ticketRepositoryProvider);
    return await repository.fetchMyTicket();
  }

  /// Refresh ticket
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMyTicket());
  }
}

/// Provider for user's ticket
final myTicketProvider = AsyncNotifierProvider<MyTicketNotifier, Ticket?>(() {
  return MyTicketNotifier();
});
