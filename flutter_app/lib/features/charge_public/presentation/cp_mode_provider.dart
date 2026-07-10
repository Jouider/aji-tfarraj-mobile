import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

const _kCpModeKey = 'cp_mode_enabled';

/// Whether the charge-public user is currently in "Mode Chargé Public"
/// (inDrive-style mode switch). Persisted so a CP who chose it reopens there.
///
/// Only meaningful for users where `User.isChargePublic` is true — the entry
/// point in Profile is gated on that.
class CpModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    return ref.read(sharedPreferencesProvider).getBool(_kCpModeKey) ?? false;
  }

  void setEnabled(bool enabled) {
    state = enabled;
    ref.read(sharedPreferencesProvider).setBool(_kCpModeKey, enabled);
  }
}

final cpModeProvider = NotifierProvider<CpModeNotifier, bool>(CpModeNotifier.new);
