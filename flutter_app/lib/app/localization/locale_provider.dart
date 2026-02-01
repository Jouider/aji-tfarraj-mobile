// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/localization/locale_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/localization/strings.dart';

/// Notifier for managing the current app locale
class LocaleNotifier extends Notifier<AppLocale> {
  @override
  AppLocale build() {
    // Default to French
    return AppLocale.fr;
  }

  /// Change the current locale
  void setLocale(AppLocale locale) {
    state = locale;
  }

  /// Toggle between FR and AR
  void toggleLocale() {
    state = state == AppLocale.fr ? AppLocale.ar : AppLocale.fr;
  }
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
