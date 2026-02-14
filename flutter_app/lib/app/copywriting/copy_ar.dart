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
  String get unauthorized =>
      'انتهت صلاحية جلستك. يرجى تسجيل الدخول مرة أخرى.';
  String get soldOut =>
      'هذا العرض مكتمل. لا توجد أماكن متاحة.';
  String get unknownError =>
      'حدث خطأ غير متوقع. يرجى المحاولة مرة أخرى.';
  String get invalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
  String get emailAlreadyExists =>
      'يوجد حساب مسجل بهذا البريد الإلكتروني.';
  String get validationError =>
      'يرجى التحقق من المعلومات المدخلة.';
}

/// Rules page content in Arabic
class RulesCopyAr {
  const RulesCopyAr();

  String get title => 'قواعد العرض';
  String get introduction =>
      'بحجزك لمكان، فإنك توافق على الشروط التالية:';

  List<RuleItemAr> get items => const [
        RuleItemAr(
          title: 'شرط السن',
          description:
              'الدخول مخصص للأشخاص الذين تبلغ أعمارهم 16 سنة فما فوق.',
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
          description:
              'يرجى الالتزام بتعليمات الموظفين وأعوان الأمن.',
        ),
      ];

  String get acceptance =>
      'لقد قرأت وأوافق على قواعد العرض.';
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
