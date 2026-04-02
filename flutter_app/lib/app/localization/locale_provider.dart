// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/localization/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';
import 'package:aji_tfarraj/features/notifications/data/notification_repository.dart'
    show sharedPreferencesProvider;

const _kLocaleKey = 'app_locale';

/// Notifier for managing the current app locale
class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    // Restore persisted locale (if any)
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_kLocaleKey);
    if (saved == 'ar') return AppLocale.ar;
    return AppLocale.fr;
  }

  /// Change the current locale and persist the choice
  void setLocale(AppLocale locale) {
    state = locale;
    _persist(locale);
  }

  /// Toggle between FR and AR
  void toggleLocale() {
    final next = state == AppLocale.fr ? AppLocale.ar : AppLocale.fr;
    state = next;
    _persist(next);
  }

  void _persist(AppLocale locale) {
    ref
        .read(sharedPreferencesProvider)
        .setString(_kLocaleKey, locale.languageCode);
  }
}

/// Whether the user has explicitly chosen a language at least once
bool hasChosenLocale(SharedPreferences prefs) {
  return prefs.containsKey(_kLocaleKey);
}

/// Provider for the current app locale (default: fr)
final localeProvider = NotifierProvider<LocaleNotifier, AppLocale>(() {
  return LocaleNotifier();
});

/// Provider to check if current locale is RTL
final isRtlProvider = Provider<bool>((ref) {
  final locale = ref.watch(localeProvider);
  return locale.isRtl;
});

/// Provider for the Flutter Locale object
final flutterLocaleProvider = Provider<Locale>((ref) {
  final locale = ref.watch(localeProvider);
  return Locale(locale.languageCode);
});

/// Provider for text direction based on locale
final textDirectionProvider = Provider<TextDirection>((ref) {
  final isRtl = ref.watch(isRtlProvider);
  return isRtl ? TextDirection.rtl : TextDirection.ltr;
});

/// Provider for localized strings
final stringsProvider = Provider<AppStrings>((ref) {
  final locale = ref.watch(localeProvider);
  return AppStrings(locale);
});
