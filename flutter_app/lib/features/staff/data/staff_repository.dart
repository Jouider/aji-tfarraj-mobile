import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/staff/domain/staff_check_in_result.dart';
import 'package:aji_tfarraj/features/staff/domain/ticket_preview.dart';

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
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Look at a ticket WITHOUT admitting anyone.
  ///
  /// Free of side effects on purpose, so the scanner can scan to check the face
  /// against the photo — and fix a bad one — before validating.
  Future<TicketPreview> lookup({String? qrToken, String? ticketCode}) async {
    assert(
      (qrToken != null) != (ticketCode != null),
      'Exactly one of qrToken or ticketCode must be provided',
    );

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/staff/ticket/lookup',
        data: qrToken != null
            ? {'qr_token': qrToken}
            : {'ticket_code': ticketCode},
      );
      return TicketPreview.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Record where the shuttle should drop this attendee, or clear the choice.
  ///
  /// [pointId] null means "no shuttle needed" — plenty of people drive
  /// themselves, and the door must be able to say so.
  Future<void> setReturnPoint({
    required int reservationId,
    required int? pointId,
  }) async {
    try {
      await _apiClient.patch<Map<String, dynamic>>(
        '/api/staff/reservations/$reservationId/return-point',
        data: {'return_point_id': pointId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  /// Replace the attendee's photo from the door. Returns the new avatar URL.
  Future<String?> replaceAttendeePhoto({
    required int attendeeId,
    required String photoPath,
  }) async {
    try {
      final form = FormData.fromMap({
        'photo': await MultipartFile.fromFile(photoPath, filename: 'door.jpg'),
      });

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/staff/attendees/$attendeeId/photo',
        data: form,
      );
      return response.data?['avatar_url'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    } catch (e) {
      throw ApiException.from(e);
    }
  }
}

final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  return StaffRepository(ref.watch(apiClientProvider));
});

// ─── State ───────────────────────────────────────────────────────────────────

/// [preview] sits between scanning and success: the scanner is looking at who
/// is in front of them and has not admitted anyone yet.
enum StaffCheckInStatus { idle, loading, preview, success, error }

class StaffCheckInState {
  final StaffCheckInStatus status;
  final StaffCheckInResult? result;

  /// Who was scanned, before anyone is admitted.
  final TicketPreview? preview;
  final String? errorMessage;
  /// checked_in_at from a 409 response, if available
  final DateTime? alreadyCheckedInAt;
  /// When false, scanner should not trigger new requests
  final bool scannerActive;

  const StaffCheckInState({
    this.status = StaffCheckInStatus.idle,
    this.result,
    this.preview,
    this.errorMessage,
    this.alreadyCheckedInAt,
    this.scannerActive = true,
  });

  StaffCheckInState copyWith({
    StaffCheckInStatus? status,
    StaffCheckInResult? result,
    TicketPreview? preview,
    String? errorMessage,
    DateTime? alreadyCheckedInAt,
    bool? scannerActive,
  }) {
    return StaffCheckInState(
      status: status ?? this.status,
      result: result ?? this.result,
      preview: preview ?? this.preview,
      errorMessage: errorMessage ?? this.errorMessage,
      alreadyCheckedInAt: alreadyCheckedInAt ?? this.alreadyCheckedInAt,
      scannerActive: scannerActive ?? this.scannerActive,
    );
  }
}

class StaffCheckInNotifier extends StateNotifier<StaffCheckInState> {
  final StaffRepository _repository;

  StaffCheckInNotifier(this._repository) : super(const StaffCheckInState());

  /// Step 1 — look at the ticket. Admits nobody.
  ///
  /// Every outcome except a hard failure lands in [StaffCheckInStatus.preview]:
  /// a refusal is something the scanner must *read*, not a dead end, and the
  /// refused ticket details still help them explain it to the person.
  Future<void> lookup({String? qrToken, String? ticketCode}) async {
    if (state.status == StaffCheckInStatus.loading) return;

    state = state.copyWith(
      status: StaffCheckInStatus.loading,
      scannerActive: false,
    );

    try {
      final preview = await _repository.lookup(
        qrToken: qrToken,
        ticketCode: ticketCode,
      );
      state = StaffCheckInState(
        status: StaffCheckInStatus.preview,
        preview: preview,
        scannerActive: false,
      );
    } on ApiException catch (e) {
      state = StaffCheckInState(
        status: StaffCheckInStatus.error,
        errorMessage: _mapErrorMessage(e),
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

  /// Step 2 — admit the person shown in the preview.
  Future<void> confirmPreview() async {
    final preview = state.preview;
    if (preview == null || !preview.canAdmit) return;

    await checkIn(ticketCode: preview.ticketCode);
  }

  /// Record the drop-off choice and reflect it in the preview immediately, so
  /// the scanner sees it land without re-scanning.
  Future<void> setReturnPoint(int? pointId) async {
    final preview = state.preview;
    final reservationId = preview?.reservationId;
    if (preview == null || reservationId == null) return;

    await _repository.setReturnPoint(
      reservationId: reservationId,
      pointId: pointId,
    );

    state = state.copyWith(preview: preview.withReturnPoint(pointId));
  }

  /// Replace the attendee's photo without leaving the preview, so the scanner
  /// fixes it and validates in one go.
  Future<String?> replacePhoto(String photoPath) async {
    final preview = state.preview;
    final id = preview?.attendeeId;
    if (preview == null || id == null) return null;

    final url = await _repository.replaceAttendeePhoto(
      attendeeId: id,
      photoPath: photoPath,
    );

    if (url != null) {
      state = state.copyWith(preview: preview.withAvatarUrl(url));
    }

    return url;
  }

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
