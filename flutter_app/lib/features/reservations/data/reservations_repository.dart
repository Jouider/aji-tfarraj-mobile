import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/config/app_config.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/reservations/domain/reservation.dart';

/// Repository for Reservation-related API calls
class ReservationsRepository {
  final ApiClient _apiClient;

  ReservationsRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  /// Fetch all reservations for the authenticated user
  /// Handles both paginated { data: [...] } and legacy array responses
  Future<List<Reservation>> fetchMyReservations() async {
    try {
      final response = await _apiClient.get(AppConfig.myReservations);
      final data = response.data;

      // Handle paginated response: { data: [...], meta: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data')) {
        final List<dynamic> reservationsData = data['data'] as List<dynamic>;
        return reservationsData
            .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Handle non-paginated response: direct array
      if (data is List<dynamic>) {
        return data
            .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Fallback: return empty list
      return [];
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a new reservation for an episode
  Future<Reservation> createReservation({
    required int episodeId,
    String? referralCode,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.reservations,
        data: {
          'episode_id': episodeId,
          if (referralCode != null && referralCode.isNotEmpty)
            'referral_code': referralCode,
        },
      );
      final data = response.data;
      
      // Handle wrapped response: { data: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data') && data['data'] is Map) {
        return Reservation.fromJson(data['data'] as Map<String, dynamic>);
      }
      
      return Reservation.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get details of a specific reservation
  Future<Reservation> fetchReservationDetail(int id) async {
    try {
      final response = await _apiClient.get(AppConfig.reservationDetail(id));
      final data = response.data;
      
      // Handle wrapped response: { data: {...} }
      if (data is Map<String, dynamic> && data.containsKey('data') && data['data'] is Map) {
        return Reservation.fromJson(data['data'] as Map<String, dynamic>);
      }
      
      return Reservation.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Cancel a reservation
  Future<void> cancelReservation(int id) async {
    try {
      await _apiClient.post(AppConfig.cancelReservation(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

/// Provider for ReservationsRepository
final reservationsRepositoryProvider = Provider<ReservationsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReservationsRepository(apiClient: apiClient);
});

/// AsyncNotifier for user's reservations list
class MyReservationsNotifier extends AsyncNotifier<List<Reservation>> {
  @override
  Future<List<Reservation>> build() async {
    return await _fetchMyReservations();
  }

  Future<List<Reservation>> _fetchMyReservations() async {
    final repository = ref.read(reservationsRepositoryProvider);
    return await repository.fetchMyReservations();
  }

  /// Refresh reservations list
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchMyReservations());
  }

  /// Create a new reservation and refresh the list
  Future<Reservation> createReservation({
    required int episodeId,
    String? referralCode,
  }) async {
    final repository = ref.read(reservationsRepositoryProvider);
    final reservation = await repository.createReservation(
      episodeId: episodeId,
      referralCode: referralCode,
    );
    // Refresh the list after creating
    await refresh();
    return reservation;
  }

  /// Cancel a reservation and refresh the list
  Future<void> cancelReservation(int id) async {
    final repository = ref.read(reservationsRepositoryProvider);
    await repository.cancelReservation(id);
    // Refresh the list after cancelling
    await refresh();
  }
}

/// Provider for user's reservations
final myReservationsProvider =
    AsyncNotifierProvider<MyReservationsNotifier, List<Reservation>>(() {
  return MyReservationsNotifier();
});

/// Provider for single reservation detail by ID
final reservationDetailProvider =
    FutureProvider.autoDispose.family<Reservation, int>((ref, id) async {
  final repository = ref.watch(reservationsRepositoryProvider);
  return await repository.fetchReservationDetail(id);
});
