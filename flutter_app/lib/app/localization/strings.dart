// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/localization/strings.dart
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
import 'package:aji_tfarraj/app/copywriting/copy_ar.dart';

/// Localized strings accessor
/// Maps keys to FR/AR strings using existing copywriting
class AppStrings {
  final AppLocale locale;

  const AppStrings(this.locale);

  // ============================================
  // Buttons
  // ============================================
  String get login =>
      locale == AppLocale.fr ? CopyFr.buttons.login : CopyAr.buttons.login;

  String get register => locale == AppLocale.fr
      ? CopyFr.buttons.register
      : CopyAr.buttons.register;

  String get reserve =>
      locale == AppLocale.fr ? CopyFr.buttons.reserve : CopyAr.buttons.reserve;

  String get confirm =>
      locale == AppLocale.fr ? CopyFr.buttons.confirm : CopyAr.buttons.confirm;

  String get cancel =>
      locale == AppLocale.fr ? CopyFr.buttons.cancel : CopyAr.buttons.cancel;

  String get logout =>
      locale == AppLocale.fr ? CopyFr.buttons.logout : CopyAr.buttons.logout;

  String get viewTicket => locale == AppLocale.fr
      ? CopyFr.buttons.viewTicket
      : CopyAr.buttons.viewTicket;

  // ============================================
  // Statuses
  // ============================================
  String get pendingReview => locale == AppLocale.fr
      ? CopyFr.statuses.pendingReview
      : CopyAr.statuses.pendingReview;

  String get contacting => locale == AppLocale.fr
      ? CopyFr.statuses.contacting
      : CopyAr.statuses.contacting;

  String get approved => locale == AppLocale.fr
      ? CopyFr.statuses.approved
      : CopyAr.statuses.approved;

  String get rejected => locale == AppLocale.fr
      ? CopyFr.statuses.rejected
      : CopyAr.statuses.rejected;

  String get cancelled => locale == AppLocale.fr
      ? CopyFr.statuses.cancelled
      : CopyAr.statuses.cancelled;

  String get expired => locale == AppLocale.fr
      ? CopyFr.statuses.expired
      : CopyAr.statuses.expired;

  String get checkedIn => locale == AppLocale.fr
      ? CopyFr.statuses.checkedIn
      : CopyAr.statuses.checkedIn;

  String statusByKey(String key) => locale == AppLocale.fr
      ? CopyFr.statuses.byKey(key)
      : CopyAr.statuses.byKey(key);

  // ============================================
  // Errors
  // ============================================
  String get networkError => locale == AppLocale.fr
      ? CopyFr.errors.networkError
      : CopyAr.errors.networkError;

  String get unauthorized => locale == AppLocale.fr
      ? CopyFr.errors.unauthorized
      : CopyAr.errors.unauthorized;

  String get soldOut =>
      locale == AppLocale.fr ? CopyFr.errors.soldOut : CopyAr.errors.soldOut;

  String get unknownError => locale == AppLocale.fr
      ? CopyFr.errors.unknownError
      : CopyAr.errors.unknownError;

  String get invalidCredentials => locale == AppLocale.fr
      ? CopyFr.errors.invalidCredentials
      : CopyAr.errors.invalidCredentials;

  String get emailAlreadyExists => locale == AppLocale.fr
      ? CopyFr.errors.emailAlreadyExists
      : CopyAr.errors.emailAlreadyExists;

  String get validationError => locale == AppLocale.fr
      ? CopyFr.errors.validationError
      : CopyAr.errors.validationError;

  // ============================================
  // Rules
  // ============================================
  String get rulesTitle =>
      locale == AppLocale.fr ? CopyFr.rules.title : CopyAr.rules.title;

  String get rulesIntroduction => locale == AppLocale.fr
      ? CopyFr.rules.introduction
      : CopyAr.rules.introduction;

  String get rulesAcceptance => locale == AppLocale.fr
      ? CopyFr.rules.acceptance
      : CopyAr.rules.acceptance;

  // ============================================
  // Loyalty
  // ============================================
  String get loyaltyTitle => locale == AppLocale.fr
      ? CopyFr.loyalty.loyaltyTitle
      : CopyAr.loyalty.loyaltyTitle;

  String get pointsTotal => locale == AppLocale.fr
      ? CopyFr.loyalty.pointsTotal
      : CopyAr.loyalty.pointsTotal;

  String get pointsSubtitle => locale == AppLocale.fr
      ? CopyFr.loyalty.pointsSubtitle
      : CopyAr.loyalty.pointsSubtitle;

  String get history =>
      locale == AppLocale.fr ? CopyFr.loyalty.history : CopyAr.loyalty.history;

  String get rewards =>
      locale == AppLocale.fr ? CopyFr.loyalty.rewards : CopyAr.loyalty.rewards;

  String get comingSoon => locale == AppLocale.fr
      ? CopyFr.loyalty.comingSoon
      : CopyAr.loyalty.comingSoon;

  String get noPointsYet => locale == AppLocale.fr
      ? CopyFr.loyalty.noPointsYet
      : CopyAr.loyalty.noPointsYet;

  String get attendanceLabel => locale == AppLocale.fr
      ? CopyFr.loyalty.attendanceLabel
      : CopyAr.loyalty.attendanceLabel;
}
