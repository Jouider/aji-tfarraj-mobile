import 'package:aji_tfarraj/app/copywriting/copy_fr.dart' show ConditionSection;

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
          description: 'الدخول مخصص للأشخاص الذين تبلغ أعمارهم 16 سنة فما فوق.',
        ),
        RuleItemAr(
          title: 'التحقق من الهوية',
          description:
              'قد يُطلب منك إبراز بطاقة الهوية عند الدخول للتحقق من عمرك.',
        ),
        RuleItemAr(
          title: 'اللباس المناسب',
          description:
              'يُشترط ارتداء لباس لائق. قد يُرفض الدخول في حالة اللباس غير المناسب.',
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
  String get passwordWeak => 'يجب أن تحتوي كلمة المرور على حرف كبير وحرف صغير ورقم على الأقل.';
  String get nameRequired => 'يرجى إدخال اسمك';
  String get nameMin => 'الاسم يجب أن يحتوي على حرفين على الأقل';
  String get confirmPasswordRequired => 'يرجى تأكيد كلمة المرور';
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  // Auth landing
  String get authLandingTitle => 'مرحباً';
  String get authLandingSubtitle =>
      'احجز مقاعدك للبرامج التلفزيونية المغربية';
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
  String get loyaltyLabel => 'الولاء';
  String get notificationsLabel => 'الإشعارات';
  String unreadCount(int n) => '$n غير مقروء${n > 1 ? 'ة' : ''}';
  String get helpLabel => 'المساعدة';
  String get aboutLabel => 'حول التطبيق';
  String get logoutLabel => 'تسجيل الخروج';

  // Edit profile
  String get editTitle => 'تعديل الملف الشخصي';
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
  String availableSeats(int n) =>
      '$n ${n == 1 ? 'مقعد متاح' : 'مقاعد متاحة'}';
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
  String availableSeats(int n) =>
      '$n ${n == 1 ? 'مقعد متاح' : 'مقاعد متاحة'}';
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
  String get agreementCheckboxLabel =>
      'لقد قرأت وأوافق على شروط المشاركة.';
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
  String get accessDeniedSubtitle =>
      'ليس لديك الصلاحيات للوصول إلى هذا القسم.';
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
