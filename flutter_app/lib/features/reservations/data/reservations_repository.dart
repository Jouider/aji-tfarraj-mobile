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
  Future<List<Reservation>> fetchMyReservations() async {
    try {
      final response = await _apiClient.get(AppConfig.myReservations);
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Create a new reservation
  Future<Reservation> createReservation({
    required int showId,
    required int seats,
  }) async {
    try {
      final response = await _apiClient.post(
        AppConfig.reservations,
        data: {
          'show_id': showId,
          'seats': seats,
        },
      );
      return Reservation.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Get details of a specific reservation
  Future<Reservation> fetchReservationDetail(int id) async {
    try {
      final response = await _apiClient.get(AppConfig.reservationDetail(id));
      return Reservation.fromJson(response.data as Map<String, dynamic>);
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
    required int showId,
    required int seats,
  }) async {
    final repository = ref.read(reservationsRepositoryProvider);
    final reservation = await repository.createReservation(
      showId: showId,
      seats: seats,
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
