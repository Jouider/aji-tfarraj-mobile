// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/localization/app_locale.dart
/// Supported app locales
enum AppLocale {
  /// French locale
  fr,
  /// Arabic locale
  ar;

  /// Get the language code
  String get languageCode {
    switch (this) {
      case AppLocale.fr:
        return 'fr';
      case AppLocale.ar:
        return 'ar';
    }
  }

  /// Check if this locale uses RTL text direction
  bool get isRtl => this == AppLocale.ar;

  /// Get locale from language code
  static AppLocale fromLanguageCode(String code) {
    switch (code) {
      case 'ar':
        return AppLocale.ar;
      case 'fr':
      default:
        return AppLocale.fr;
    }
  }
}
