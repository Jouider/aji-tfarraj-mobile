// filepath: /Users/mouadsmac/aji-tfarraj-mobile/flutter_app/lib/app/localization/strings.dart
import 'package:aji_tfarraj/app/localization/app_locale.dart';
import 'package:aji_tfarraj/app/copywriting/copy_fr.dart';
import 'package:aji_tfarraj/app/copywriting/copy_ar.dart';
import 'package:aji_tfarraj/app/copywriting/casting_copy.dart';
import 'package:aji_tfarraj/app/copywriting/departure_copy.dart';

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

  // ============================================
  // Rewards
  // ============================================
  String get rewardsTitle => locale == AppLocale.fr
      ? CopyFr.rewards.rewardsTitle
      : CopyAr.rewards.rewardsTitle;

  String get myRewardsTitle => locale == AppLocale.fr
      ? CopyFr.rewards.myRewardsTitle
      : CopyAr.rewards.myRewardsTitle;

  String get collectReward => locale == AppLocale.fr
      ? CopyFr.rewards.collectReward
      : CopyAr.rewards.collectReward;

  String get rewardRequestSent => locale == AppLocale.fr
      ? CopyFr.rewards.rewardRequestSent
      : CopyAr.rewards.rewardRequestSent;

  String get rewardPendingLabel => locale == AppLocale.fr
      ? CopyFr.rewards.pendingLabel
      : CopyAr.rewards.pendingLabel;

  String get rewardApprovedLabel => locale == AppLocale.fr
      ? CopyFr.rewards.approvedLabel
      : CopyAr.rewards.approvedLabel;

  String get rewardRejectedLabel => locale == AppLocale.fr
      ? CopyFr.rewards.rejectedLabel
      : CopyAr.rewards.rejectedLabel;

  String get noRewardsYet => locale == AppLocale.fr
      ? CopyFr.rewards.noRewardsYet
      : CopyAr.rewards.noRewardsYet;

  String get noMyRewardsYet => locale == AppLocale.fr
      ? CopyFr.rewards.noMyRewardsYet
      : CopyAr.rewards.noMyRewardsYet;

  String get pointsRequired => locale == AppLocale.fr
      ? CopyFr.rewards.pointsRequired
      : CopyAr.rewards.pointsRequired;

  String get seeAllRewards => locale == AppLocale.fr
      ? CopyFr.rewards.seeAllRewards
      : CopyAr.rewards.seeAllRewards;

  String get requestedAt => locale == AppLocale.fr
      ? CopyFr.rewards.requestedAt
      : CopyAr.rewards.requestedAt;

  // ============================================
  // Auth
  // ============================================
  String get loginSubtitle => locale == AppLocale.fr
      ? CopyFr.auth.loginSubtitle
      : CopyAr.auth.loginSubtitle;

  String get noAccount =>
      locale == AppLocale.fr ? CopyFr.auth.noAccount : CopyAr.auth.noAccount;

  String get registerLink => locale == AppLocale.fr
      ? CopyFr.auth.registerLink
      : CopyAr.auth.registerLink;

  String get registerTitle => locale == AppLocale.fr
      ? CopyFr.auth.registerTitle
      : CopyAr.auth.registerTitle;

  String get registerSubtitle => locale == AppLocale.fr
      ? CopyFr.auth.registerSubtitle
      : CopyAr.auth.registerSubtitle;

  String get alreadyAccount => locale == AppLocale.fr
      ? CopyFr.auth.alreadyAccount
      : CopyAr.auth.alreadyAccount;

  String get loginLink =>
      locale == AppLocale.fr ? CopyFr.auth.loginLink : CopyAr.auth.loginLink;

  String get emailLabel =>
      locale == AppLocale.fr ? CopyFr.auth.emailLabel : CopyAr.auth.emailLabel;

  String get emailHint =>
      locale == AppLocale.fr ? CopyFr.auth.emailHint : CopyAr.auth.emailHint;

  String get passwordLabel => locale == AppLocale.fr
      ? CopyFr.auth.passwordLabel
      : CopyAr.auth.passwordLabel;

  String get nameLabel =>
      locale == AppLocale.fr ? CopyFr.auth.nameLabel : CopyAr.auth.nameLabel;

  String get nameHint =>
      locale == AppLocale.fr ? CopyFr.auth.nameHint : CopyAr.auth.nameHint;

  String get confirmPasswordLabel => locale == AppLocale.fr
      ? CopyFr.auth.confirmPasswordLabel
      : CopyAr.auth.confirmPasswordLabel;

  String get emailRequired => locale == AppLocale.fr
      ? CopyFr.auth.emailRequired
      : CopyAr.auth.emailRequired;

  String get emailInvalid => locale == AppLocale.fr
      ? CopyFr.auth.emailInvalid
      : CopyAr.auth.emailInvalid;

  String get passwordRequired => locale == AppLocale.fr
      ? CopyFr.auth.passwordRequired
      : CopyAr.auth.passwordRequired;

  String get passwordMin =>
      locale == AppLocale.fr ? CopyFr.auth.passwordMin : CopyAr.auth.passwordMin;

  String get passwordWeak =>
      locale == AppLocale.fr ? CopyFr.auth.passwordWeak : CopyAr.auth.passwordWeak;

  String get nameRequired => locale == AppLocale.fr
      ? CopyFr.auth.nameRequired
      : CopyAr.auth.nameRequired;

  String get nameMin =>
      locale == AppLocale.fr ? CopyFr.auth.nameMin : CopyAr.auth.nameMin;

  String get confirmPasswordRequired => locale == AppLocale.fr
      ? CopyFr.auth.confirmPasswordRequired
      : CopyAr.auth.confirmPasswordRequired;

  String get passwordMismatch => locale == AppLocale.fr
      ? CopyFr.auth.passwordMismatch
      : CopyAr.auth.passwordMismatch;

  // Auth landing
  String get authLandingTitle => locale == AppLocale.fr
      ? CopyFr.auth.authLandingTitle
      : CopyAr.auth.authLandingTitle;

  String get authLandingSubtitle => locale == AppLocale.fr
      ? CopyFr.auth.authLandingSubtitle
      : CopyAr.auth.authLandingSubtitle;

  String get continueWithGoogle => locale == AppLocale.fr
      ? CopyFr.auth.continueWithGoogle
      : CopyAr.auth.continueWithGoogle;

  String get continueWithApple => locale == AppLocale.fr
      ? CopyFr.auth.continueWithApple
      : CopyAr.auth.continueWithApple;

  String get continueWithEmail => locale == AppLocale.fr
      ? CopyFr.auth.continueWithEmail
      : CopyAr.auth.continueWithEmail;

  String get createAccount => locale == AppLocale.fr
      ? CopyFr.auth.createAccount
      : CopyAr.auth.createAccount;

  String get orDivider =>
      locale == AppLocale.fr ? CopyFr.auth.orDivider : CopyAr.auth.orDivider;

  String get termsNotice => locale == AppLocale.fr
      ? CopyFr.auth.termsNotice
      : CopyAr.auth.termsNotice;

  // Forgot password
  String get forgotPassword => locale == AppLocale.fr
      ? CopyFr.auth.forgotPassword
      : CopyAr.auth.forgotPassword;

  String get forgotPasswordTitle => locale == AppLocale.fr
      ? CopyFr.auth.forgotPasswordTitle
      : CopyAr.auth.forgotPasswordTitle;

  String get forgotPasswordSubtitle => locale == AppLocale.fr
      ? CopyFr.auth.forgotPasswordSubtitle
      : CopyAr.auth.forgotPasswordSubtitle;

  String get forgotPasswordButton => locale == AppLocale.fr
      ? CopyFr.auth.forgotPasswordButton
      : CopyAr.auth.forgotPasswordButton;

  String get forgotPasswordSuccess => locale == AppLocale.fr
      ? CopyFr.auth.forgotPasswordSuccess
      : CopyAr.auth.forgotPasswordSuccess;

  String get forgotPasswordSuccessMessage => locale == AppLocale.fr
      ? CopyFr.auth.forgotPasswordSuccessMessage
      : CopyAr.auth.forgotPasswordSuccessMessage;

  String get backToLogin => locale == AppLocale.fr
      ? CopyFr.auth.backToLogin
      : CopyAr.auth.backToLogin;

  // ============================================
  // Common
  // ============================================
  String get retry =>
      locale == AppLocale.fr ? CopyFr.common.retry : CopyAr.common.retry;

  String get seeAll =>
      locale == AppLocale.fr ? CopyFr.common.seeAll : CopyAr.common.seeAll;

  String get back => locale == AppLocale.fr
      ? CopyFr.common.back
      : CopyAr.common.back;

  String get backToHome => locale == AppLocale.fr
      ? CopyFr.common.backToHome
      : CopyAr.common.backToHome;

  String get browseShows => locale == AppLocale.fr
      ? CopyFr.common.browseShows
      : CopyAr.common.browseShows;

  String get reservationSuccessBody => locale == AppLocale.fr
      ? CopyFr.common.reservationSuccessBody
      : CopyAr.common.reservationSuccessBody;

  String get errorTitle => locale == AppLocale.fr
      ? CopyFr.errors.errorTitle
      : CopyAr.errors.errorTitle;

  String get unknownUser => locale == AppLocale.fr
      ? CopyFr.common.unknownUser
      : CopyAr.common.unknownUser;

  String get place =>
      locale == AppLocale.fr ? CopyFr.common.place : CopyAr.common.place;

  String get places =>
      locale == AppLocale.fr ? CopyFr.common.places : CopyAr.common.places;

  // ============================================
  // Profile
  // ============================================
  String get profileTitle => locale == AppLocale.fr
      ? CopyFr.profile.title
      : CopyAr.profile.title;

  String get profileLanguageLabel => locale == AppLocale.fr
      ? CopyFr.profile.languageLabel
      : CopyAr.profile.languageLabel;

  String get profileLanguageValueFr => locale == AppLocale.fr
      ? CopyFr.profile.languageValueFr
      : CopyAr.profile.languageValueFr;

  String get profileLanguageValueAr => locale == AppLocale.fr
      ? CopyFr.profile.languageValueAr
      : CopyAr.profile.languageValueAr;

  String get profileThemeLabel => locale == AppLocale.fr
      ? CopyFr.profile.themeLabel
      : CopyAr.profile.themeLabel;

  String get themeSystem => locale == AppLocale.fr
      ? CopyFr.profile.themeSystem
      : CopyAr.profile.themeSystem;

  String get themeLight => locale == AppLocale.fr
      ? CopyFr.profile.themeLight
      : CopyAr.profile.themeLight;

  String get themeDark => locale == AppLocale.fr
      ? CopyFr.profile.themeDark
      : CopyAr.profile.themeDark;

  String get profileLoyaltyLabel => locale == AppLocale.fr
      ? CopyFr.profile.loyaltyLabel
      : CopyAr.profile.loyaltyLabel;

  String get profileNotificationsLabel => locale == AppLocale.fr
      ? CopyFr.profile.notificationsLabel
      : CopyAr.profile.notificationsLabel;

  String profileUnreadCount(int n) => locale == AppLocale.fr
      ? CopyFr.profile.unreadCount(n)
      : CopyAr.profile.unreadCount(n);

  String get profileHelpLabel => locale == AppLocale.fr
      ? CopyFr.profile.helpLabel
      : CopyAr.profile.helpLabel;

  String get profileAboutLabel => locale == AppLocale.fr
      ? CopyFr.profile.aboutLabel
      : CopyAr.profile.aboutLabel;

  String get profileLogoutLabel => locale == AppLocale.fr
      ? CopyFr.profile.logoutLabel
      : CopyAr.profile.logoutLabel;

  String get profileGroupPreferences => locale == AppLocale.fr
      ? CopyFr.profile.groupPreferences
      : CopyAr.profile.groupPreferences;

  String get profileGroupAccount => locale == AppLocale.fr
      ? CopyFr.profile.groupAccount
      : CopyAr.profile.groupAccount;

  String get profileGroupSettings => locale == AppLocale.fr
      ? CopyFr.profile.groupSettings
      : CopyAr.profile.groupSettings;

  // Edit profile
  String get editProfileTitle => locale == AppLocale.fr
      ? CopyFr.profile.editTitle
      : CopyAr.profile.editTitle;

  String get editSectionPersonal => locale == AppLocale.fr
      ? CopyFr.profile.editSectionPersonal
      : CopyAr.profile.editSectionPersonal;

  String get editSectionLocation => locale == AppLocale.fr
      ? CopyFr.profile.editSectionLocation
      : CopyAr.profile.editSectionLocation;

  String get editSectionContact => locale == AppLocale.fr
      ? CopyFr.profile.editSectionContact
      : CopyAr.profile.editSectionContact;

  String get profileIncompleteWarning => locale == AppLocale.fr
      ? CopyFr.profile.incompleteWarning
      : CopyAr.profile.incompleteWarning;

  String get profileIncompleteMessage => locale == AppLocale.fr
      ? CopyFr.profile.incompleteMessage
      : CopyAr.profile.incompleteMessage;

  String get completeProfileButton => locale == AppLocale.fr
      ? CopyFr.profile.completeProfileButton
      : CopyAr.profile.completeProfileButton;

  String get firstNameLabel => locale == AppLocale.fr
      ? CopyFr.profile.firstNameLabel
      : CopyAr.profile.firstNameLabel;

  String get lastNameLabel => locale == AppLocale.fr
      ? CopyFr.profile.lastNameLabel
      : CopyAr.profile.lastNameLabel;

  String get cityLabel => locale == AppLocale.fr
      ? CopyFr.profile.cityLabel
      : CopyAr.profile.cityLabel;

  String get districtLabel => locale == AppLocale.fr
      ? CopyFr.profile.districtLabel
      : CopyAr.profile.districtLabel;

  String get firstNameRequired => locale == AppLocale.fr
      ? CopyFr.profile.firstNameRequired
      : CopyAr.profile.firstNameRequired;

  String get lastNameRequired => locale == AppLocale.fr
      ? CopyFr.profile.lastNameRequired
      : CopyAr.profile.lastNameRequired;

  String get cityRequired => locale == AppLocale.fr
      ? CopyFr.profile.cityRequired
      : CopyAr.profile.cityRequired;

  String get districtRequired => locale == AppLocale.fr
      ? CopyFr.profile.districtRequired
      : CopyAr.profile.districtRequired;

  String get genderLabel => locale == AppLocale.fr
      ? CopyFr.profile.genderLabel
      : CopyAr.profile.genderLabel;

  String get genderMale => locale == AppLocale.fr
      ? CopyFr.profile.genderMale
      : CopyAr.profile.genderMale;

  String get genderFemale => locale == AppLocale.fr
      ? CopyFr.profile.genderFemale
      : CopyAr.profile.genderFemale;

  String get genderRequired => locale == AppLocale.fr
      ? CopyFr.profile.genderRequired
      : CopyAr.profile.genderRequired;

  String get saveChanges => locale == AppLocale.fr
      ? CopyFr.profile.saveChanges
      : CopyAr.profile.saveChanges;

  String get profileSavedSuccess => locale == AppLocale.fr
      ? CopyFr.profile.savedSuccess
      : CopyAr.profile.savedSuccess;

  String get genericError => locale == AppLocale.fr
      ? CopyFr.errors.unknownError
      : CopyAr.errors.unknownError;

  String get avatarDeletedSuccess => locale == AppLocale.fr
      ? CopyFr.profile.avatarDeletedSuccess
      : CopyAr.profile.avatarDeletedSuccess;

  String get addPhotoHint => locale == AppLocale.fr
      ? CopyFr.profile.addPhotoHint
      : CopyAr.profile.addPhotoHint;

  String get skipForNow => locale == AppLocale.fr
      ? CopyFr.profile.skipForNow
      : CopyAr.profile.skipForNow;

  String get cameraAccessDenied => locale == AppLocale.fr
      ? CopyFr.profile.cameraAccessDenied
      : CopyAr.profile.cameraAccessDenied;

  String get permissionNeededTitle => locale == AppLocale.fr
      ? CopyFr.profile.permissionNeededTitle
      : CopyAr.profile.permissionNeededTitle;

  String get cameraPermissionMessage => locale == AppLocale.fr
      ? CopyFr.profile.cameraPermissionMessage
      : CopyAr.profile.cameraPermissionMessage;

  String get openSettings => locale == AppLocale.fr
      ? CopyFr.profile.openSettings
      : CopyAr.profile.openSettings;

  String get profileStillIncomplete => locale == AppLocale.fr
      ? CopyFr.profile.profileStillIncomplete
      : CopyAr.profile.profileStillIncomplete;

  String get uploadPhoto => locale == AppLocale.fr
      ? CopyFr.profile.uploadPhoto
      : CopyAr.profile.uploadPhoto;

  String get takePhoto => locale == AppLocale.fr
      ? CopyFr.profile.takePhoto
      : CopyAr.profile.takePhoto;

  String get chooseFromGallery => locale == AppLocale.fr
      ? CopyFr.profile.chooseFromGallery
      : CopyAr.profile.chooseFromGallery;

  String get removePhoto => locale == AppLocale.fr
      ? CopyFr.profile.removePhoto
      : CopyAr.profile.removePhoto;

  // Phone section
  String get phoneLabel => locale == AppLocale.fr
      ? CopyFr.profile.phoneLabel
      : CopyAr.profile.phoneLabel;

  String get phoneNumberHint => locale == AppLocale.fr
      ? CopyFr.profile.phoneNumberHint
      : CopyAr.profile.phoneNumberHint;

  String get phoneVerified => locale == AppLocale.fr
      ? CopyFr.profile.phoneVerified
      : CopyAr.profile.phoneVerified;

  String get phoneNotVerified => locale == AppLocale.fr
      ? CopyFr.profile.phoneNotVerified
      : CopyAr.profile.phoneNotVerified;

  String get phoneNumberInvalid => locale == AppLocale.fr
      ? CopyFr.profile.phoneNumberInvalid
      : CopyAr.profile.phoneNumberInvalid;

  String get verifyPhoneButton => locale == AppLocale.fr
      ? CopyFr.profile.verifyPhoneButton
      : CopyAr.profile.verifyPhoneButton;

  String get phoneAlreadyUsed => locale == AppLocale.fr
      ? CopyFr.profile.phoneAlreadyUsed
      : CopyAr.profile.phoneAlreadyUsed;

  String get dateOfBirthLabel => locale == AppLocale.fr
      ? CopyFr.profile.dateOfBirthLabel
      : CopyAr.profile.dateOfBirthLabel;

  String get dateOfBirthRequired => locale == AppLocale.fr
      ? CopyFr.profile.dateOfBirthRequired
      : CopyAr.profile.dateOfBirthRequired;

  String get avatarRequiredHint => locale == AppLocale.fr
      ? CopyFr.profile.avatarRequiredHint
      : CopyAr.profile.avatarRequiredHint;

  // OTP screen
  String get otpScreenTitle => locale == AppLocale.fr
      ? CopyFr.profile.otpScreenTitle
      : CopyAr.profile.otpScreenTitle;

  String otpScreenSubtitle(String maskedPhone) => locale == AppLocale.fr
      ? CopyFr.profile.otpScreenSubtitle(maskedPhone)
      : CopyAr.profile.otpScreenSubtitle(maskedPhone);

  String get otpCodeHint => locale == AppLocale.fr
      ? CopyFr.profile.otpCodeHint
      : CopyAr.profile.otpCodeHint;

  String get otpCodeRequired => locale == AppLocale.fr
      ? CopyFr.profile.otpCodeRequired
      : CopyAr.profile.otpCodeRequired;

  String get otpVerifyButton => locale == AppLocale.fr
      ? CopyFr.profile.otpVerifyButton
      : CopyAr.profile.otpVerifyButton;

  String get otpResendButton => locale == AppLocale.fr
      ? CopyFr.profile.otpResendButton
      : CopyAr.profile.otpResendButton;

  String otpResendCountdown(int s) => locale == AppLocale.fr
      ? CopyFr.profile.otpResendCountdown(s)
      : CopyAr.profile.otpResendCountdown(s);

  String get otpSentSuccess => locale == AppLocale.fr
      ? CopyFr.profile.otpSentSuccess
      : CopyAr.profile.otpSentSuccess;

  String get otpVerifiedSuccess => locale == AppLocale.fr
      ? CopyFr.profile.otpVerifiedSuccess
      : CopyAr.profile.otpVerifiedSuccess;

  String get otpInvalidCode => locale == AppLocale.fr
      ? CopyFr.profile.otpInvalidCode
      : CopyAr.profile.otpInvalidCode;

  String get otpSendFailed => locale == AppLocale.fr
      ? CopyFr.profile.otpSendFailed
      : CopyAr.profile.otpSendFailed;

  String get otpVerifyFailed => locale == AppLocale.fr
      ? CopyFr.profile.otpVerifyFailed
      : CopyAr.profile.otpVerifyFailed;

  // ============================================
  // My Reservations
  // ============================================
  String get myReservationsTitle => locale == AppLocale.fr
      ? CopyFr.myReservations.title
      : CopyAr.myReservations.title;

  String get myResTabPending => locale == AppLocale.fr
      ? CopyFr.myReservations.tabPending
      : CopyAr.myReservations.tabPending;

  String get myResTabApproved => locale == AppLocale.fr
      ? CopyFr.myReservations.tabApproved
      : CopyAr.myReservations.tabApproved;

  String get myResTabPast => locale == AppLocale.fr
      ? CopyFr.myReservations.tabPast
      : CopyAr.myReservations.tabPast;

  String get myResEmptyPending => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyPending
      : CopyAr.myReservations.emptyPending;

  String get myResEmptyPendingSubtitle => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyPendingSubtitle
      : CopyAr.myReservations.emptyPendingSubtitle;

  String get myResEmptyApproved => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyApproved
      : CopyAr.myReservations.emptyApproved;

  String get myResEmptyApprovedSubtitle => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyApprovedSubtitle
      : CopyAr.myReservations.emptyApprovedSubtitle;

  String get myResEmptyPast => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyPast
      : CopyAr.myReservations.emptyPast;

  String get myResEmptyPastSubtitle => locale == AppLocale.fr
      ? CopyFr.myReservations.emptyPastSubtitle
      : CopyAr.myReservations.emptyPastSubtitle;

  String get myResCancelDialogTitle => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelDialogTitle
      : CopyAr.myReservations.cancelDialogTitle;

  String get myResCancelDialogContent => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelDialogContent
      : CopyAr.myReservations.cancelDialogContent;

  String get myResCancelDialogKeep => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelDialogKeep
      : CopyAr.myReservations.cancelDialogKeep;

  String get myResCancelDialogConfirm => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelDialogConfirm
      : CopyAr.myReservations.cancelDialogConfirm;

  String get myResCancelSuccess => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelSuccess
      : CopyAr.myReservations.cancelSuccess;

  String get myResCancelErrorForbidden => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelErrorForbidden
      : CopyAr.myReservations.cancelErrorForbidden;

  String get myResCancelErrorConflict => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelErrorConflict
      : CopyAr.myReservations.cancelErrorConflict;

  String get myResCancelErrorGeneric => locale == AppLocale.fr
      ? CopyFr.myReservations.cancelErrorGeneric
      : CopyAr.myReservations.cancelErrorGeneric;

  String get myResExpiredBanner => locale == AppLocale.fr
      ? CopyFr.myReservations.expiredBanner
      : CopyAr.myReservations.expiredBanner;

  String get myResCheckedInBanner => locale == AppLocale.fr
      ? CopyFr.myReservations.checkedInBanner
      : CopyAr.myReservations.checkedInBanner;

  String get myResRetryLabel => locale == AppLocale.fr
      ? CopyFr.myReservations.retryLabel
      : CopyAr.myReservations.retryLabel;

  String myResSeatCount(int n) => locale == AppLocale.fr
      ? CopyFr.myReservations.seatCount(n)
      : CopyAr.myReservations.seatCount(n);

  // ============================================
  // Home
  // ============================================
  String get homeSectionUpcoming => locale == AppLocale.fr
      ? CopyFr.home.sectionUpcoming
      : CopyAr.home.sectionUpcoming;

  String get homeSectionComingSoon => locale == AppLocale.fr
      ? CopyFr.home.sectionComingSoon
      : CopyAr.home.sectionComingSoon;

  String get homeSectionPopular => locale == AppLocale.fr
      ? CopyFr.home.sectionPopular
      : CopyAr.home.sectionPopular;

  String get homeSoldOut =>
      locale == AppLocale.fr ? CopyFr.home.soldOut : CopyAr.home.soldOut;

  String get homeComingSoonBadge => locale == AppLocale.fr
      ? CopyFr.home.comingSoonBadge
      : CopyAr.home.comingSoonBadge;

  String get homeSoldOutBadge => locale == AppLocale.fr
      ? CopyFr.home.soldOutBadge
      : CopyAr.home.soldOutBadge;

  String get homeDateTbc =>
      locale == AppLocale.fr ? CopyFr.home.dateTbc : CopyAr.home.dateTbc;

  String get homeNotificationsTooltip => locale == AppLocale.fr
      ? CopyFr.home.notificationsTooltip
      : CopyAr.home.notificationsTooltip;

  // ============================================
  // Show Detail
  // ============================================
  String get showDetailSoldOut => locale == AppLocale.fr
      ? CopyFr.showDetail.soldOut
      : CopyAr.showDetail.soldOut;

  String showDetailAvailableSeats(int n) => locale == AppLocale.fr
      ? CopyFr.showDetail.availableSeats(n)
      : CopyAr.showDetail.availableSeats(n);

  String showDetailReservations(int reserved, int cap) => locale == AppLocale.fr
      ? CopyFr.showDetail.reservations(reserved, cap)
      : CopyAr.showDetail.reservations(reserved, cap);

  String get showDetailAbout => locale == AppLocale.fr
      ? CopyFr.showDetail.about
      : CopyAr.showDetail.about;

  String get showDetailSeeLess => locale == AppLocale.fr
      ? CopyFr.showDetail.seeLess
      : CopyAr.showDetail.seeLess;

  String get showDetailSeeMore => locale == AppLocale.fr
      ? CopyFr.showDetail.seeMore
      : CopyAr.showDetail.seeMore;

  String get showDetailDateLabel => locale == AppLocale.fr
      ? CopyFr.showDetail.dateLabel
      : CopyAr.showDetail.dateLabel;

  String get showDetailTimeLabel => locale == AppLocale.fr
      ? CopyFr.showDetail.timeLabel
      : CopyAr.showDetail.timeLabel;

  String get showDetailLocationLabel => locale == AppLocale.fr
      ? CopyFr.showDetail.locationLabel
      : CopyAr.showDetail.locationLabel;

  String get showDetailChannelLabel => locale == AppLocale.fr
      ? CopyFr.showDetail.channelLabel
      : CopyAr.showDetail.channelLabel;

  String get showDetailLoyaltyPointsLabel => locale == AppLocale.fr
      ? CopyFr.showDetail.loyaltyPointsLabel
      : CopyAr.showDetail.loyaltyPointsLabel;

  String showDetailLoyaltyPointsValue(int pts) => locale == AppLocale.fr
      ? CopyFr.showDetail.loyaltyPointsValue(pts)
      : CopyAr.showDetail.loyaltyPointsValue(pts);

  String get showDetailRulesTitle => locale == AppLocale.fr
      ? CopyFr.showDetail.rulesTitle
      : CopyAr.showDetail.rulesTitle;

  String get showDetailReserveNow => locale == AppLocale.fr
      ? CopyFr.showDetail.reserveNow
      : CopyAr.showDetail.reserveNow;

  String get showDetailSoldOutCta => locale == AppLocale.fr
      ? CopyFr.showDetail.soldOutCta
      : CopyAr.showDetail.soldOutCta;

  // ============================================
  // Reserve Seats
  // ============================================
  String get reserveSeatsTitle => locale == AppLocale.fr
      ? CopyFr.reserveSeats.title
      : CopyAr.reserveSeats.title;

  String get reserveSeatsSoldOutBadge => locale == AppLocale.fr
      ? CopyFr.reserveSeats.soldOutBadge
      : CopyAr.reserveSeats.soldOutBadge;

  String reserveSeatsAvailable(int n) => locale == AppLocale.fr
      ? CopyFr.reserveSeats.availableSeats(n)
      : CopyAr.reserveSeats.availableSeats(n);

  String get reserveSeatsCountLabel => locale == AppLocale.fr
      ? CopyFr.reserveSeats.seatsCountLabel
      : CopyAr.reserveSeats.seatsCountLabel;

  String reserveSeatsMaxHint(int n) => locale == AppLocale.fr
      ? CopyFr.reserveSeats.maxHint(n)
      : CopyAr.reserveSeats.maxHint(n);

  String get reserveSeatsInfoTitle => locale == AppLocale.fr
      ? CopyFr.reserveSeats.infoTitle
      : CopyAr.reserveSeats.infoTitle;

  String get reserveSeatsInfoBody => locale == AppLocale.fr
      ? CopyFr.reserveSeats.infoBody
      : CopyAr.reserveSeats.infoBody;

  String get reserveSeatsRecap => locale == AppLocale.fr
      ? CopyFr.reserveSeats.recap
      : CopyAr.reserveSeats.recap;

  String get reserveSeatsConfirm => locale == AppLocale.fr
      ? CopyFr.reserveSeats.confirm
      : CopyAr.reserveSeats.confirm;

  String get reserveSeatsSoldOutCta => locale == AppLocale.fr
      ? CopyFr.reserveSeats.soldOutCta
      : CopyAr.reserveSeats.soldOutCta;

  String get reserveSeatsErrSoldOut => locale == AppLocale.fr
      ? CopyFr.reserveSeats.errSoldOut
      : CopyAr.reserveSeats.errSoldOut;

  String get reserveSeatsErrNotEnough => locale == AppLocale.fr
      ? CopyFr.reserveSeats.errNotEnough
      : CopyAr.reserveSeats.errNotEnough;

  String get agreementCheckboxLabel => locale == AppLocale.fr
      ? CopyFr.reserveSeats.agreementCheckboxLabel
      : CopyAr.reserveSeats.agreementCheckboxLabel;

  String get agreementReadRules => locale == AppLocale.fr
      ? CopyFr.reserveSeats.agreementReadRules
      : CopyAr.reserveSeats.agreementReadRules;

  // ============================================
  // Ticket
  // ============================================
  String get ticketTitle =>
      locale == AppLocale.fr ? CopyFr.ticket.title : CopyAr.ticket.title;

  String get ticketLoading =>
      locale == AppLocale.fr ? CopyFr.ticket.loading : CopyAr.ticket.loading;

  String get ticketPendingTitle => locale == AppLocale.fr
      ? CopyFr.ticket.pendingTitle
      : CopyAr.ticket.pendingTitle;

  String get ticketPendingDesc => locale == AppLocale.fr
      ? CopyFr.ticket.pendingDesc
      : CopyAr.ticket.pendingDesc;

  String get ticketShowTickets => locale == AppLocale.fr
      ? CopyFr.ticket.showTickets
      : CopyAr.ticket.showTickets;

  String get ticketViewReservations => locale == AppLocale.fr
      ? CopyFr.ticket.viewReservations
      : CopyAr.ticket.viewReservations;

  String get ticketRulesReminder => locale == AppLocale.fr
      ? CopyFr.ticket.rulesReminder
      : CopyAr.ticket.rulesReminder;

  String get ticketRefresh =>
      locale == AppLocale.fr ? CopyFr.ticket.refresh : CopyAr.ticket.refresh;

  String get ticketOfflineBanner => locale == AppLocale.fr
      ? CopyFr.ticket.offlineBanner
      : CopyAr.ticket.offlineBanner;

  String get ticketCountSingle => locale == AppLocale.fr
      ? CopyFr.ticket.countSingle
      : CopyAr.ticket.countSingle;

  String ticketCountMultiple(int idx, int total) => locale == AppLocale.fr
      ? CopyFr.ticket.countMultiple(idx, total)
      : CopyAr.ticket.countMultiple(idx, total);

  String get ticketSwipeHint => locale == AppLocale.fr
      ? CopyFr.ticket.swipeHint
      : CopyAr.ticket.swipeHint;

  String get ticketUsed =>
      locale == AppLocale.fr ? CopyFr.ticket.ticketUsed : CopyAr.ticket.ticketUsed;

  String get ticketValid =>
      locale == AppLocale.fr ? CopyFr.ticket.ticketValid : CopyAr.ticket.ticketValid;

  String get ticketCheckedInLabel => locale == AppLocale.fr
      ? CopyFr.ticket.checkedInLabel
      : CopyAr.ticket.checkedInLabel;

  String get ticketUsedLabel => locale == AppLocale.fr
      ? CopyFr.ticket.usedLabel
      : CopyAr.ticket.usedLabel;

  String get ticketHolderLabel =>
      locale == AppLocale.fr ? 'Titulaire du billet' : 'صاحب التذكرة';

  String get avatarNoFace => locale == AppLocale.fr
      ? 'Aucun visage détecté. Prends une photo de ton visage.'
      : 'لم يتم اكتشاف وجه. التقط صورة لوجهك.';

  // Why a profile photo was refused. Neutral wording on purpose: the same
  // camera serves the member's own selfie, door staff photographing someone,
  // and on-site registration.
  String get avatarFaceTooSmall => locale == AppLocale.fr
      ? 'Rapprochez-vous : le visage doit remplir le cadre.'
      : 'اقترب أكثر: يجب أن يملأ الوجه الإطار.';

  String get avatarMultipleFaces => locale == AppLocale.fr
      ? 'Une seule personne sur la photo.'
      : 'شخص واحد فقط في الصورة.';

  String get avatarNotFacing => locale == AppLocale.fr
      ? 'Le visage doit être tourné vers l\'objectif.'
      : 'يجب أن يكون الوجه مقابلاً للكاميرا.';

  String get avatarEyesClosed => locale == AppLocale.fr
      ? 'Les yeux doivent être ouverts.'
      : 'يجب أن تكون العينان مفتوحتين.';

  // Social accounts on the profile — optional, for collaborations and castings.
  String get editSectionSocial =>
      locale == AppLocale.fr ? 'Réseaux sociaux' : 'مواقع التواصل';

  String get socialPurpose => locale == AppLocale.fr
      ? 'Facultatif — pour vous proposer des collaborations et des castings.'
      : 'اختياري — لنقترح عليك تعاونات وفرص كاستينغ.';

  String get socialUsernameHint =>
      locale == AppLocale.fr ? "nom d'utilisateur" : 'اسم المستخدم';

  String get socialCheck => locale == AppLocale.fr ? 'Vérifier' : 'تحقق';

  String get socialInvalid => locale == AppLocale.fr
      ? "Tapez votre nom d'utilisateur, ou collez le lien de votre profil."
      : 'اكتب اسم المستخدم أو الصق رابط حسابك.';

  String get socialOpenError => locale == AppLocale.fr
      ? "Impossible d'ouvrir ce profil."
      : 'تعذّر فتح هذا الحساب.';

  // Tutorial clips (GET /api/app-config → tutorials). "tu", like the voice-over.
  String get tutorialWatch =>
      locale == AppLocale.fr ? 'Voir la vidéo' : 'شوف الفيديو';

  String get tutorialHowTo =>
      locale == AppLocale.fr ? 'Voir comment faire' : 'شوف كيفاش';

  String get tutorialProfileTitle => locale == AppLocale.fr
      ? 'Compléter mon profil'
      : 'تكميل الملف الشخصي';

  String get tutorialReservationTitle => locale == AppLocale.fr
      ? 'Réserver avec une invitation'
      : 'الحجز برابط الدعوة';

  String get tutorialProfileOffer => locale == AppLocale.fr
      ? 'Première fois ? Regarde comment compléter ton profil.'
      : 'أول مرة؟ شوف كيفاش تكمل الملف الشخصي ديالك.';

  String get tutorialReservationOffer => locale == AppLocale.fr
      ? 'Comment réserver avec cette invitation ?'
      : 'كيفاش تحجز بهاد الدعوة؟';

  String get tutorialDismiss => locale == AppLocale.fr ? 'Masquer' : 'خبي';

  String get tutorialUnavailable => locale == AppLocale.fr
      ? 'Impossible de lire la vidéo pour le moment. Vérifie ta connexion.'
      : 'ما قدرناش نشغلو الفيديو دابا. تأكد من الاتصال ديالك.';

  String get avatarFrameHint => locale == AppLocale.fr
      ? 'Placez votre visage dans le cadre'
      : 'ضع وجهك داخل الإطار';

  String get avatarCameraError => locale == AppLocale.fr
      ? 'Impossible d\'ouvrir la caméra.'
      : 'تعذّر فتح الكاميرا.';

  String ticketSeats(int n) =>
      locale == AppLocale.fr ? CopyFr.ticket.seats(n) : CopyAr.ticket.seats(n);

  String get ticketQrHintValid => locale == AppLocale.fr
      ? CopyFr.ticket.qrHintValid
      : CopyAr.ticket.qrHintValid;

  String get ticketQrHintUsed => locale == AppLocale.fr
      ? CopyFr.ticket.qrHintUsed
      : CopyAr.ticket.qrHintUsed;

  String ticketCodeCopied(String code) => locale == AppLocale.fr
      ? CopyFr.ticket.codeCopied(code)
      : CopyAr.ticket.codeCopied(code);

  String ticketCheckinAt(String date) => locale == AppLocale.fr
      ? CopyFr.ticket.checkinAt(date)
      : CopyAr.ticket.checkinAt(date);

  // ============================================
  // Browse
  // ============================================
  String get browseTitle =>
      locale == AppLocale.fr ? CopyFr.browse.title : CopyAr.browse.title;

  String get browseFilterTooltip => locale == AppLocale.fr
      ? CopyFr.browse.filterTooltip
      : CopyAr.browse.filterTooltip;

  String get browseNoResults => locale == AppLocale.fr
      ? CopyFr.browse.noResults
      : CopyAr.browse.noResults;

  String get browseNoResultsDesc => locale == AppLocale.fr
      ? CopyFr.browse.noResultsDesc
      : CopyAr.browse.noResultsDesc;

  String get browseClearFilters => locale == AppLocale.fr
      ? CopyFr.browse.clearFilters
      : CopyAr.browse.clearFilters;

  String get browseSearchHint => locale == AppLocale.fr
      ? CopyFr.browse.searchHint
      : CopyAr.browse.searchHint;

  String get browseAllCities => locale == AppLocale.fr
      ? CopyFr.browse.allCities
      : CopyAr.browse.allCities;

  String get browseFilterByChannel => locale == AppLocale.fr
      ? CopyFr.browse.filterByChannel
      : CopyAr.browse.filterByChannel;

  String get browseNoChannels => locale == AppLocale.fr
      ? CopyFr.browse.noChannels
      : CopyAr.browse.noChannels;

  String get browseClearAllFilters => locale == AppLocale.fr
      ? CopyFr.browse.clearAllFilters
      : CopyAr.browse.clearAllFilters;

  String get browseSoldOutBadge => locale == AppLocale.fr
      ? CopyFr.browse.soldOutBadge
      : CopyAr.browse.soldOutBadge;

  String browseAvailableSeats(int n) => locale == AppLocale.fr
      ? CopyFr.browse.availableSeats(n)
      : CopyAr.browse.availableSeats(n);

  // ============================================
  // Notifications
  // ============================================
  String get notificationsTitle => locale == AppLocale.fr
      ? CopyFr.notifications.title
      : CopyAr.notifications.title;

  String get notificationsMarkAllRead => locale == AppLocale.fr
      ? CopyFr.notifications.markAllRead
      : CopyAr.notifications.markAllRead;

  String get notificationsMarkAllReadSuccess => locale == AppLocale.fr
      ? CopyFr.notifications.markAllReadSuccess
      : CopyAr.notifications.markAllReadSuccess;

  String get notificationsDeleteAll => locale == AppLocale.fr
      ? CopyFr.notifications.deleteAll
      : CopyAr.notifications.deleteAll;

  String get notificationsDeleteAllTitle => locale == AppLocale.fr
      ? CopyFr.notifications.deleteAllTitle
      : CopyAr.notifications.deleteAllTitle;

  String get notificationsDeleteAllContent => locale == AppLocale.fr
      ? CopyFr.notifications.deleteAllContent
      : CopyAr.notifications.deleteAllContent;

  String get notificationsDeleteAllConfirm => locale == AppLocale.fr
      ? CopyFr.notifications.deleteAllConfirm
      : CopyAr.notifications.deleteAllConfirm;

  String get notificationsDeleteAllSuccess => locale == AppLocale.fr
      ? CopyFr.notifications.deleteAllSuccess
      : CopyAr.notifications.deleteAllSuccess;

  String get notificationsDismissed => locale == AppLocale.fr
      ? CopyFr.notifications.dismissed
      : CopyAr.notifications.dismissed;

  String get notificationsEmptyTitle => locale == AppLocale.fr
      ? CopyFr.notifications.emptyTitle
      : CopyAr.notifications.emptyTitle;

  String get notificationsEmptyDesc => locale == AppLocale.fr
      ? CopyFr.notifications.emptyDesc
      : CopyAr.notifications.emptyDesc;

  // ============================================
  // Nav Tabs
  // ============================================
  String get navTabEmissions => locale == AppLocale.fr
      ? CopyFr.navTabs.emissions
      : CopyAr.navTabs.emissions;

  String get navTabExplorer => locale == AppLocale.fr
      ? CopyFr.navTabs.explorer
      : CopyAr.navTabs.explorer;

  String get navTabReservations => locale == AppLocale.fr
      ? CopyFr.navTabs.reservations
      : CopyAr.navTabs.reservations;

  String get navTabTicket => locale == AppLocale.fr
      ? CopyFr.navTabs.ticket
      : CopyAr.navTabs.ticket;

  String get navTabProfile => locale == AppLocale.fr
      ? CopyFr.navTabs.profile
      : CopyAr.navTabs.profile;

  // ============================================
  // Casting
  // ============================================

  /// The whole section in one object rather than fifty getters: the copy is
  /// structured — each pose carries its own instructions — and flattening it
  /// would lose that shape. Both languages implement [CastingCopy], so the
  /// analyser refuses a build where one of them is missing a string.
  CastingCopy get casting =>
      locale == AppLocale.fr ? CopyFr.casting : CopyAr.casting;

  /// "Présents" and departures (staff, admin, scanner).
  DepartureCopy get departures =>
      locale == AppLocale.fr ? CopyFr.departures : CopyAr.departures;

  // ============================================
  // Staff Check-in
  // ============================================
  String get staffCheckInTitle => locale == AppLocale.fr
      ? CopyFr.staff.checkInTitle
      : CopyAr.staff.checkInTitle;

  String get staffTabScanQr => locale == AppLocale.fr
      ? CopyFr.staff.tabScanQr
      : CopyAr.staff.tabScanQr;

  String get staffTabManualCode => locale == AppLocale.fr
      ? CopyFr.staff.tabManualCode
      : CopyAr.staff.tabManualCode;

  String get staffScanInstruction => locale == AppLocale.fr
      ? CopyFr.staff.scanInstruction
      : CopyAr.staff.scanInstruction;

  String get staffManualPlaceholder => locale == AppLocale.fr
      ? CopyFr.staff.manualPlaceholder
      : CopyAr.staff.manualPlaceholder;

  String get staffValidateButton => locale == AppLocale.fr
      ? CopyFr.staff.validateButton
      : CopyAr.staff.validateButton;

  String get staffSuccessTitle => locale == AppLocale.fr
      ? CopyFr.staff.successTitle
      : CopyAr.staff.successTitle;

  String get staffAlreadyUsed => locale == AppLocale.fr
      ? CopyFr.staff.alreadyUsed
      : CopyAr.staff.alreadyUsed;

  String get staffNotFound => locale == AppLocale.fr
      ? CopyFr.staff.notFound
      : CopyAr.staff.notFound;

  String get staffAccessDenied => locale == AppLocale.fr
      ? CopyFr.staff.accessDenied
      : CopyAr.staff.accessDenied;

  String get staffAccessDeniedSubtitle => locale == AppLocale.fr
      ? CopyFr.staff.accessDeniedSubtitle
      : CopyAr.staff.accessDeniedSubtitle;

  String get staffSessionExpired => locale == AppLocale.fr
      ? CopyFr.staff.sessionExpired
      : CopyAr.staff.sessionExpired;

  String get staffNetworkError => locale == AppLocale.fr
      ? CopyFr.staff.networkError
      : CopyAr.staff.networkError;


  // ============================================
  // Shuttle manifest (staff)
  // ============================================
  String get staffManifestTitle => locale == AppLocale.fr
      ? CopyFr.staff.manifestTitle
      : CopyAr.staff.manifestTitle;

  String get staffManifestSubtitle => locale == AppLocale.fr
      ? CopyFr.staff.manifestSubtitle
      : CopyAr.staff.manifestSubtitle;

  String get staffManifestPickEpisode => locale == AppLocale.fr
      ? CopyFr.staff.manifestPickEpisode
      : CopyAr.staff.manifestPickEpisode;

  String get staffManifestNoEpisodes => locale == AppLocale.fr
      ? CopyFr.staff.manifestNoEpisodes
      : CopyAr.staff.manifestNoEpisodes;

  String get staffManifestNoEpisodesSubtitle => locale == AppLocale.fr
      ? CopyFr.staff.manifestNoEpisodesSubtitle
      : CopyAr.staff.manifestNoEpisodesSubtitle;

  String get staffManifestNoShuttle => locale == AppLocale.fr
      ? CopyFr.staff.manifestNoShuttle
      : CopyAr.staff.manifestNoShuttle;

  String get staffManifestNoShuttleSubtitle => locale == AppLocale.fr
      ? CopyFr.staff.manifestNoShuttleSubtitle
      : CopyAr.staff.manifestNoShuttleSubtitle;

  String get staffManifestNobody => locale == AppLocale.fr
      ? CopyFr.staff.manifestNobody
      : CopyAr.staff.manifestNobody;

  String get staffManifestNobodySubtitle => locale == AppLocale.fr
      ? CopyFr.staff.manifestNobodySubtitle
      : CopyAr.staff.manifestNobodySubtitle;

  String get staffManifestPeopleIn => locale == AppLocale.fr
      ? CopyFr.staff.manifestPeopleIn
      : CopyAr.staff.manifestPeopleIn;

  String get staffManifestWaiting => locale == AppLocale.fr
      ? CopyFr.staff.manifestWaiting
      : CopyAr.staff.manifestWaiting;

  String get staffManifestOwnMeans => locale == AppLocale.fr
      ? CopyFr.staff.manifestOwnMeans
      : CopyAr.staff.manifestOwnMeans;

  String get staffManifestPeople => locale == AppLocale.fr
      ? CopyFr.staff.manifestPeople
      : CopyAr.staff.manifestPeople;

  String get staffManifestEmptyStop => locale == AppLocale.fr
      ? CopyFr.staff.manifestEmptyStop
      : CopyAr.staff.manifestEmptyStop;

  String get staffManifestOffList => locale == AppLocale.fr
      ? CopyFr.staff.manifestOffList
      : CopyAr.staff.manifestOffList;

  String get staffManifestOrphanWarning => locale == AppLocale.fr
      ? CopyFr.staff.manifestOrphanWarning
      : CopyAr.staff.manifestOrphanWarning;

  String get staffManifestShare => locale == AppLocale.fr
      ? CopyFr.staff.manifestShare
      : CopyAr.staff.manifestShare;

  String get staffManifestSharePdf => locale == AppLocale.fr
      ? CopyFr.staff.manifestSharePdf
      : CopyAr.staff.manifestSharePdf;

  String get staffManifestShareText => locale == AppLocale.fr
      ? CopyFr.staff.manifestShareText
      : CopyAr.staff.manifestShareText;

  String get staffManifestShareError => locale == AppLocale.fr
      ? CopyFr.staff.manifestShareError
      : CopyAr.staff.manifestShareError;

  String get staffManifestRefresh => locale == AppLocale.fr
      ? CopyFr.staff.manifestRefresh
      : CopyAr.staff.manifestRefresh;

  String get staffManifestLoadError => locale == AppLocale.fr
      ? CopyFr.staff.manifestLoadError
      : CopyAr.staff.manifestLoadError;

  String get staffManifestGeneratedAt => locale == AppLocale.fr
      ? CopyFr.staff.manifestGeneratedAt
      : CopyAr.staff.manifestGeneratedAt;

  String get staffProfileManifestTile => locale == AppLocale.fr
      ? CopyFr.staff.profileManifestTile
      : CopyAr.staff.profileManifestTile;

  String get staffScanAnother => locale == AppLocale.fr
      ? CopyFr.staff.scanAnother
      : CopyAr.staff.scanAnother;

  String get staffValidateEntry => locale == AppLocale.fr
      ? CopyFr.staff.validateEntry
      : CopyAr.staff.validateEntry;

  String get staffReturnPointTitle => locale == AppLocale.fr
      ? CopyFr.staff.returnPointTitle
      : CopyAr.staff.returnPointTitle;

  String get staffReturnPointQuestion => locale == AppLocale.fr
      ? CopyFr.staff.returnPointQuestion
      : CopyAr.staff.returnPointQuestion;

  String get staffReturnPointNone => locale == AppLocale.fr
      ? CopyFr.staff.returnPointNone
      : CopyAr.staff.returnPointNone;

  String get staffReturnPointSaveError => locale == AppLocale.fr
      ? CopyFr.staff.returnPointSaveError
      : CopyAr.staff.returnPointSaveError;


  String get staffCameraPermissionDenied => locale == AppLocale.fr
      ? CopyFr.staff.cameraPermissionDenied
      : CopyAr.staff.cameraPermissionDenied;

  String get staffCameraPermissionSubtitle => locale == AppLocale.fr
      ? CopyFr.staff.cameraPermissionSubtitle
      : CopyAr.staff.cameraPermissionSubtitle;

  String get staffOpenSettings => locale == AppLocale.fr
      ? CopyFr.staff.openSettings
      : CopyAr.staff.openSettings;

  String get staffCheckedInAt => locale == AppLocale.fr
      ? CopyFr.staff.checkedInAt
      : CopyAr.staff.checkedInAt;

  String get staffCheckInLabel => locale == AppLocale.fr
      ? CopyFr.staff.profileStaffTile
      : CopyAr.staff.profileStaffTile;

  String get staffRetry => locale == AppLocale.fr
      ? CopyFr.staff.retry
      : CopyAr.staff.retry;

  String get staffBack => locale == AppLocale.fr
      ? CopyFr.staff.back
      : CopyAr.staff.back;

  String get staffAttendeeName => locale == AppLocale.fr
      ? CopyFr.staff.attendeeName
      : CopyAr.staff.attendeeName;

  String get staffShowLabel => locale == AppLocale.fr
      ? CopyFr.staff.showLabel
      : CopyAr.staff.showLabel;

  String get staffTicketCodeLabel => locale == AppLocale.fr
      ? CopyFr.staff.ticketCodeLabel
      : CopyAr.staff.ticketCodeLabel;

  // ============================================
  // Rules (locale-aware items list)
  // ============================================
  List<({String title, String description})> get rulesItems =>
      locale == AppLocale.fr
          ? CopyFr.rules.items
              .map((e) => (title: e.title, description: e.description))
              .toList()
          : CopyAr.rules.items
              .map((e) => (title: e.title, description: e.description))
              .toList();

  // ============================================
  // Conditions de participation
  // ============================================
  String get conditionsTitle => locale == AppLocale.fr
      ? CopyFr.conditions.title
      : CopyAr.conditions.title;

  String get conditionsSubtitle => locale == AppLocale.fr
      ? CopyFr.conditions.subtitle
      : CopyAr.conditions.subtitle;

  String get conditionsProfileTileLabel => locale == AppLocale.fr
      ? CopyFr.conditions.profileTileLabel
      : CopyAr.conditions.profileTileLabel;

  String get conditionsValidationTitle => locale == AppLocale.fr
      ? CopyFr.conditions.validationTitle
      : CopyAr.conditions.validationTitle;

  List<String> get conditionsCheckboxItems => locale == AppLocale.fr
      ? CopyFr.conditions.checkboxItems
      : CopyAr.conditions.checkboxItems;

  List<ConditionSection> get conditionsSections => locale == AppLocale.fr
      ? CopyFr.conditions.sections
      : CopyAr.conditions.sections;

  // ============================================
  // How it works / Comment ça marche
  // ============================================
  String get howItWorksTitle => locale == AppLocale.fr
      ? CopyFr.howItWorks.title
      : CopyAr.howItWorks.title;

  String get howItWorksProfileTileLabel => locale == AppLocale.fr
      ? CopyFr.howItWorks.profileTileLabel
      : CopyAr.howItWorks.profileTileLabel;

  String get howItWorksProfileTileSubtitle => locale == AppLocale.fr
      ? CopyFr.howItWorks.profileTileSubtitle
      : CopyAr.howItWorks.profileTileSubtitle;

  String get howItWorksTrackClient => locale == AppLocale.fr
      ? CopyFr.howItWorks.trackClient
      : CopyAr.howItWorks.trackClient;

  String get howItWorksTrackParrain => locale == AppLocale.fr
      ? CopyFr.howItWorks.trackParrain
      : CopyAr.howItWorks.trackParrain;

  String get howItWorksWatchVideo => locale == AppLocale.fr
      ? CopyFr.howItWorks.watchVideo
      : CopyAr.howItWorks.watchVideo;

  String get howItWorksGotIt => locale == AppLocale.fr
      ? CopyFr.howItWorks.gotIt
      : CopyAr.howItWorks.gotIt;

  String get howItWorksNext => locale == AppLocale.fr
      ? CopyFr.howItWorks.next
      : CopyAr.howItWorks.next;

  // ============================================
  // Charge public ("Mode Chargé Public")
  // ============================================
  ChargePublicCopy get cp =>
      locale == AppLocale.fr ? CopyFr.chargePublic : CopyAr.chargePublic;

  // ============================================
  // Badges & levels (gamification)
  // ============================================
  bool get _fr => locale == AppLocale.fr;

  String get badgeProfileTitle => _fr ? 'Mon badge' : 'شارتي';

  // ── Noter l'application ──
  String get rateAppTitle => _fr ? "Noter l'application" : 'قيّم التطبيق';
  String get rateAppSubtitle =>
      _fr ? 'Votre avis nous aide à faire mieux' : 'رأيك كيعاوننا نتحسنو';
  String get badgeCpTitle => _fr ? 'Mon niveau' : 'مستواي';
  String badgeLevelShort(int level) => _fr ? 'Niv. $level' : 'مستوى $level';
  String get badgeMaxReached =>
      _fr ? 'Niveau maximum atteint 🎉' : 'بلغت أعلى مستوى 🎉';

  String badgeAttendanceCount(int n) =>
      _fr ? '$n présence${n > 1 ? 's' : ''}' : '$n حضور';
  String badgeCpCount(int n) =>
      _fr ? '$n invité${n > 1 ? 's' : ''} ramené${n > 1 ? 's' : ''}' : '$n مدعو';

  String badgeRemainingAttendance(int n) => _fr
      ? 'Encore $n présence${n > 1 ? 's' : ''} pour le niveau suivant'
      : 'بقي $n حضور للمستوى التالي';
  String badgeRemainingCp(int n) => _fr
      ? 'Encore $n invité${n > 1 ? 's' : ''} pour le niveau suivant'
      : 'بقي $n مدعو للمستوى التالي';

  String howItWorksStepCounter(int current, int total) => locale == AppLocale.fr
      ? CopyFr.howItWorks.stepCounter(current, total)
      : CopyAr.howItWorks.stepCounter(current, total);

  String get howItWorksClientHeadline => locale == AppLocale.fr
      ? CopyFr.howItWorks.clientHeadline
      : CopyAr.howItWorks.clientHeadline;

  String get howItWorksClientSubtitle => locale == AppLocale.fr
      ? CopyFr.howItWorks.clientSubtitle
      : CopyAr.howItWorks.clientSubtitle;

  List<HowToStep> get howItWorksClientSteps => locale == AppLocale.fr
      ? CopyFr.howItWorks.clientSteps
      : CopyAr.howItWorks.clientSteps;

  String get howItWorksParrainHeadline => locale == AppLocale.fr
      ? CopyFr.howItWorks.parrainHeadline
      : CopyAr.howItWorks.parrainHeadline;

  String get howItWorksParrainSubtitle => locale == AppLocale.fr
      ? CopyFr.howItWorks.parrainSubtitle
      : CopyAr.howItWorks.parrainSubtitle;

  List<HowToStep> get howItWorksParrainSteps => locale == AppLocale.fr
      ? CopyFr.howItWorks.parrainSteps
      : CopyAr.howItWorks.parrainSteps;

  String? get howItWorksParrainVideoUrl => locale == AppLocale.fr
      ? CopyFr.howItWorks.parrainVideoUrl
      : CopyAr.howItWorks.parrainVideoUrl;

  // ============================================
  // Inscription sur place (on-site registration)
  // ============================================
  String get onSiteTitle => locale == AppLocale.fr
      ? CopyFr.onSite.title
      : CopyAr.onSite.title;

  String get onSiteSubtitle => locale == AppLocale.fr
      ? CopyFr.onSite.subtitle
      : CopyAr.onSite.subtitle;

  String get onSiteProfileTileSubtitle => locale == AppLocale.fr
      ? CopyFr.onSite.profileTileSubtitle
      : CopyAr.onSite.profileTileSubtitle;

  String get onSiteSessionTitle => locale == AppLocale.fr
      ? CopyFr.onSite.sessionTitle
      : CopyAr.onSite.sessionTitle;

  String get onSiteChooseShow => locale == AppLocale.fr
      ? CopyFr.onSite.chooseShow
      : CopyAr.onSite.chooseShow;

  String get onSiteChooseEpisode => locale == AppLocale.fr
      ? CopyFr.onSite.chooseEpisode
      : CopyAr.onSite.chooseEpisode;

  String get onSiteChooseChargePublic => locale == AppLocale.fr
      ? CopyFr.onSite.chooseChargePublic
      : CopyAr.onSite.chooseChargePublic;

  String get onSiteNoChargePublic => locale == AppLocale.fr
      ? CopyFr.onSite.noChargePublic
      : CopyAr.onSite.noChargePublic;

  String get onSiteSearchChargePublic => locale == AppLocale.fr
      ? CopyFr.onSite.searchChargePublic
      : CopyAr.onSite.searchChargePublic;

  String get onSiteChangeSession => locale == AppLocale.fr
      ? CopyFr.onSite.changeSession
      : CopyAr.onSite.changeSession;

  String get onSiteStartSession => locale == AppLocale.fr
      ? CopyFr.onSite.startSession
      : CopyAr.onSite.startSession;

  String get onSiteNoEpisodes => locale == AppLocale.fr
      ? CopyFr.onSite.noEpisodes
      : CopyAr.onSite.noEpisodes;

  String get onSiteStepPhoto => locale == AppLocale.fr
      ? CopyFr.onSite.stepPhoto
      : CopyAr.onSite.stepPhoto;

  String get onSiteStepIdentity => locale == AppLocale.fr
      ? CopyFr.onSite.stepIdentity
      : CopyAr.onSite.stepIdentity;

  String get onSiteStepLocation => locale == AppLocale.fr
      ? CopyFr.onSite.stepLocation
      : CopyAr.onSite.stepLocation;

  String get onSiteTakePhoto => locale == AppLocale.fr
      ? CopyFr.onSite.takePhoto
      : CopyAr.onSite.takePhoto;

  String get onSiteRetakePhoto => locale == AppLocale.fr
      ? CopyFr.onSite.retakePhoto
      : CopyAr.onSite.retakePhoto;

  String get onSitePhotoHint => locale == AppLocale.fr
      ? CopyFr.onSite.photoHint
      : CopyAr.onSite.photoHint;

  String get onSitePhotoRequired => locale == AppLocale.fr
      ? CopyFr.onSite.photoRequired
      : CopyAr.onSite.photoRequired;

  String get onSiteFirstName => locale == AppLocale.fr
      ? CopyFr.onSite.firstName
      : CopyAr.onSite.firstName;

  String get onSiteLastName => locale == AppLocale.fr
      ? CopyFr.onSite.lastName
      : CopyAr.onSite.lastName;

  String get onSiteGender => locale == AppLocale.fr
      ? CopyFr.onSite.gender
      : CopyAr.onSite.gender;

  String get onSiteMale => locale == AppLocale.fr
      ? CopyFr.onSite.male
      : CopyAr.onSite.male;

  String get onSiteFemale => locale == AppLocale.fr
      ? CopyFr.onSite.female
      : CopyAr.onSite.female;

  String get onSiteBirthday => locale == AppLocale.fr
      ? CopyFr.onSite.birthday
      : CopyAr.onSite.birthday;

  String get onSitePhone => locale == AppLocale.fr
      ? CopyFr.onSite.phone
      : CopyAr.onSite.phone;

  String get onSiteEmail => locale == AppLocale.fr
      ? CopyFr.onSite.email
      : CopyAr.onSite.email;

  String get onSiteEmailHint => locale == AppLocale.fr
      ? CopyFr.onSite.emailHint
      : CopyAr.onSite.emailHint;

  String get onSiteCity => locale == AppLocale.fr
      ? CopyFr.onSite.city
      : CopyAr.onSite.city;

  String get onSiteDistrict => locale == AppLocale.fr
      ? CopyFr.onSite.district
      : CopyAr.onSite.district;

  String get onSiteNext => locale == AppLocale.fr
      ? CopyFr.onSite.next
      : CopyAr.onSite.next;

  String get onSiteBack => locale == AppLocale.fr
      ? CopyFr.onSite.back
      : CopyAr.onSite.back;

  String get onSiteSubmit => locale == AppLocale.fr
      ? CopyFr.onSite.submit
      : CopyAr.onSite.submit;

  String get onSiteNextPerson => locale == AppLocale.fr
      ? CopyFr.onSite.nextPerson
      : CopyAr.onSite.nextPerson;

  String get onSiteClose => locale == AppLocale.fr
      ? CopyFr.onSite.close
      : CopyAr.onSite.close;

  String get onSiteDoneTitle => locale == AppLocale.fr
      ? CopyFr.onSite.doneTitle
      : CopyAr.onSite.doneTitle;

  String get onSiteCredentials => locale == AppLocale.fr
      ? CopyFr.onSite.credentials
      : CopyAr.onSite.credentials;

  String get onSiteCredentialsHint => locale == AppLocale.fr
      ? CopyFr.onSite.credentialsHint
      : CopyAr.onSite.credentialsHint;

  String get onSiteCopyCredentials => locale == AppLocale.fr
      ? CopyFr.onSite.copyCredentials
      : CopyAr.onSite.copyCredentials;

  String get onSiteCopied => locale == AppLocale.fr
      ? CopyFr.onSite.copied
      : CopyAr.onSite.copied;

  String get onSiteRequiredFields => locale == AppLocale.fr
      ? CopyFr.onSite.requiredFields
      : CopyAr.onSite.requiredFields;

  String get onSiteGenericError => locale == AppLocale.fr
      ? CopyFr.onSite.genericError
      : CopyAr.onSite.genericError;

  String onSiteRegisteredCount(int n) => locale == AppLocale.fr
      ? CopyFr.onSite.registeredCount(n)
      : CopyAr.onSite.registeredCount(n);

  String onSiteStepCounter(int current, int total) => locale == AppLocale.fr
      ? CopyFr.onSite.stepCounter(current, total)
      : CopyAr.onSite.stepCounter(current, total);

  String onSiteDoneSubtitle(String name) => locale == AppLocale.fr
      ? CopyFr.onSite.doneSubtitle(name)
      : CopyAr.onSite.doneSubtitle(name);

  String onSiteRewardEarned(int amount) => locale == AppLocale.fr
      ? CopyFr.onSite.rewardEarned(amount)
      : CopyAr.onSite.rewardEarned(amount);

  // ============================================
  // Referral / Parrainage
  // ============================================
  String get referralTitle => locale == AppLocale.fr
      ? CopyFr.referral.title
      : CopyAr.referral.title;

  String get referralMyCode => locale == AppLocale.fr
      ? CopyFr.referral.myReferralCode
      : CopyAr.referral.myReferralCode;

  String get referralCopyCode => locale == AppLocale.fr
      ? CopyFr.referral.copyCode
      : CopyAr.referral.copyCode;

  String get referralCodeCopied => locale == AppLocale.fr
      ? CopyFr.referral.codeCopied
      : CopyAr.referral.codeCopied;

  String get referralInviteFriend => locale == AppLocale.fr
      ? CopyFr.referral.inviteFriend
      : CopyAr.referral.inviteFriend;

  String get referralGenerateLink => locale == AppLocale.fr
      ? CopyFr.referral.generateLink
      : CopyAr.referral.generateLink;

  String get referralShareLink => locale == AppLocale.fr
      ? CopyFr.referral.shareLink
      : CopyAr.referral.shareLink;

  String referralInvitesYou(String name) => locale == AppLocale.fr
      ? CopyFr.referral.invitesYou(name)
      : CopyAr.referral.invitesYou(name);

  String get referralReserveNow => locale == AppLocale.fr
      ? CopyFr.referral.reserveNow
      : CopyAr.referral.reserveNow;

  String get referralCodeLabel => locale == AppLocale.fr
      ? CopyFr.referral.referralCodeLabel
      : CopyAr.referral.referralCodeLabel;

  String get referralCodeHint => locale == AppLocale.fr
      ? CopyFr.referral.referralCodeHint
      : CopyAr.referral.referralCodeHint;

  String get referralTotalInvited => locale == AppLocale.fr
      ? CopyFr.referral.totalInvited
      : CopyAr.referral.totalInvited;

  String get referralTotalAttended => locale == AppLocale.fr
      ? CopyFr.referral.totalAttended
      : CopyAr.referral.totalAttended;

  String get referralPending => locale == AppLocale.fr
      ? CopyFr.referral.pending
      : CopyAr.referral.pending;

  String get referralPointsEarned => locale == AppLocale.fr
      ? CopyFr.referral.pointsEarned
      : CopyAr.referral.pointsEarned;

  String get referralMyLinks => locale == AppLocale.fr
      ? CopyFr.referral.myLinks
      : CopyAr.referral.myLinks;

  String get referralClicks => locale == AppLocale.fr
      ? CopyFr.referral.clicks
      : CopyAr.referral.clicks;

  String get referralConversions => locale == AppLocale.fr
      ? CopyFr.referral.conversions
      : CopyAr.referral.conversions;

  String get referralExpired => locale == AppLocale.fr
      ? CopyFr.referral.expired
      : CopyAr.referral.expired;

  String get referralLinkExpired => locale == AppLocale.fr
      ? CopyFr.referral.linkExpired
      : CopyAr.referral.linkExpired;

  String get referralLinkInvalid => locale == AppLocale.fr
      ? CopyFr.referral.linkInvalid
      : CopyAr.referral.linkInvalid;

  String get referralShowUnavailable => locale == AppLocale.fr
      ? CopyFr.referral.showUnavailable
      : CopyAr.referral.showUnavailable;

  String referralShareMessage(String showTitle, String link) =>
      locale == AppLocale.fr
          ? CopyFr.referral.shareMessage(showTitle, link)
          : CopyAr.referral.shareMessage(showTitle, link);

  String episodeShareMessage(
          String showTitle, String episodeLabel, String dateStr, String link) =>
      locale == AppLocale.fr
          ? CopyFr.referral
              .episodeShareMessage(showTitle, episodeLabel, dateStr, link)
          : CopyAr.referral
              .episodeShareMessage(showTitle, episodeLabel, dateStr, link);

  String get referralNoLinksYet => locale == AppLocale.fr
      ? CopyFr.referral.noLinksYet
      : CopyAr.referral.noLinksYet;

  String get referralNoReferralsYet => locale == AppLocale.fr
      ? CopyFr.referral.noReferralsYet
      : CopyAr.referral.noReferralsYet;

  String get referralInviteFriendsEarnPoints => locale == AppLocale.fr
      ? CopyFr.referral.inviteFriendsEarnPoints
      : CopyAr.referral.inviteFriendsEarnPoints;

  String get referralProfileTileLabel => locale == AppLocale.fr
      ? CopyFr.referral.profileTileLabel
      : CopyAr.referral.profileTileLabel;

  String get referralStatsTitle => locale == AppLocale.fr
      ? CopyFr.referral.statsTitle
      : CopyAr.referral.statsTitle;

  String get referralLinksTitle => locale == AppLocale.fr
      ? CopyFr.referral.linksTitle
      : CopyAr.referral.linksTitle;

  // ── Episodes ──────────────────────────────────────────────────────────────

  String get episodeSectionTitle => locale == AppLocale.fr
      ? CopyFr.episode.sectionTitle
      : CopyAr.episode.sectionTitle;

  String episodeCount(int n) => locale == AppLocale.fr
      ? CopyFr.episode.episodeCount(n)
      : CopyAr.episode.episodeCount(n);

  String get reserveEpisode => locale == AppLocale.fr
      ? CopyFr.episode.reserveEpisode
      : CopyAr.episode.reserveEpisode;

  String get noUpcomingEpisodes => locale == AppLocale.fr
      ? CopyFr.episode.noUpcomingEpisodes
      : CopyAr.episode.noUpcomingEpisodes;

  String get nextEpisodeLabel => locale == AppLocale.fr
      ? CopyFr.episode.nextEpisode
      : CopyAr.episode.nextEpisode;

  String get pastEpisodeLabel => locale == AppLocale.fr
      ? CopyFr.episode.pastEpisode
      : CopyAr.episode.pastEpisode;

  String get allEpisodesLabel => locale == AppLocale.fr
      ? CopyFr.episode.allEpisodes
      : CopyAr.episode.allEpisodes;

  String get upcomingEpisodesLabel => locale == AppLocale.fr
      ? CopyFr.episode.upcomingEpisodes
      : CopyAr.episode.upcomingEpisodes;

  String get episodeSoldOut => locale == AppLocale.fr
      ? CopyFr.episode.soldOut
      : CopyAr.episode.soldOut;

  String episodeAvailableSeats(int n) => locale == AppLocale.fr
      ? CopyFr.episode.availableSeats(n)
      : CopyAr.episode.availableSeats(n);

  // ── Reservation Result ────────────────────────────────────────────────────

  String get reservationResultTitle => locale == AppLocale.fr
      ? CopyFr.reservationResult.title
      : CopyAr.reservationResult.title;

  String get reservationResultStatusBadge => locale == AppLocale.fr
      ? CopyFr.reservationResult.statusBadge
      : CopyAr.reservationResult.statusBadge;

  String get reservationResultNumberLabel => locale == AppLocale.fr
      ? CopyFr.reservationResult.summaryNumberLabel
      : CopyAr.reservationResult.summaryNumberLabel;

  String get reservationResultSeatsLabel => locale == AppLocale.fr
      ? CopyFr.reservationResult.summarySeatsLabel
      : CopyAr.reservationResult.summarySeatsLabel;

  String get reservationResultDateLabel => locale == AppLocale.fr
      ? CopyFr.reservationResult.summaryDateLabel
      : CopyAr.reservationResult.summaryDateLabel;

  String get reservationResultExpiresLabel => locale == AppLocale.fr
      ? CopyFr.reservationResult.summaryExpiresLabel
      : CopyAr.reservationResult.summaryExpiresLabel;

  String reservationResultSeats(int n) => locale == AppLocale.fr
      ? CopyFr.reservationResult.seats(n)
      : CopyAr.reservationResult.seats(n);

  String get reservationResultNextStepsTitle => locale == AppLocale.fr
      ? CopyFr.reservationResult.nextStepsTitle
      : CopyAr.reservationResult.nextStepsTitle;

  String get reservationResultStep1 => locale == AppLocale.fr
      ? CopyFr.reservationResult.step1
      : CopyAr.reservationResult.step1;

  String get reservationResultStep2 => locale == AppLocale.fr
      ? CopyFr.reservationResult.step2
      : CopyAr.reservationResult.step2;

  String get reservationResultStep3 => locale == AppLocale.fr
      ? CopyFr.reservationResult.step3
      : CopyAr.reservationResult.step3;

  String get reservationResultCtaMyReservations => locale == AppLocale.fr
      ? CopyFr.reservationResult.ctaMyReservations
      : CopyAr.reservationResult.ctaMyReservations;

  String get reservationResultCtaHome => locale == AppLocale.fr
      ? CopyFr.reservationResult.ctaHome
      : CopyAr.reservationResult.ctaHome;

  // ── Reservation Detail ────────────────────────────────────────────────────

  String get resDetailAppBarTitle => locale == AppLocale.fr
      ? CopyFr.reservationDetail.appBarTitle
      : CopyAr.reservationDetail.appBarTitle;

  String get resDetailMsgPending => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgPending
      : CopyAr.reservationDetail.msgPending;

  String get resDetailMsgApproved => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgApproved
      : CopyAr.reservationDetail.msgApproved;

  String get resDetailMsgRejected => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgRejected
      : CopyAr.reservationDetail.msgRejected;

  String get resDetailMsgCheckedIn => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgCheckedIn
      : CopyAr.reservationDetail.msgCheckedIn;

  String get resDetailMsgCancelled => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgCancelled
      : CopyAr.reservationDetail.msgCancelled;

  String get resDetailMsgExpired => locale == AppLocale.fr
      ? CopyFr.reservationDetail.msgExpired
      : CopyAr.reservationDetail.msgExpired;

  String get resDetailSectionShow => locale == AppLocale.fr
      ? CopyFr.reservationDetail.sectionShow
      : CopyAr.reservationDetail.sectionShow;

  String get resDetailSectionDetails => locale == AppLocale.fr
      ? CopyFr.reservationDetail.sectionDetails
      : CopyAr.reservationDetail.sectionDetails;

  String get resDetailLabelNumber => locale == AppLocale.fr
      ? CopyFr.reservationDetail.labelNumber
      : CopyAr.reservationDetail.labelNumber;

  String get resDetailLabelSeats => locale == AppLocale.fr
      ? CopyFr.reservationDetail.labelSeats
      : CopyAr.reservationDetail.labelSeats;

  String get resDetailLabelCreatedAt => locale == AppLocale.fr
      ? CopyFr.reservationDetail.labelCreatedAt
      : CopyAr.reservationDetail.labelCreatedAt;

  String get resDetailLabelExpiresAt => locale == AppLocale.fr
      ? CopyFr.reservationDetail.labelExpiresAt
      : CopyAr.reservationDetail.labelExpiresAt;

  String get resDetailLabelExpiredAt => locale == AppLocale.fr
      ? CopyFr.reservationDetail.labelExpiredAt
      : CopyAr.reservationDetail.labelExpiredAt;

  String resDetailSeats(int n) => locale == AppLocale.fr
      ? CopyFr.reservationDetail.seats(n)
      : CopyAr.reservationDetail.seats(n);

  String get resDetailAlertRejectionTitle => locale == AppLocale.fr
      ? CopyFr.reservationDetail.alertRejectionTitle
      : CopyAr.reservationDetail.alertRejectionTitle;

  String get resDetailAlertExpiredTitle => locale == AppLocale.fr
      ? CopyFr.reservationDetail.alertExpiredTitle
      : CopyAr.reservationDetail.alertExpiredTitle;

  String get resDetailAlertExpiredBody => locale == AppLocale.fr
      ? CopyFr.reservationDetail.alertExpiredBody
      : CopyAr.reservationDetail.alertExpiredBody;

  String get resDetailAlertCheckedInTitle => locale == AppLocale.fr
      ? CopyFr.reservationDetail.alertCheckedInTitle
      : CopyAr.reservationDetail.alertCheckedInTitle;

  String get resDetailAlertCheckedInBody => locale == AppLocale.fr
      ? CopyFr.reservationDetail.alertCheckedInBody
      : CopyAr.reservationDetail.alertCheckedInBody;

  String get resDetailBtnViewTicket => locale == AppLocale.fr
      ? CopyFr.reservationDetail.btnViewTicket
      : CopyAr.reservationDetail.btnViewTicket;

  String get resDetailBtnViewUsedTicket => locale == AppLocale.fr
      ? CopyFr.reservationDetail.btnViewUsedTicket
      : CopyAr.reservationDetail.btnViewUsedTicket;

  String get resDetailBtnDiscoverShows => locale == AppLocale.fr
      ? CopyFr.reservationDetail.btnDiscoverShows
      : CopyAr.reservationDetail.btnDiscoverShows;

  String get resDetailBtnCancel => locale == AppLocale.fr
      ? CopyFr.reservationDetail.btnCancelReservation
      : CopyAr.reservationDetail.btnCancelReservation;

  String get resDetailCancelDialogTitle => locale == AppLocale.fr
      ? CopyFr.reservationDetail.cancelDialogTitle
      : CopyAr.reservationDetail.cancelDialogTitle;

  String get resDetailCancelDialogBody => locale == AppLocale.fr
      ? CopyFr.reservationDetail.cancelDialogBody
      : CopyAr.reservationDetail.cancelDialogBody;

  String get resDetailCancelDialogBack => locale == AppLocale.fr
      ? CopyFr.reservationDetail.cancelDialogBack
      : CopyAr.reservationDetail.cancelDialogBack;

  String get resDetailCancelDialogConfirm => locale == AppLocale.fr
      ? CopyFr.reservationDetail.cancelDialogConfirm
      : CopyAr.reservationDetail.cancelDialogConfirm;

  String get resDetailCancelSuccess => locale == AppLocale.fr
      ? CopyFr.reservationDetail.cancelSuccess
      : CopyAr.reservationDetail.cancelSuccess;

  String get resDetailCopied => locale == AppLocale.fr
      ? CopyFr.reservationDetail.copiedLabel
      : CopyAr.reservationDetail.copiedLabel;

  String get resDetailRetry => locale == AppLocale.fr
      ? CopyFr.reservationDetail.retry
      : CopyAr.reservationDetail.retry;

  // ============================================
  // Support Tickets
  // ============================================
  String get supportListTitle => locale == AppLocale.fr
      ? CopyFr.support.listTitle : CopyAr.support.listTitle;
  String get supportCreateTitle => locale == AppLocale.fr
      ? CopyFr.support.createTitle : CopyAr.support.createTitle;
  String get supportNewButton => locale == AppLocale.fr
      ? CopyFr.support.newButton : CopyAr.support.newButton;

  String get supportStatusOpen => locale == AppLocale.fr
      ? CopyFr.support.statusOpen : CopyAr.support.statusOpen;
  String get supportStatusInProgress => locale == AppLocale.fr
      ? CopyFr.support.statusInProgress : CopyAr.support.statusInProgress;
  String get supportStatusClosed => locale == AppLocale.fr
      ? CopyFr.support.statusClosed : CopyAr.support.statusClosed;

  String get supportBannerOpenTitle => locale == AppLocale.fr
      ? CopyFr.support.bannerOpenTitle : CopyAr.support.bannerOpenTitle;
  String get supportBannerOpenMsg => locale == AppLocale.fr
      ? CopyFr.support.bannerOpenMsg : CopyAr.support.bannerOpenMsg;
  String get supportBannerInProgressTitle => locale == AppLocale.fr
      ? CopyFr.support.bannerInProgressTitle : CopyAr.support.bannerInProgressTitle;
  String get supportBannerInProgressMsg => locale == AppLocale.fr
      ? CopyFr.support.bannerInProgressMsg : CopyAr.support.bannerInProgressMsg;
  String get supportBannerClosedTitle => locale == AppLocale.fr
      ? CopyFr.support.bannerClosedTitle : CopyAr.support.bannerClosedTitle;
  String get supportBannerClosedMsg => locale == AppLocale.fr
      ? CopyFr.support.bannerClosedMsg : CopyAr.support.bannerClosedMsg;

  String get supportCardSubtitle => locale == AppLocale.fr
      ? CopyFr.support.cardSubtitle : CopyAr.support.cardSubtitle;

  String get supportEmptyTitle => locale == AppLocale.fr
      ? CopyFr.support.emptyTitle : CopyAr.support.emptyTitle;
  String get supportEmptySubtitle => locale == AppLocale.fr
      ? CopyFr.support.emptySubtitle : CopyAr.support.emptySubtitle;
  String get supportEmptyButton => locale == AppLocale.fr
      ? CopyFr.support.emptyButton : CopyAr.support.emptyButton;
  String get supportErrorMsg => locale == AppLocale.fr
      ? CopyFr.support.errorMsg : CopyAr.support.errorMsg;
  String get supportRetryButton => locale == AppLocale.fr
      ? CopyFr.support.retryButton : CopyAr.support.retryButton;

  String get supportInfoBannerTitle => locale == AppLocale.fr
      ? CopyFr.support.infoBannerTitle : CopyAr.support.infoBannerTitle;
  String get supportInfoBannerBody => locale == AppLocale.fr
      ? CopyFr.support.infoBannerBody : CopyAr.support.infoBannerBody;
  String get supportSubjectLabel => locale == AppLocale.fr
      ? CopyFr.support.subjectLabel : CopyAr.support.subjectLabel;
  String get supportSubjectHint => locale == AppLocale.fr
      ? CopyFr.support.subjectHint : CopyAr.support.subjectHint;
  String get supportSubjectRequired => locale == AppLocale.fr
      ? CopyFr.support.subjectRequired : CopyAr.support.subjectRequired;
  String get supportMessageLabel => locale == AppLocale.fr
      ? CopyFr.support.messageLabel : CopyAr.support.messageLabel;
  String get supportMessageHint => locale == AppLocale.fr
      ? CopyFr.support.messageHint : CopyAr.support.messageHint;
  String get supportSubmitButton => locale == AppLocale.fr
      ? CopyFr.support.submitButton : CopyAr.support.submitButton;

  String get supportConfirmationTitle => locale == AppLocale.fr
      ? CopyFr.support.confirmationTitle : CopyAr.support.confirmationTitle;
  String get supportConfirmationBadge => locale == AppLocale.fr
      ? CopyFr.support.confirmationBadge : CopyAr.support.confirmationBadge;
  String get supportSummarySubject => locale == AppLocale.fr
      ? CopyFr.support.summarySubject : CopyAr.support.summarySubject;
  String get supportSummaryTicket => locale == AppLocale.fr
      ? CopyFr.support.summaryTicket : CopyAr.support.summaryTicket;
  String get supportSummarySubmitted => locale == AppLocale.fr
      ? CopyFr.support.summarySubmitted : CopyAr.support.summarySubmitted;
  String get supportStepsTitle => locale == AppLocale.fr
      ? CopyFr.support.stepsTitle : CopyAr.support.stepsTitle;
  String get supportStep1 => locale == AppLocale.fr
      ? CopyFr.support.step1 : CopyAr.support.step1;
  String get supportStep2 => locale == AppLocale.fr
      ? CopyFr.support.step2 : CopyAr.support.step2;
  String get supportStep3 => locale == AppLocale.fr
      ? CopyFr.support.step3 : CopyAr.support.step3;
  String get supportBtnViewTickets => locale == AppLocale.fr
      ? CopyFr.support.btnViewTickets : CopyAr.support.btnViewTickets;
  String get supportBtnBackHome => locale == AppLocale.fr
      ? CopyFr.support.btnBackHome : CopyAr.support.btnBackHome;

  String get supportDetailSubjectSection => locale == AppLocale.fr
      ? CopyFr.support.detailSubjectSection : CopyAr.support.detailSubjectSection;
  String get supportDetailMessageSection => locale == AppLocale.fr
      ? CopyFr.support.detailMessageSection : CopyAr.support.detailMessageSection;
  String get supportDetailMetaSection => locale == AppLocale.fr
      ? CopyFr.support.detailMetaSection : CopyAr.support.detailMetaSection;
  String get supportMetaTicketNumber => locale == AppLocale.fr
      ? CopyFr.support.metaTicketNumber : CopyAr.support.metaTicketNumber;
  String get supportMetaSubmittedAt => locale == AppLocale.fr
      ? CopyFr.support.metaSubmittedAt : CopyAr.support.metaSubmittedAt;
  String get supportMetaUpdatedAt => locale == AppLocale.fr
      ? CopyFr.support.metaUpdatedAt : CopyAr.support.metaUpdatedAt;
  String get supportInfoCallPending => locale == AppLocale.fr
      ? CopyFr.support.infoCallPending : CopyAr.support.infoCallPending;
  String get supportInfoClosed => locale == AppLocale.fr
      ? CopyFr.support.infoClosed : CopyAr.support.infoClosed;
  String get supportDetailError => locale == AppLocale.fr
      ? CopyFr.support.detailError : CopyAr.support.detailError;
  String get supportDetailForbidden => locale == AppLocale.fr
      ? CopyFr.support.detailForbidden : CopyAr.support.detailForbidden;
  String get supportDetailRetry => locale == AppLocale.fr
      ? CopyFr.support.detailRetry : CopyAr.support.detailRetry;

  String get supportProfileTitle => locale == AppLocale.fr
      ? CopyFr.support.profileTitle : CopyAr.support.profileTitle;
  String get supportProfileSubtitle => locale == AppLocale.fr
      ? CopyFr.support.profileSubtitle : CopyAr.support.profileSubtitle;

  // ── App gate: update prompt + biometric lock ──
  String get updateTitle => locale == AppLocale.fr
      ? CopyFr.appGate.updateTitle : CopyAr.appGate.updateTitle;
  String get updateMessage => locale == AppLocale.fr
      ? CopyFr.appGate.updateMessage : CopyAr.appGate.updateMessage;
  String get updateForcedTitle => locale == AppLocale.fr
      ? CopyFr.appGate.updateForcedTitle : CopyAr.appGate.updateForcedTitle;
  String get updateForcedMessage => locale == AppLocale.fr
      ? CopyFr.appGate.updateForcedMessage : CopyAr.appGate.updateForcedMessage;
  String get updateNow => locale == AppLocale.fr
      ? CopyFr.appGate.updateNow : CopyAr.appGate.updateNow;
  String get updateLater => locale == AppLocale.fr
      ? CopyFr.appGate.updateLater : CopyAr.appGate.updateLater;

  String get biometricLockLabel => locale == AppLocale.fr
      ? CopyFr.appGate.biometricLockLabel : CopyAr.appGate.biometricLockLabel;
  String get biometricLockSubtitle => locale == AppLocale.fr
      ? CopyFr.appGate.biometricLockSubtitle
      : CopyAr.appGate.biometricLockSubtitle;
  String get biometricUnlockTitle => locale == AppLocale.fr
      ? CopyFr.appGate.biometricUnlockTitle
      : CopyAr.appGate.biometricUnlockTitle;
  String get biometricUnlockSubtitle => locale == AppLocale.fr
      ? CopyFr.appGate.biometricUnlockSubtitle
      : CopyAr.appGate.biometricUnlockSubtitle;
  String get biometricUnlockButton => locale == AppLocale.fr
      ? CopyFr.appGate.biometricUnlockButton
      : CopyAr.appGate.biometricUnlockButton;
  String get biometricReason => locale == AppLocale.fr
      ? CopyFr.appGate.biometricReason : CopyAr.appGate.biometricReason;
  String get biometricUnavailable => locale == AppLocale.fr
      ? CopyFr.appGate.biometricUnavailable
      : CopyAr.appGate.biometricUnavailable;
  String get biometricEnableFailed => locale == AppLocale.fr
      ? CopyFr.appGate.biometricEnableFailed
      : CopyAr.appGate.biometricEnableFailed;
}
