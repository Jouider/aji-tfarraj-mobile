import 'package:aji_tfarraj/app/copywriting/copy_fr.dart'
    show ConditionSection, HowToStep, ChargePublicCopy;

/// Arabic copywriting for Aji Tfarraj app
/// Starter pack - not final marketing copy
class CopyAr {
  CopyAr._();

  // ============================================
  // Buttons
  // ============================================
  static const buttons = ButtonsCopyAr();

  // ============================================
  // Reservation Statuses
  // ============================================
  static const statuses = StatusesCopyAr();

  // ============================================
  // Error Messages
  // ============================================
  static const errors = ErrorsCopyAr();

  // ============================================
  // Rules Page
  // ============================================
  static const rules = RulesCopyAr();

  // ============================================
  // Loyalty / الولاء
  // ============================================
  static const loyalty = LoyaltyCopyAr();

  // ============================================
  // Auth (login / register)
  // ============================================
  static const auth = AuthCopyAr();

  // ============================================
  // Common UI
  // ============================================
  static const common = CommonCopyAr();

  // ============================================
  // Profile screen
  // ============================================
  static const profile = ProfileCopyAr();

  // ============================================
  // My Reservations screen
  // ============================================
  static const myReservations = MyReservationsCopyAr();

  // ============================================
  // Home screen
  // ============================================
  static const home = HomeCopyAr();

  // ============================================
  // Show Detail screen
  // ============================================
  static const showDetail = ShowDetailCopyAr();

  // ============================================
  // Reserve Seats screen
  // ============================================
  static const reserveSeats = ReserveSeatsCopyAr();

  // ============================================
  // Ticket screen
  // ============================================
  static const ticket = TicketCopyAr();

  // ============================================
  // Browse screen
  // ============================================
  static const browse = BrowseCopyAr();

  // ============================================
  // Notifications screen
  // ============================================
  static const notifications = NotificationsCopyAr();

  // ============================================
  // Bottom Nav Tabs
  // ============================================
  static const navTabs = NavTabsCopyAr();

  // ============================================
  // Staff Check-in
  // ============================================
  static const staff = StaffCopyAr();

  // ============================================
  // Conditions de participation
  // ============================================
  static const conditions = ConditionsCopyAr();

  // ============================================
  // Rewards
  // ============================================
  static const rewards = RewardsCopyAr();

  // ============================================
  // Referral / الإحالة
  // ============================================
  static const referral = ReferralCopyAr();

  // ============================================
  // How it works / كيفاش كيخدم
  // ============================================
  static const howItWorks = HowItWorksCopyAr();

  // ============================================
  // Charge public ("Mode Chargé Public")
  // ============================================
  static const chargePublic = ChargePublicCopyAr();

  // ============================================
  // Episodes / الحلقات
  // ============================================
  static const episode = EpisodeCopyAr();

  // ============================================
  // Reservation Result / تأكيد الحجز
  // ============================================
  static const reservationResult = ReservationResultCopyAr();

  // ============================================
  // Reservation Detail / تفاصيل الحجز
  // ============================================
  static const reservationDetail = ReservationDetailCopyAr();

  // ============================================
  // Support Tickets / تذاكر الدعم
  // ============================================
  static const support = SupportCopyAr();

  // ============================================
  // App gate (update prompt + biometric lock)
  // ============================================
  static const appGate = AppGateCopyAr();
}

/// Update-prompt + biometric-lock copy in Arabic
class AppGateCopyAr {
  const AppGateCopyAr();

  // Update prompt
  String get updateTitle => 'تحديث متاح';
  String get updateMessage =>
      'تتوفر نسخة جديدة من «أجي تفرّج». قم بالتحديث للاستفادة من آخر التحسينات.';
  String get updateForcedTitle => 'التحديث مطلوب';
  String get updateForcedMessage =>
      'هذه النسخة لم تعد مدعومة. يرجى التحديث لمواصلة استخدام التطبيق.';
  String get updateNow => 'تحديث الآن';
  String get updateLater => 'لاحقًا';

  // Biometric lock
  String get biometricLockLabel => 'القفل البيومتري';
  String get biometricLockSubtitle => 'Face ID / البصمة عند الفتح';
  String get biometricUnlockTitle => 'التطبيق مقفل';
  String get biometricUnlockSubtitle =>
      'تحقّق من هويتك للوصول إلى تذاكرك وملفك الشخصي.';
  String get biometricUnlockButton => 'إلغاء القفل';
  String get biometricReason => 'أكّد هويتك لفتح «أجي تفرّج»';
  String get biometricUnavailable =>
      'لا توجد طريقة بيومترية مُعدّة على هذا الجهاز.';
  String get biometricEnableFailed => 'تعذّر تفعيل القفل. حاول مرة أخرى.';
}

/// Rewards screen copy in Arabic
class RewardsCopyAr {
  const RewardsCopyAr();

  String get rewardsTitle => 'المكافآت';
  String get myRewardsTitle => 'طلباتي';
  String get collectReward => 'احصل عليها';
  String get rewardRequestSent => 'تم إرسال الطلب. في انتظار الموافقة.';
  String get pendingLabel => 'قيد الانتظار';
  String get approvedLabel => 'مقبول';
  String get rejectedLabel => 'مرفوض';
  String get insufficientPoints => 'ليس لديك نقاط كافية.';
  String get duplicatePending => 'لقد طلبت هذه المكافأة بالفعل.';
  String get rewardInactive => 'هذه المكافأة غير متاحة حاليًا.';
  String get noRewardsYet => 'لا توجد مكافآت متاحة.';
  String get noMyRewardsYet => 'لا توجد طلبات حتى الآن.';
  String get pointsRequired => 'نقطة مطلوبة';
  String get seeAllRewards => 'عرض كل المكافآت';
  String get requestedAt => 'تم الطلب في';
}

/// Button labels in Arabic
class ButtonsCopyAr {
  const ButtonsCopyAr();

  String get login => 'تسجيل الدخول';
  String get register => 'إنشاء حساب';
  String get reserve => 'حجز';
  String get confirm => 'تأكيد';
  String get cancel => 'إلغاء';
  String get logout => 'تسجيل الخروج';
  String get viewTicket => 'عرض التذكرة';
}

/// Reservation status labels in Arabic
class StatusesCopyAr {
  const StatusesCopyAr();

  String get pendingReview => 'في انتظار المراجعة';
  String get contacting => 'جاري التواصل';
  String get approved => 'تم تأكيد الحجز';
  String get rejected => 'تم رفض الحجز';
  String get cancelled => 'تم إلغاء الحجز';
  String get expired => 'انتهت صلاحية الحجز';
  String get checkedIn => 'تم تسجيل الدخول';

  /// Get status label by key
  String byKey(String key) {
    switch (key) {
      case 'pending_review':
        return pendingReview;
      case 'contacting':
        return contacting;
      case 'approved':
        return approved;
      case 'rejected':
        return rejected;
      case 'cancelled':
        return cancelled;
      case 'expired':
        return expired;
      case 'checked_in':
        return checkedIn;
      default:
        return key;
    }
  }
}

/// Error messages in Arabic
class ErrorsCopyAr {
  const ErrorsCopyAr();

  String get networkError =>
      'تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت.';
  String get unauthorized => 'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.';
  String get soldOut => 'هذا العرض مكتمل. لا توجد أماكن متاحة.';
  String get unknownError => 'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  String get emailAlreadyExists => 'يوجد حساب مسجل بهذا البريد الإلكتروني.';
  String get validationError => 'يرجى التحقق من المعلومات المدخلة.';
  String get errorTitle => 'حدث خطأ';
}

/// Rules page content in Arabic
class RulesCopyAr {
  const RulesCopyAr();

  String get title => 'قواعد العرض';
  String get introduction => 'بحجزك لمكان، فإنك توافق على الشروط التالية:';

  List<RuleItemAr> get items => const [
        RuleItemAr(
          title: 'شرط السن',
          description: 'الدخول مخصص للأشخاص الذين تبلغ أعمارهم 18 سنة فما فوق.',
        ),
        RuleItemAr(
          title: 'التحقق من الهوية',
          description:
              'يرجى تقديم بطاقة هوية خاصة بك مع إرفاق صورة من البطاقة الشخصية.',
        ),
        RuleItemAr(
          title: 'اللباس المناسب',
          description:
              'يُرفض دخول أي شخص يرتدي ملابس غير مناسبة أو فيها أي علامات تجارية أو إشهارية.',
        ),
        RuleItemAr(
          title: 'منع التصوير',
          description:
              'يُمنع منعاً باتاً التصوير الفوتوغرافي والفيديو أثناء العرض.',
        ),
        RuleItemAr(
          title: 'احترام التعليمات',
          description: 'يرجى الالتزام بتعليمات الموظفين وأعوان الأمن.',
        ),
      ];

  String get acceptance => 'لقد قرأت وأوافق على قواعد العرض.';
}

/// Rule item model for Arabic
class RuleItemAr {
  final String title;
  final String description;

  const RuleItemAr({
    required this.title,
    required this.description,
  });
}

/// Auth (login / register) copy in Arabic
class AuthCopyAr {
  const AuthCopyAr();

  // Login
  String get loginSubtitle => 'سجّل دخولك للحجز';
  String get noAccount => 'ليس لديك حساب؟';
  String get registerLink => 'إنشاء حساب';

  // Register
  String get registerTitle => 'إنشاء حساب';
  String get registerSubtitle => 'سجّل للحجز في عروضك المفضلة';
  String get alreadyAccount => 'لديك حساب بالفعل؟';
  String get loginLink => 'تسجيل الدخول';

  // Form fields
  String get emailLabel => 'البريد الإلكتروني';
  String get emailHint => 'بريدك@مثال.com';
  String get passwordLabel => 'كلمة المرور';
  String get nameLabel => 'الاسم الكامل';
  String get nameHint => 'أحمد بنجلون';
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  // Validation
  String get emailRequired => 'يرجى إدخال بريدك الإلكتروني';
  String get emailInvalid => 'يرجى إدخال بريد إلكتروني صالح';
  String get passwordRequired => 'يرجى إدخال كلمة المرور';
  String get passwordMin => 'كلمة المرور يجب أن تحتوي على 8 أحرف على الأقل';
  String get passwordWeak =>
      'يجب أن تحتوي كلمة المرور على حرف كبير وحرف صغير ورقم على الأقل.';
  String get nameRequired => 'يرجى إدخال اسمك';
  String get nameMin => 'الاسم يجب أن يحتوي على حرفين على الأقل';
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  // Auth landing
  String get authLandingTitle => 'مرحباً';
  String get authLandingSubtitle => 'احجز مقاعدك للبرامج التلفزيونية المغربية';
  String get continueWithGoogle => 'المتابعة مع Google';
  String get continueWithApple => 'المتابعة مع Apple';
  String get continueWithEmail => 'تسجيل الدخول بالبريد الإلكتروني';
  String get createAccount => 'إنشاء حساب';
  String get orDivider => 'أو';
  String get termsNotice => 'بالمتابعة، أنت توافق على شروط الاستخدام';

  // Forgot password
  String get forgotPassword => 'نسيت كلمة المرور؟';
  String get forgotPasswordTitle => 'نسيت كلمة المرور';
  String get forgotPasswordSubtitle =>
      'أدخل بريدك الإلكتروني لتلقي رابط إعادة التعيين';
  String get forgotPasswordButton => 'إرسال الرابط';
  String get forgotPasswordSuccess => 'تم الإرسال!';
  String get forgotPasswordSuccessMessage =>
      'تحقق من بريدك الإلكتروني واتبع التعليمات لإعادة تعيين كلمة المرور.';
  String get backToLogin => 'العودة لتسجيل الدخول';
}

/// Common UI copy in Arabic
class CommonCopyAr {
  const CommonCopyAr();

  String get retry => 'إعادة المحاولة';
  String get seeAll => 'عرض الكل';
  String get loading => 'جاري التحميل...';
  String get unknownUser => 'مستخدم';
  String get place => 'مقعد';
  String get places => 'مقاعد';
  String get back => 'رجوع';
  String get backToHome => 'العودة إلى الرئيسية';
  String get browseShows => 'استعراض البرامج الأخرى';
  String get reservationSuccessBody =>
      'طلبك قيد المعالجة. سيتم الاتصال بك لتأكيد مشاركتك.';
}

/// Profile screen copy in Arabic
class ProfileCopyAr {
  const ProfileCopyAr();

  String get title => 'ملفي الشخصي';
  String get languageLabel => 'اللغة';
  String get languageValueFr => 'Français';
  String get languageValueAr => 'العربية';
  String get themeLabel => 'المظهر';
  String get themeSystem => 'النظام';
  String get themeLight => 'فاتح';
  String get themeDark => 'داكن';
  String get loyaltyLabel => 'الوفاء';
  String get notificationsLabel => 'الإشعارات';
  String unreadCount(int n) => '$n غير مقروء${n > 1 ? 'ة' : ''}';
  String get groupPreferences => 'التفضيلات';
  String get groupAccount => 'الحساب';
  String get groupSettings => 'الإعدادات';
  String get helpLabel => 'المساعدة';
  String get aboutLabel => 'حول التطبيق';
  String get logoutLabel => 'تسجيل الخروج';

  // Edit profile
  String get editTitle => 'تعديل الملف الشخصي';
  String get editSectionPersonal => 'المعلومات الشخصية';
  String get editSectionLocation => 'الموقع';
  String get editSectionContact => 'التواصل';
  String get incompleteWarning => 'أكمل ملفك الشخصي لتتمكن من الحجز';
  String get incompleteMessage =>
      'يرجى إدخال اسمك الأول والأخير والمدينة والحي، والتحقق من رقم هاتفك قبل الحجز.';
  String get completeProfileButton => 'إكمال الملف الشخصي';
  String get firstNameLabel => 'الاسم الأول';
  String get lastNameLabel => 'الاسم الأخير';
  String get cityLabel => 'المدينة';
  String get districtLabel => 'الحي';
  String get firstNameRequired => 'يرجى إدخال اسمك الأول';
  String get lastNameRequired => 'يرجى إدخال اسمك الأخير';
  String get cityRequired => 'يرجى اختيار مدينتك';
  String get districtRequired => 'يرجى اختيار حيّك';
  String get saveChanges => 'حفظ';
  String get savedSuccess => 'تم تحديث الملف الشخصي';
  String get uploadPhoto => 'تغيير الصورة';
  String get takePhoto => 'التقاط صورة';
  String get chooseFromGallery => 'اختيار من المعرض';
  String get removePhoto => 'حذف الصورة';
  String get avatarDeletedSuccess => 'تم حذف صورة الملف الشخصي';
  String get addPhotoHint => 'اضغط لإضافة صورة (اختياري)';
  String get skipForNow => 'تخطى الآن';
  String get cameraAccessDenied =>
      'تم رفض الوصول إلى الكاميرا. يرجى السماح بالوصول في الإعدادات.';
  String get permissionNeededTitle => 'إذن مطلوب';
  String get cameraPermissionMessage =>
      'لالتقاط صورة ملفك الشخصي، يرجى السماح بالوصول إلى الكاميرا في الإعدادات.';
  String get openSettings => 'فتح الإعدادات';
  String get profileStillIncomplete =>
      'لا تزال بعض المعلومات المطلوبة ناقصة. يرجى التحقق من النموذج قبل المتابعة.';

  // Phone section
  String get phoneLabel => 'رقم الهاتف';
  String get phoneNumberHint => '6XXXXXXXX';
  String get phoneVerified => 'رقم موثّق';
  String get phoneNotVerified => 'رقم غير موثّق';
  String get phoneNumberInvalid => 'يرجى إدخال رقم صالح.';
  String get verifyPhoneButton => 'توثيق الرقم';
  String get phoneAlreadyUsed => 'هذا الرقم مستخدم بالفعل من قبل حساب آخر.';

  // Date of birth
  String get dateOfBirthLabel => 'تاريخ الميلاد';
  String get dateOfBirthRequired => 'يرجى إدخال تاريخ ميلادك';

  // Gender
  String get genderLabel => 'الجنس';
  String get genderMale => 'ذكر';
  String get genderFemale => 'أنثى';
  String get genderRequired => 'يرجى اختيار الجنس';

  // Avatar
  String get avatarRequiredHint => 'الصورة مطلوبة لإكمال الملف الشخصي';

  // OTP screen
  String get otpScreenTitle => 'التحقق من الرقم';
  String otpScreenSubtitle(String maskedPhone) =>
      'أرسلنا رمزاً إلى $maskedPhone';
  String get otpCodeHint => 'رمز مكون من 6 أرقام';
  String get otpCodeRequired => 'يرجى إدخال الرمز المكون من 6 أرقام.';
  String get otpVerifyButton => 'تحقق';
  String get otpResendButton => 'إعادة إرسال الرمز';
  String otpResendCountdown(int s) => 'إعادة الإرسال خلال $s ث';
  String get otpSentSuccess => 'تم إرسال الرمز عبر الرسائل القصيرة.';
  String get otpVerifiedSuccess => 'تم توثيق الرقم بنجاح.';
  String get otpInvalidCode => 'الرمز غير صالح أو منتهي الصلاحية.';
  String get otpSendFailed => 'تعذر إرسال الرمز في الوقت الحالي.';
  String get otpVerifyFailed => 'تعذر التحقق من الرمز في الوقت الحالي.';
}

/// My Reservations screen copy in Arabic
class MyReservationsCopyAr {
  const MyReservationsCopyAr();

  String get title => 'حجوزاتي';

  // Tabs
  String get tabPending => 'قيد الانتظار';
  String get tabApproved => 'المُوافَق عليها';
  String get tabPast => 'السابقة';

  // Empty states
  String get emptyPending => 'لا توجد حجوزات قيد الانتظار';
  String get emptyPendingSubtitle => 'ستظهر طلباتك الحالية هنا';
  String get emptyApproved => 'لا توجد حجوزات مُوافَق عليها';
  String get emptyApprovedSubtitle => 'ستظهر حجوزاتك المؤكدة هنا';
  String get emptyPast => 'لا توجد حجوزات سابقة';
  String get emptyPastSubtitle => 'سيظهر سجل حجوزاتك هنا';

  // Cancel dialog
  String get cancelDialogTitle => 'إلغاء الحجز';
  String get cancelDialogContent =>
      'هل أنت متأكد من رغبتك في إلغاء هذا الحجز؟ لا يمكن التراجع عن هذا الإجراء.';
  String get cancelDialogKeep => 'لا، إبقاء';
  String get cancelDialogConfirm => 'نعم، إلغاء';

  // Snackbars
  String get cancelSuccess => 'تم إلغاء الحجز';
  String get cancelErrorForbidden => 'لا يمكنك إلغاء هذا الحجز.';
  String get cancelErrorConflict => 'لم يعد بالإمكان إلغاء هذا الحجز.';
  String get cancelErrorGeneric => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  // Card banners
  String get expiredBanner => 'انتهت صلاحية الحجز';
  String get checkedInBanner => 'تم تسجيل الدخول — التذكرة مستخدمة';

  // Misc
  String get retryLabel => 'إعادة المحاولة';
  String seatCount(int n) => '$n ${n == 1 ? 'مقعد' : 'مقاعد'}';
}

/// Home screen copy in Arabic
class HomeCopyAr {
  const HomeCopyAr();

  String get sectionUpcoming => 'العروض القادمة';
  String get sectionComingSoon => 'قريبًا';
  String get sectionPopular => 'الأكثر طلبًا';
  String get soldOut => 'مكتمل';
  String get comingSoonBadge => 'قريبًا';
  String get soldOutBadge => 'مكتمل';
  String get dateTbc => 'التاريخ قيد التأكيد';
  String get notificationsTooltip => 'الإشعارات';
}

/// Show Detail screen copy in Arabic
class ShowDetailCopyAr {
  const ShowDetailCopyAr();

  String get soldOut => 'مكتمل';
  String availableSeats(int n) => '$n ${n == 1 ? 'مقعد متاح' : 'مقاعد متاحة'}';
  String reservations(int reserved, int cap) => '$reserved حجز من أصل $cap';
  String get about => 'حول البرنامج';
  String get seeLess => 'عرض أقل';
  String get seeMore => 'عرض المزيد';
  String get dateLabel => 'التاريخ';
  String get timeLabel => 'الوقت';
  String get locationLabel => 'المكان';
  String get channelLabel => 'القناة';
  String get loyaltyPointsLabel => 'نقاط الولاء';
  String loyaltyPointsValue(int pts) => '+$pts نقطة عند الحضور';
  String get rulesTitle => 'قواعد المشاركة';
  String get reserveNow => 'احجز الآن';
  String get soldOutCta => 'مكتمل';
}

/// Reserve Seats screen copy in Arabic
class ReserveSeatsCopyAr {
  const ReserveSeatsCopyAr();

  String get title => 'حجز مقاعد';
  String get soldOutBadge => 'مكتمل — لا مقاعد متاحة';
  String availableSeats(int n) => '$n ${n == 1 ? 'مقعد متاح' : 'مقاعد متاحة'}';
  String get seatsCountLabel => 'عدد المقاعد';
  String maxHint(int n) => 'بحد أقصى 4 مقاعد · $n متاح';
  String get infoTitle => 'معلومة مهمة';
  String get infoBody =>
      'سيتم مراجعة طلبك من قِبل فريقنا. ستتلقى إشعارًا بالتأكيد بمجرد الموافقة.';
  String get recap => 'ملخص';
  String get confirm => 'تأكيد الحجز';
  String get soldOutCta => 'مكتمل';
  String get errSoldOut => 'المقاعد ممتلئة. لا توجد مقاعد كافية.';
  String get errNotEnough => 'لا توجد مقاعد كافية.';
  String get agreementCheckboxLabel => 'لقد قرأت وأوافق على شروط المشاركة.';
  String get agreementReadRules => 'قراءة النظام الداخلي';
}

/// Ticket screen copy in Arabic
class TicketCopyAr {
  const TicketCopyAr();

  String get title => 'بطاقاتي';
  String get loading => 'جاري تحميل بطاقاتك...';
  String get pendingTitle => 'في انتظار التأكيد';
  String get pendingDesc =>
      'ستتوفر بطاقاتك هنا بعد الموافقة على حجوزاتك من قِبل فريقنا.';
  String get showTickets => 'عرض بطاقاتي';
  String get viewReservations => 'عرض حجوزاتي';
  String get rulesReminder => 'تذكير بالقواعد';
  String get refresh => 'تحديث';
  String get offlineBanner => 'وضع عدم الاتصال — آخر نسخة من البطاقات';
  String get countSingle => 'بطاقة 1 معتمدة';
  String countMultiple(int idx, int total) =>
      '${idx + 1} / $total بطاقات معتمدة';
  String get swipeHint => 'اسحب لرؤية بطاقاتك الأخرى';
  String get ticketUsed => 'بطاقة مستخدمة';
  String get ticketValid => 'بطاقة صالحة';
  String get checkedInLabel => 'تم التحقق من الدخول';
  String get usedLabel => 'مُستخدَم';
  String seats(int n) => '$n ${n == 1 ? 'مقعد' : 'مقاعد'}';
  String get qrHintValid => 'أظهر رمز QR هذا عند الدخول';
  String get qrHintUsed => 'تم استخدام هذه البطاقة مسبقًا';
  String codeCopied(String code) => 'تم نسخ الرمز: $code';
  String checkinAt(String date) => 'تسجيل الدخول بتاريخ $date';
}

/// Browse screen copy in Arabic
class BrowseCopyAr {
  const BrowseCopyAr();

  String get title => 'استكشاف';
  String get filterTooltip => 'تصفية';
  String get noResults => 'لا نتائج';
  String get noResultsDesc => 'لا توجد عروض تطابق بحثك.';
  String get clearFilters => 'مسح الفلاتر';
  String get searchHint => 'ابحث عن عرض...';
  String get allCities => 'الكل';
  String get filterByChannel => 'تصفية حسب القناة';
  String get noChannels => 'لا توجد قنوات';
  String get clearAllFilters => 'مسح كل الفلاتر';
  String get soldOutBadge => 'مكتمل';
  String availableSeats(int n) => '$n ${n == 1 ? 'مقعد' : 'مقاعد'}';
}

/// Notifications screen copy in Arabic
class NotificationsCopyAr {
  const NotificationsCopyAr();

  String get title => 'الإشعارات';
  String get markAllRead => 'تحديد الكل كمقروء';
  String get markAllReadSuccess => 'تم تحديد كل الإشعارات كمقروءة';
  String get deleteAll => 'حذف الكل';
  String get deleteAllTitle => 'حذف كل الإشعارات';
  String get deleteAllContent =>
      'هل أنت متأكد من حذف كل الإشعارات؟ لا يمكن التراجع عن هذا الإجراء.';
  String get deleteAllConfirm => 'حذف';
  String get deleteAllSuccess => 'تم حذف كل الإشعارات';
  String get dismissed => 'تم حذف الإشعار';
  String get emptyTitle => 'لا إشعارات';
  String get emptyDesc => 'لم تتلق أي إشعار بعد.';
}

/// Loyalty copy in Arabic
class LoyaltyCopyAr {
  const LoyaltyCopyAr();

  String get loyaltyTitle => 'الولاء';
  String get pointsTotal => 'النقاط';
  String get pointsSubtitle => 'اكسب نقاطًا بعد كل تسجيل حضور';
  String get history => 'السجل';
  String get rewards => 'المكافآت';
  String get comingSoon => 'قريبًا';
  String get noPointsYet => 'لا توجد نقاط حتى الآن';
  String get attendanceLabel => 'الحضور';
}

/// Bottom nav tab labels in Arabic
class NavTabsCopyAr {
  const NavTabsCopyAr();

  String get emissions => 'البرامج';
  String get explorer => 'استكشاف';
  String get reservations => 'حجوزاتي';
  String get ticket => 'بطاقتي';
  String get profile => 'حسابي';
}

/// Staff check-in strings in Arabic
class StaffCopyAr {
  const StaffCopyAr();

  String get checkInTitle => 'تسجيل الدخول - البطاقات';
  String get tabScanQr => 'مسح QR';
  String get tabManualCode => 'الرمز اليدوي';
  String get scanInstruction => 'وجّه الكاميرا نحو رمز QR الخاص بالبطاقة';
  String get manualPlaceholder => 'AT-2026-000008';
  String get validateButton => 'التحقق من البطاقة';
  String get successTitle => 'تم التحقق من البطاقة';
  String get alreadyUsed => 'البطاقة مستخدمة بالفعل';
  String get notFound => 'البطاقة غير موجودة';
  String get accessDenied => 'مطلوب صلاحيات الموظف';
  String get accessDeniedSubtitle => 'ليس لديك الصلاحيات للوصول إلى هذا القسم.';
  String get sessionExpired => 'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.';
  String get networkError => 'تعذّر التحقق من البطاقة في الوقت الحالي.';
  String get scanAnother => 'مسح بطاقة أخرى';
  String get cameraPermissionDenied => 'تم رفض الوصول إلى الكاميرا';
  String get cameraPermissionSubtitle =>
      'السماح بالوصول إلى الكاميرا لمسح رموز QR.';
  String get openSettings => 'فتح الإعدادات';
  String get checkedInAt => 'وقت الدخول';
  String get profileStaffTile => 'تسجيل الدخول - البطاقات';
  String get retry => 'إعادة المحاولة';
  String get back => 'رجوع';
  String get attendeeName => 'المشاهد';
  String get showLabel => 'البرنامج';
  String get ticketCodeLabel => 'رمز البطاقة';
}

/// شروط المشاركة — Arabic
class ConditionsCopyAr {
  const ConditionsCopyAr();

  String get title => 'شروط المشاركة';
  String get subtitle => 'تفويض حق الصورة والنظام الداخلي';
  String get profileTileLabel => 'النظام الداخلي';
  String get validationTitle => 'التوقيع والتصديق الإلكتروني';

  List<String> get checkboxItems => const [
        'أؤكد أن عمري يزيد عن 18 سنة وأوافق على شروط المشاركة.',
        'أفوّض استخدام صورتي وصوتي وحضوري في البرامج والمحتويات السمعية البصرية.',
        'أتعهد باحترام سرية التصوير (اتفاقية عدم الإفصاح).',
        'أقر بأن تصديقي الإلكتروني يُعدّ توقيعاً وقبولاً قانونياً للشروط الواردة.',
      ];

  List<ConditionSection> get sections => const [
        ConditionSection(
          title: 'الحد الأدنى للسن',
          body:
              'تُخصص المشاركة في البرامج والتصوير للأشخاص الذين تتراوح أعمارهم بين 18 و65 سنة.\nيؤكد كل شخص مسجل أنه بالغ (18 سنة على الأقل).',
        ),
        ConditionSection(
          title: 'بطاقة الهوية إلزامية',
          body:
              'يخضع الدخول إلى الاستوديو أو موقع التصوير لتقديم وثيقة هوية سارية المفعول (بطاقة وطنية أو جواز سفر).\nيحق للمنظم رفض الدخول في غياب وثيقة الهوية.',
        ),
        ConditionSection(
          title: 'تفويض حق الصورة',
          body:
              'بمشاركته في التصوير أو الحدث، يفوّض المشارك صراحةً وبدون مقابل للمنظم والمنتجين وقنوات التلفزيون وشركائهم:\n• تصويره والتقاط صوره وتسجيل صورته وصوته وملامحه،\n• استخدام هذه الصور في إطار البرامج والمحتويات السمعية البصرية أو الترويجية.\n\nيمكن بث هذه الصور على جميع الوسائط: التلفزيون، الإنترنت، المنصات الرقمية، الشبكات الاجتماعية والوسائط الترويجية.\nيُمنح هذا التفويض على المستوى العالمي وبدون حد زمني وبدون تعويض مالي.',
        ),
        ConditionSection(
          title: 'السرية (اتفاقية عدم الإفصاح)',
          body:
              'يلتزم المشارك بعدم الكشف عن:\n• مضمون البرنامج\n• مقاطع التصوير\n• الضيوف أو النتائج\n• المعلومات المتعلقة بالإنتاج\n\nقبل البث الرسمي.\n\nيُمنع منعاً باتاً نشر صور أو مقاطع فيديو من التصوير على الشبكات الاجتماعية.',
        ),
        ConditionSection(
          title: 'الهواتف والتسجيلات',
          body:
              'خلال التصوير:\n• يجب إيقاف تشغيل الهواتف أو ضبطها على الوضع الصامت\n• يُمنع التصوير الفوتوغرافي أو بالفيديو أو التسجيل الصوتي.',
        ),
        ConditionSection(
          title: 'السلوك والاحترام',
          body:
              'يجب على المشاركين:\n• احترام فريق الإنتاج\n• اتباع تعليمات مساعدي الاستوديو\n• احترام سائر أفراد الجمهور.\n\nأي سلوك عنيف أو مزعزع للنظام قد يُفضي إلى الطرد الفوري من الاستوديو.',
        ),
        ConditionSection(
          title: 'الشجارات والنزاعات',
          body:
              'لا يتحمل المنظم أي مسؤولية عن الشجارات أو النزاعات بين المشاركين، سواء داخل الاستوديو أو خارج المقر.',
        ),
        ConditionSection(
          title: 'المقتنيات الشخصية',
          body:
              'يتحمل المشاركون مسؤولية مقتنياتهم الشخصية.\nيتبرأ المنظم من كل مسؤولية في حال:\n• الضياع\n• السرقة\n• التلف.',
        ),
        ConditionSection(
          title: 'مواعيد وأوقات التصوير',
          body:
              'المواعيد المُعلنة إرشادية.\nقد تستمر التصوير لوقت أطول مما هو مقرر.\nلا يمكن تحميل المنظم المسؤولية عن تأخر نهاية التصوير.',
        ),
        ConditionSection(
          title: 'الدخول والأمن',
          body:
              'قد يخضع الدخول إلى الاستوديو لفحص أمني.\nيحق للمنظم رفض الدخول أو طرد أي شخص لا يحترم القواعد.',
        ),
        ConditionSection(
          title: 'اللباس',
          body:
              'قد تشترط بعض البرامج نوعاً معيناً من اللباس.\nقد يُرفض الدخول للملابس التي تحمل شعارات أو رسائل غير لائقة.',
        ),
        ConditionSection(
          title: 'حماية البيانات',
          body:
              'تُستخدم المعلومات المجمّعة في التطبيق حصراً من أجل:\n• إدارة تسجيلات الجمهور\n• تنظيم التصوير\n• التواصل المتعلق بالفعاليات.',
        ),
        ConditionSection(
          title: 'حق الإلغاء',
          body:
              'يحق للمنظم تعديل أو إلغاء مشاركة مستخدم لأسباب تنظيمية أو أمنية.',
        ),
        ConditionSection(
          title: 'قبول الشروط',
          body:
              'يستلزم أي تسجيل عبر التطبيق القبول الكامل للنظام الداخلي الحالي.',
        ),
      ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Referral / الإحالة
// ─────────────────────────────────────────────────────────────────────────────
class ReferralCopyAr {
  const ReferralCopyAr();

  String get title => 'الإحالة';
  String get myReferralCode => 'رمز الإحالة الخاص بي';
  String get copyCode => 'نسخ الرمز';
  String get codeCopied => 'تم نسخ الرمز!';
  String get inviteFriend => 'دعوة صديق';
  String get generateLink => 'إنشاء رابط';
  String get shareLink => 'مشاركة الرابط';
  String invitesYou(String name) => '$name يدعوك لحضور هذه الحلقة';
  String get reserveNow => 'احجز الآن';
  String get referralCodeLabel => 'رمز الإحالة (اختياري)';
  String get referralCodeHint => 'أدخل رمز صديقك';
  String get totalInvited => 'المدعوون';
  String get totalAttended => 'الحاضرون';
  String get pending => 'قيد الانتظار';
  String get pointsEarned => 'النقاط المكتسبة';
  String get myLinks => 'روابط الإحالة الخاصة بي';
  String get clicks => 'نقرات';
  String get conversions => 'حجوزات';
  String get expired => 'منتهي الصلاحية';
  String get linkExpired => 'انتهت صلاحية هذا الرابط';
  String get linkInvalid => 'رابط غير صالح';
  String get showUnavailable => 'هذه الحلقة لم تعد متاحة';
  String shareMessage(String showTitle, String link) =>
      'انضم إلي لحضور $showTitle! احجز مكانك هنا: $link';
  String episodeShareMessage(
          String showTitle, String episodeLabel, String dateStr, String link) =>
      'انضم إليّ في «$showTitle» — $episodeLabel ($dateStr)! '
      'احجز مكانك مجانًا هنا: $link';
  String get noLinksYet => 'لا توجد روابط مشتركة';
  String get noReferralsYet => 'لا توجد إحالات حتى الآن';
  String get inviteFriendsEarnPoints => 'ادعُ أصدقاءك واكسب نقاطًا!';
  String get profileTileLabel => 'الإحالة';
  String get statsTitle => 'إحالاتي';
  String get linksTitle => 'روابطي';
}

// ─────────────────────────────────────────────────────────────────────────────
// How it works / كيفاش كتخدم
// ─────────────────────────────────────────────────────────────────────────────
class HowItWorksCopyAr {
  const HowItWorksCopyAr();

  String get title => 'كيفاش كتخدم';

  // Profile entry point
  String get profileTileLabel => 'كيفاش كتخدم';
  String get profileTileSubtitle => 'دليل استعمال التطبيق';

  // Track selector
  String get trackClient => 'للمتفرجين';
  String get trackParrain => 'للمُحيلين';

  // Actions
  String get watchVideo => 'شاهد الفيديو';
  String get gotIt => 'فهمت';
  String get next => 'التالي';
  String stepCounter(int current, int total) => 'خطوة $current / $total';

  // Client track — how to use the app
  String get clientHeadline => 'احجز مكانك في 5 خطوات';
  String get clientSubtitle =>
      'احضر مجانًا تصوير برامجك المفضلة.';
  List<HowToStep> get clientSteps => const [
        HowToStep(
          title: 'استكشف البرامج',
          body: 'تصفّح التصويرات التلفزيونية المتاحة واختر البرنامج اللي عجبك.',
        ),
        HowToStep(
          title: 'اختر مقاعدك',
          body: 'افتح برنامجًا واحجز حتى 4 مقاعد، مجانًا.',
        ),
        HowToStep(
          title: 'انتظر التأكيد',
          body:
              'فريقنا كيتواصل معاك لتأكيد حضورك. كتوصلك إشعارات في كل مرحلة.',
        ),
        HowToStep(
          title: 'استلم تذكرتك',
          body: 'من بعد الموافقة، كتبان تذكرتك برمز QR داخل التطبيق.',
        ),
        HowToStep(
          title: 'احضر إلى التصوير',
          body: 'ورّي رمز QR ديالك في المدخل نهار التصوير واستمتع بالعرض!',
        ),
      ];

  // Parrain track — how to refer and earn
  String get parrainHeadline => 'ادعُ، شارك واربح';
  String get parrainSubtitle =>
      'شارك روابطك، عمّر الاستوديوهات وتقاضى عن كل مدعو حاضر.';
  List<HowToStep> get parrainSteps => const [
        HowToStep(
          title: 'احصل على رابطك',
          body:
              'افتح برنامجًا وأنشئ رابط الإحالة الخاص بك من زر المشاركة.',
        ),
        HowToStep(
          title: 'شاركه مع معارفك',
          body:
              'أرسل الرابط عبر واتساب أو الرسائل أو مواقع التواصل لأكبر عدد ممكن.',
        ),
        HowToStep(
          title: 'كيحجزو أماكنهم',
          body:
              'كل شخص كيحجز عبر رابطك كيترتبط تلقائيًا بحسابك.',
        ),
        HowToStep(
          title: 'تابع نتائجك مباشرة',
          body:
              'شوف النقرات والحجوزات ديال كل رابط في «إحالاتي».',
        ),
        HowToStep(
          title: 'اربح مقابلك',
          body:
              'كتخلّص عن كل مدعو حاضر فعليًا في التصوير. كل ما عمّرت أكثر، ربحت أكثر.',
        ),
      ];

  /// Video URLs — null until the tutorial clips are produced/hosted.
  String? get clientVideoUrl => null;
  String? get parrainVideoUrl => null;
}

// ──────────────────────────────���───────────────────────────���──────────────────
// Episodes / الحلقات
// ────────────────���────────────────────────────��───────────────────────────────
class EpisodeCopyAr {
  const EpisodeCopyAr();

  String get sectionTitle => 'الحلقات';
  String episodeCount(int n) => '$n ${n == 1 ? 'حلقة' : 'حلقات'}';
  String get reserveEpisode => 'احجز هذه الحلقة';
  String get noUpcomingEpisodes => 'لا توجد تسجيلات قادمة';
  String get nextEpisode => 'الحلقة القادمة';
  String get pastEpisode => 'حلقة سابقة';
  String get allEpisodes => 'جميع الحلق��ت';
  String get upcomingEpisodes => 'الحلقات القادمة';
  String get soldOut => 'مك��مل';
  String availableSeats(int n) => '$n ${n == 1 ? 'مقعد متاح' : 'مقاعد متاحة'}';
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Result / تأكيد الحجز
// ─────────────────────────────────────────────────────────────────────────────
class ReservationResultCopyAr {
  const ReservationResultCopyAr();

  String get title => 'تم إرسال الحجز';
  String get statusBadge => 'في انتظار المراجعة';
  String get summaryShowLabel => 'البرنامج';
  String get summaryNumberLabel => 'رقم الحجز';
  String get summarySeatsLabel => 'المقاعد المحجوزة';
  String get summaryDateLabel => 'تاريخ العرض';
  String get summaryExpiresLabel => 'تنتهي في';
  String seats(int n) => '$n ${n == 1 ? 'مقعد' : 'مقاعد'}';
  String get nextStepsTitle => 'الخطوات التالية';
  String get step1 => 'طلبك قيد المعالجة.';
  String get step2 => 'سيتصل بك فريقنا لتأكيد حجزك.';
  String get step3 => 'بعد الموافقة، ستتلقى تذكرتك الإلكترونية.';
  String get ctaMyReservations => 'عرض حجوزاتي';
  String get ctaHome => 'العودة إلى الرئيسية';
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Detail screen / تفاصيل الحجز
// ─────────────────────────────────────────────────────────────────────────────
class ReservationDetailCopyAr {
  const ReservationDetailCopyAr();

  String get appBarTitle => 'حجزي';

  // Status messages
  String get msgPending =>
      'طلبك قيد المعالجة. سيتم إخطارك فور الموافقة عليه.';
  String get msgApproved =>
      'تم تأكيد حجزك! يمكنك الاطلاع على تذكرتك أدناه.';
  String get msgRejected =>
      'تم رفض طلبك. يمكنك تقديم طلب جديد.';
  String get msgCheckedIn => 'لقد حضرت هذا البرنامج. شكراً!';
  String get msgCancelled => 'لقد ألغيت هذا الحجز.';
  String get msgExpired =>
      'انتهت صلاحية هذا الحجز. يمكنك حجز برنامج آخر.';

  // Section labels
  String get sectionShow => 'البرنامج';
  String get sectionDetails => 'تفاصيل الحجز';

  // Detail row labels
  String get labelNumber => 'رقم الحجز';
  String get labelSeats => 'عدد المقاعد';
  String get labelCreatedAt => 'تاريخ الحجز';
  String get labelExpiresAt => 'تنتهي في';
  String get labelExpiredAt => 'انتهت في';
  String seats(int n) => '$n ${n == 1 ? 'مقعد' : 'مقاعد'}';

  // Alert boxes
  String get alertRejectionTitle => 'سبب الرفض';
  String get alertExpiredTitle => 'انتهت صلاحية الحجز';
  String get alertExpiredBody =>
      'انتهت صلاحية هذا الحجز لأنه لم يتم تأكيده في الوقت المحدد. يمكنك تقديم حجز جديد.';
  String get alertCheckedInTitle => 'تم تسجيل الدخول';
  String get alertCheckedInBody =>
      'تم استخدام تذكرتك للوصول إلى البرنامج. شكراً لمشاركتك!';

  // Action buttons
  String get btnViewTicket => 'عرض تذكرتي';
  String get btnViewUsedTicket => 'عرض التذكرة المستخدمة';
  String get btnDiscoverShows => 'اكتشف البرامج';
  String get btnCancelReservation => 'إلغاء الحجز';

  // Cancel dialog
  String get cancelDialogTitle => 'إلغاء الحجز؟';
  String get cancelDialogBody =>
      'هذا الإجراء لا يمكن التراجع عنه. سيتم تحرير مقعدك.';
  String get cancelDialogBack => 'رجوع';
  String get cancelDialogConfirm => 'تأكيد';

  // Snackbar
  String get cancelSuccess => 'تم إلغاء الحجز';
  String get copiedLabel => 'تم النسخ!';

  // Error view
  String get retry => 'إعادة المحاولة';
}

/// Support Tickets copy in Arabic
class SupportCopyAr {
  const SupportCopyAr();

  // App bar titles
  String get listTitle => 'الدعم / المساعدة';
  String get createTitle => 'تذكرة جديدة';
  String get newButton => 'جديدة';

  // Status badges
  String get statusOpen => 'قيد الانتظار';
  String get statusInProgress => 'قيد المعالجة';
  String get statusClosed => 'تم الحل';

  // Status banner titles & messages
  String get bannerOpenTitle => 'قيد الانتظار';
  String get bannerOpenMsg =>
      'طلبك في قائمة الانتظار.\nسيتواصل معك فريقنا قريباً.';
  String get bannerInProgressTitle => 'قيد المعالجة';
  String get bannerInProgressMsg =>
      'أحد الوكلاء يتولى طلبك.\nسيتم التواصل معك هاتفياً.';
  String get bannerClosedTitle => 'تم الحل';
  String get bannerClosedMsg =>
      'تمت معالجة هذه التذكرة وإغلاقها.\nشكراً على تواصلك معنا.';

  // Card
  String get cardSubtitle => 'سيتواصل معك فريقنا عبر الهاتف.';

  // Empty state
  String get emptyTitle => 'لا توجد تذاكر';
  String get emptySubtitle => 'لم تتواصل مع الدعم بعد.';
  String get emptyButton => 'إنشاء تذكرة';

  // Error state
  String get errorMsg => 'تعذر تحميل تذاكرك.';
  String get retryButton => 'إعادة المحاولة';

  // Create screen
  String get infoBannerTitle => 'معلومة مفيدة';
  String get infoBannerBody =>
      'سيتصل بك فريقنا على الرقم المرتبط بحسابك. '
      'صف مشكلتك بالتفصيل لتسريع المعالجة.';
  String get subjectLabel => 'الموضوع *';
  String get subjectHint => 'مثال: مشكلة في حجزي...';
  String get subjectRequired => 'الموضوع مطلوب';
  String get messageLabel => 'الوصف *';
  String get messageHint =>
      'صف مشكلتك بالتفصيل...\nاذكر رقم الحجز إن وجد.';
  String get submitButton => 'إرسال طلبي';

  // Confirmation screen
  String get confirmationTitle => 'تم إرسال الطلب!';
  String get confirmationBadge => 'في انتظار المعالجة';
  String get summarySubject => 'الموضوع';
  String get summaryTicket => 'التذكرة';
  String get summarySubmitted => 'أُرسلت في';
  String get stepsTitle => 'الخطوات التالية';
  String get step1 => 'تم استلام طلبك بنجاح.';
  String get step2 => 'سيتصل بك أحد الوكلاء خلال 24–48 ساعة.';
  String get step3 => 'ستُغلق التذكرة بعد الحل.';
  String get btnViewTickets => 'عرض تذاكري';
  String get btnBackHome => 'العودة للرئيسية';

  // Detail screen
  String get detailSubjectSection => 'الموضوع';
  String get detailMessageSection => 'رسالتك';
  String get detailMetaSection => 'التفاصيل';
  String get metaTicketNumber => 'رقم التذكرة';
  String get metaSubmittedAt => 'تاريخ الإرسال';
  String get metaUpdatedAt => 'آخر تحديث';
  String get infoCallPending =>
      'ستتلقى اتصالاً من فريقنا.\nتأكد من أن رقمك محدّث.';
  String get infoClosed => 'هذه التذكرة مغلقة.';
  String get detailError => 'خطأ في التحميل';
  String get detailForbidden => 'غير مصرح بالوصول';
  String get detailRetry => 'إعادة المحاولة';

  // Profile entry point
  String get profileTitle => 'الدعم / المساعدة';
  String get profileSubtitle => 'تواصل مع فريقنا';
}

// ─────────────────────────────────────────────────────────────────────────────
// Charge public / المكلف بالجمهور
// ─────────────────────────────────────────────────────────────────────────────
class ChargePublicCopyAr extends ChargePublicCopy {
  const ChargePublicCopyAr();

  @override
  String get spaceSubtitle => 'مساحة المكلف بالجمهور';
  @override
  String get modePublic => 'الوضع العام';
  @override
  String get roleFallbackName => 'مكلف بالجمهور';
  @override
  String get modeCardTitle => 'وضع المكلف بالجمهور';
  @override
  String get modeCardSubtitle => 'اطّلع على مدعوّيك وأرباحك';

  @override
  String get tabHome => 'مساحتي';
  @override
  String get tabShare => 'مشاركة';
  @override
  String get tabGuests => 'مدعوّيّ';
  @override
  String get tabEarnings => 'أرباحي';

  @override
  String get navHome => 'الرئيسية';
  @override
  String get navShare => 'مشاركة';
  @override
  String get navGuests => 'المدعوون';
  @override
  String get navEarnings => 'الأرباح';

  @override
  String get greetingMorning => 'صباح الخير';
  @override
  String get greetingEvening => 'مساء الخير';

  @override
  String get balanceTitle => 'الرصيد المستحق';
  @override
  String money(int v) => '$v درهم';
  @override
  String earnedShort(int v) => 'ربحت $v درهم';
  @override
  String paidShort(int v) => 'دُفع $v درهم';

  @override
  String get kpiBrought => 'أشخاص جلبتهم';
  @override
  String get kpiAttended => 'حضروا';
  @override
  String get kpiPending => 'قيد الانتظار';
  @override
  String get kpiPoints => 'نقاطي';

  @override
  String get earningsByShow => 'الأرباح حسب البرنامج';
  @override
  String get recentGuests => 'مدعوّون حديثاً';
  @override
  String get myReferred => 'مُحالوني';
  @override
  String get seeAll => 'عرض الكل';
  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noGuests => 'لا يوجد مدعوّون حالياً';
  @override
  String get detailSoon => 'القائمة التفصيلية قريباً.';
  @override
  String filterAll(int n) => 'الكل ($n)';
  @override
  String filterAttended(int n) => 'الحاضرون ($n)';
  @override
  String filterApproved(int n) => 'المقبولون ($n)';
  @override
  String filterPending(int n) => 'قيد الانتظار ($n)';
  @override
  String filterCancelled(int n) => 'الملغاة ($n)';

  @override
  String get statusPresent => 'حاضر';
  @override
  String get statusApproved => 'مقبولة';
  @override
  String get statusContacting => 'قيد التواصل';
  @override
  String get statusRejected => 'مرفوضة';
  @override
  String get statusCancelled => 'ملغاة';
  @override
  String get statusExpired => 'منتهية';
  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String visitsCount(int n) => '$n حضور';
  @override
  String gain(int v) => '+$v درهم';
  @override
  String get totalEarned => 'إجمالي الأرباح';
  @override
  String get alreadyPaid => 'المدفوع';
  @override
  String get paymentHistory => 'سجل المدفوعات';
  @override
  String get payment => 'دفعة';
  @override
  String invitedAttended(int inv, int att) => '$inv مدعو · $att حاضر';

  @override
  String get noUpcoming => 'لا توجد برامج قادمة';
  @override
  String get shareHeader => 'شارك برنامجاً لدعوة معارفك واربح عن كل حضور.';
  @override
  String get soldOut => 'مكتمل';
  @override
  String seatsCount(int n) => '$n مقاعد';
  @override
  String get shareBtn => 'مشاركة';
}
