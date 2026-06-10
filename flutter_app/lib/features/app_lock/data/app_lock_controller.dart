import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'package:aji_tfarraj/app/localization/locale_provider.dart';

const String _kBiometricEnabledKey = 'biometric_lock_enabled';

/// Re-lock if the app was in the background longer than this.
const Duration _lockAfterBackground = Duration(seconds: 30);

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

/// Thin wrapper around local_auth.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the device can do biometrics (or has a device passcode fallback).
  Future<bool> isAvailable() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && (canCheck || await _auth.isDeviceSupported());
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          // Allow device PIN/passcode as a fallback so a user is never locked
          // out if biometrics fail.
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((_) => BiometricService());

class AppLockState {
  final bool enabled;
  final bool isLocked;

  const AppLockState({this.enabled = false, this.isLocked = false});

  AppLockState copyWith({bool? enabled, bool? isLocked}) => AppLockState(
        enabled: enabled ?? this.enabled,
        isLocked: isLocked ?? this.isLocked,
      );
}

class AppLockController extends StateNotifier<AppLockState> {
  final Ref _ref;
  DateTime? _backgroundedAt;

  AppLockController(this._ref) : super(const AppLockState()) {
    _init();
  }

  Future<void> _init() async {
    bool enabled = false;
    try {
      enabled = (await _storage.read(key: _kBiometricEnabledKey)) == 'true';
    } catch (_) {}
    // If lock is enabled, start locked so launch requires authentication.
    state = AppLockState(enabled: enabled, isLocked: enabled);
  }

  String get _reason => _ref.read(stringsProvider).biometricReason;

  /// Enable/disable the lock. Enabling first requires a successful auth so the
  /// user can't lock themselves out. Returns the resulting enabled state.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final ok = await _ref.read(biometricServiceProvider).authenticate(_reason);
      if (!ok) return false;
    }
    try {
      await _storage.write(key: _kBiometricEnabledKey, value: value.toString());
    } catch (_) {}
    state = state.copyWith(enabled: value, isLocked: false);
    return value;
  }

  /// Prompt biometrics to clear the lock. Returns true on success.
  Future<bool> unlock() async {
    final ok = await _ref.read(biometricServiceProvider).authenticate(_reason);
    if (ok) state = state.copyWith(isLocked: false);
    return ok;
  }

  void onPaused() => _backgroundedAt = DateTime.now();

  void onResumed() {
    if (!state.enabled) return;
    final bg = _backgroundedAt;
    _backgroundedAt = null;
    if (bg != null && DateTime.now().difference(bg) >= _lockAfterBackground) {
      state = state.copyWith(isLocked: true);
    }
  }
}

final appLockProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  return AppLockController(ref);
});

/// Whether the device can use biometric/passcode auth (gates the Profile toggle).
final biometricAvailableProvider = FutureProvider<bool>((ref) {
  return ref.read(biometricServiceProvider).isAvailable();
});
