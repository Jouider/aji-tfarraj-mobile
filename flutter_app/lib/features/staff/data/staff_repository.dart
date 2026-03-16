import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/staff/domain/staff_check_in_result.dart';

class StaffRepository {
  final ApiClient _apiClient;

  StaffRepository(this._apiClient);

  /// Validates a ticket by QR token or manual ticket code.
  /// Exactly one of [qrToken] or [ticketCode] must be non-null.
  Future<StaffCheckInResult> checkIn({
    String? qrToken,
    String? ticketCode,
  }) async {
    assert(
      (qrToken != null) != (ticketCode != null),
      'Exactly one of qrToken or ticketCode must be provided',
    );

    final body = qrToken != null
        ? {'qr_token': qrToken}
        : {'ticket_code': ticketCode};

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/staff/check-in',
        data: body,
      );
      return StaffCheckInResult.fromJson(response.data!);
    } on DioException catch (e) {
      // For 409 (already checked in), surface checked_in_at through errors map
      if (e.response?.statusCode == 409) {
        final data = e.response?.data;
        final checkedInAt = data is Map<String, dynamic>
            ? data['checked_in_at'] as String?
            : null;
        throw ApiException(
          message: data is Map<String, dynamic>
              ? (data['message'] as String? ?? 'Ticket already checked in')
              : 'Ticket already checked in',
          statusCode: 409,
          code: 'already_checked_in',
          errors: checkedInAt != null ? {'checked_in_at': checkedInAt} : null,
        );
      }
      throw ApiException.fromDioError(e);
    }
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(apiClientProvider));
});

// ─── State ───────────────────────────────────────────────────────────────────

enum StaffCheckInStatus { idle, loading, success, error }

class StaffCheckInState {
  final StaffCheckInStatus status;
  final StaffCheckInResult? result;
  final String? errorMessage;
  /// checked_in_at from a 409 response, if available
  final DateTime? alreadyCheckedInAt;
  /// When false, scanner should not trigger new requests
  final bool scannerActive;

  const StaffCheckInState({
    this.status = StaffCheckInStatus.idle,
    this.result,
    this.errorMessage,
    this.alreadyCheckedInAt,
    this.scannerActive = true,
  });

  StaffCheckInState copyWith({
    StaffCheckInStatus? status,
    StaffCheckInResult? result,
    String? errorMessage,
    DateTime? alreadyCheckedInAt,
    bool? scannerActive,
  }) {
    return StaffCheckInState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      alreadyCheckedInAt: alreadyCheckedInAt ?? this.alreadyCheckedInAt,
      scannerActive: scannerActive ?? this.scannerActive,
    );
  }
}

class StaffCheckInNotifier extends StateNotifier<StaffCheckInState> {
  final StaffRepository _repository;

  StaffCheckInNotifier(this._repository) : super(const StaffCheckInState());

  Future<void> checkIn({String? qrToken, String? ticketCode}) async {
    if (state.status == StaffCheckInStatus.loading) return;

    state = state.copyWith(
      status: StaffCheckInStatus.loading,
      scannerActive: false,
    );

    try {
      final result = await _repository.checkIn(
        qrToken: qrToken,
        ticketCode: ticketCode,
      );
      state = StaffCheckInState(
        status: StaffCheckInStatus.success,
        result: result,
        scannerActive: false,
      );
    } on ApiException catch (e) {
      final message = _mapErrorMessage(e);
      DateTime? alreadyCheckedInAt;
      if (e.statusCode == 409 && e.errors?['checked_in_at'] != null) {
        try {
          alreadyCheckedInAt =
              DateTime.parse(e.errors!['checked_in_at'] as String).toLocal();
        } catch (_) {}
      }
      state = StaffCheckInState(
        status: StaffCheckInStatus.error,
        errorMessage: message,
        alreadyCheckedInAt: alreadyCheckedInAt,
        scannerActive: false,
      );
    } catch (_) {
      state = const StaffCheckInState(
        status: StaffCheckInStatus.error,
        errorMessage: 'Impossible de vérifier le billet pour le moment.',
        scannerActive: false,
      );
    }
  }

  void reset() {
    state = const StaffCheckInState();
  }

  String _mapErrorMessage(ApiException e) {
    switch (e.statusCode) {
      case 401:
        return 'Session expirée. Reconnectez-vous.';
      case 403:
        return 'Accès staff requis.';
      case 404:
        return 'Billet introuvable.';
      case 409:
        return 'Billet déjà utilisé.';
      case 422:
        return e.message;
      default:
        return 'Impossible de vérifier le billet pour le moment.';
    }
  }
}

final staffCheckInProvider =
    StateNotifierProvider.autoDispose<StaffCheckInNotifier, StaffCheckInState>(
  (ref) => StaffCheckInNotifier(ref.watch(staffRepositoryProvider)),
);
