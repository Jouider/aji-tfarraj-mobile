import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/network/api_client.dart';
import 'package:aji_tfarraj/features/auth/data/auth_repository.dart';
import 'package:aji_tfarraj/features/profile/data/profile_repository.dart';

const _resendCooldownSeconds = 30;

class OtpState {
  final bool isRequesting;
  final bool isVerifying;
  final int resendSecondsLeft;
  final String? errorMessage;
  final bool success;

  const OtpState({
    this.isRequesting = false,
    this.isVerifying = false,
    this.resendSecondsLeft = 0,
    this.errorMessage,
    this.success = false,
  });

  OtpState copyWith({
    bool? isRequesting,
    bool? isVerifying,
    int? resendSecondsLeft,
    String? errorMessage,
    bool clearError = false,
    bool? success,
  }) {
    return OtpState(
      isRequesting: isRequesting ?? this.isRequesting,
      isVerifying: isVerifying ?? this.isVerifying,
      resendSecondsLeft: resendSecondsLeft ?? this.resendSecondsLeft,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
    );
  }
}

class PhoneOtpController extends StateNotifier<OtpState> {
  PhoneOtpController({
    required this.ref,
    required this.countryCode,
    required this.phoneNumber,
    required this.repository,
  }) : super(const OtpState());

  final Ref ref;
  final String countryCode;
  final String phoneNumber;
  final ProfileRepository repository;

  Timer? _countdownTimer;

  /// Request an OTP via SMS. On success, starts the 30-second resend cooldown.
  Future<void> requestOtp() async {
    state = state.copyWith(isRequesting: true, clearError: true);
    try {
      await repository.requestPhoneOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
      );
      _startCountdown();
    } on ApiException catch (e) {
      state = state.copyWith(
        isRequesting: false,
        errorMessage: _mapRequestError(e),
      );
      return;
    }
    state = state.copyWith(isRequesting: false);
  }

  /// Verify the OTP code. Returns true on success.
  Future<bool> verifyOtp(String code) async {
    state = state.copyWith(isVerifying: true, clearError: true);
    try {
      final updatedUser = await repository.verifyPhoneOtp(
        countryCode: countryCode,
        phoneNumber: phoneNumber,
        code: code,
      );
      // Update cached user immediately so the profile edit screen reflects the change
      ref.read(loginAuthStateProvider.notifier).updateUser(updatedUser);
      // Also refresh from server for consistency
      await ref.read(loginAuthStateProvider.notifier).refreshUser();
      state = state.copyWith(isVerifying: false, success: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isVerifying: false,
        errorMessage: _mapVerifyError(e),
      );
      return false;
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    state = state.copyWith(resendSecondsLeft: _resendCooldownSeconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final left = state.resendSecondsLeft - 1;
      if (left <= 0) {
        timer.cancel();
        state = state.copyWith(resendSecondsLeft: 0);
      } else {
        state = state.copyWith(resendSecondsLeft: left);
      }
    });
  }

  String _mapRequestError(ApiException e) {
    if (e.isUnauthenticated) return 'Vous devez être connecté.';
    if (e.code == 'OTP_SEND_FAILED') {
      return "Impossible d'envoyer le code pour le moment.";
    }
    return e.message;
  }

  String _mapVerifyError(ApiException e) {
    if (e.isUnauthenticated) return 'Vous devez être connecté.';
    if (e.code == 'OTP_INVALID') return 'Code invalide ou expiré.';
    if (e.code == 'OTP_VERIFY_FAILED') {
      return 'Impossible de vérifier le code pour le moment.';
    }
    return e.message;
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final phoneOtpControllerProvider = StateNotifierProvider.autoDispose
    .family<PhoneOtpController, OtpState, (String, String)>(
  (ref, params) => PhoneOtpController(
    ref: ref,
    countryCode: params.$1,
    phoneNumber: params.$2,
    repository: ref.watch(profileRepositoryProvider),
  ),
);
