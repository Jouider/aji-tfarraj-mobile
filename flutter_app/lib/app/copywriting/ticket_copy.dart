/// Copy for the live ticket: what the ticket says at each moment of the
/// recording, the full-screen QR, past tickets and the empty screen.
///
/// A contract, so French and Arabic cannot drift apart: a string added here and
/// missing in one language does not compile. Addressed with « vous », like the
/// rest of the audience's space.
abstract class TicketScreenCopy {
  // What the ticket says, moment by moment
  String get startsIn;
  String get startsTodayIn;

  /// More than a day away: days, hours, minutes. Under a day the screen shows a
  /// running clock, which reads the same in both languages.
  String countdownDays(int days, String hours, String minutes);
  String get liveTitle;
  String get liveHint;
  String get checkedInTitle;
  String checkedInHint(String time);
  String get validTitle;
  String get validHint;
  String get attended;
  String get missed;

  // The facts on the ticket
  String get factDate;
  String get factTime;
  String get factSeats;
  String get directions;
  String get seeReservation;

  // The QR
  String get tapToEnlarge;
  String get qrSemantics;
  String get close;

  // Several tickets
  String page(int index, int total);

  // Past tickets
  String get pastTitle;
  String pastSeeAll(int count);
  String get pastSeeLess;

  // Nothing to show yet
  String get noUpcomingTitle;
  String get noUpcomingBody;
  String get browseShows;
  String get emptyTitle;
  String get emptyBody;
  String pendingTitle(String show);
  String get pendingBody;

  /// Reserved, confirmed by the team, ticket ready: always three.
  List<String> get pendingSteps;
  String get refresh;
}

class TicketScreenCopyFr implements TicketScreenCopy {
  const TicketScreenCopyFr();

  @override
  String get startsIn => 'Début dans';
  @override
  String get startsTodayIn => 'C\'est aujourd\'hui, début dans';
  @override
  String countdownDays(int days, String hours, String minutes) =>
      '$days j $hours h $minutes min';
  @override
  String get liveTitle => 'Tournage en cours';
  @override
  String get liveHint => 'Présentez votre QR code à l\'entrée';
  @override
  String get checkedInTitle => 'Entrée validée';
  @override
  String checkedInHint(String time) => 'À $time. Bon tournage !';
  @override
  String get validTitle => 'Billet valide';
  @override
  String get validHint => 'Présentez ce QR code à l\'entrée';
  @override
  String get attended => 'Présent';
  @override
  String get missed => 'Non utilisé';

  @override
  String get factDate => 'Date';
  @override
  String get factTime => 'Heure';
  @override
  String get factSeats => 'Places';
  @override
  String get directions => 'Itinéraire';
  @override
  String get seeReservation => 'Voir la réservation';

  @override
  String get tapToEnlarge => 'Touchez le QR code pour l\'agrandir';
  @override
  String get qrSemantics => 'QR code du billet. Touchez pour l\'agrandir.';
  @override
  String get close => 'Fermer';

  @override
  String page(int index, int total) => 'Billet $index sur $total';

  @override
  String get pastTitle => 'Billets passés';
  @override
  String pastSeeAll(int count) => 'Voir les $count billets';
  @override
  String get pastSeeLess => 'Voir moins';

  @override
  String get noUpcomingTitle => 'Aucun tournage à venir';
  @override
  String get noUpcomingBody =>
      'Réservez votre prochaine émission : votre billet apparaîtra ici.';
  @override
  String get browseShows => 'Découvrir les émissions';
  @override
  String get emptyTitle => 'Pas encore de billet';
  @override
  String get emptyBody =>
      'Réservez une émission : votre billet apparaîtra ici dès que notre équipe aura confirmé votre place.';
  @override
  String pendingTitle(String show) => 'Votre réservation pour « $show »';
  @override
  String get pendingBody =>
      'Notre équipe confirme votre place. Votre billet apparaîtra ici dès son approbation.';
  @override
  List<String> get pendingSteps => const ['Réservé', 'Confirmation', 'Billet'];
  @override
  String get refresh => 'Actualiser';
}

class TicketScreenCopyAr implements TicketScreenCopy {
  const TicketScreenCopyAr();

  @override
  String get startsIn => 'يبدأ بعد';
  @override
  String get startsTodayIn => 'اليوم، يبدأ بعد';
  @override
  String countdownDays(int days, String hours, String minutes) =>
      '$days يوم $hours س $minutes د';
  @override
  String get liveTitle => 'التصوير جارٍ';
  @override
  String get liveHint => 'أظهر رمز QR عند الدخول';
  @override
  String get checkedInTitle => 'تم تسجيل دخولك';
  @override
  String checkedInHint(String time) => 'على الساعة $time. مشاهدة ممتعة!';
  @override
  String get validTitle => 'بطاقة صالحة';
  @override
  String get validHint => 'أظهر رمز QR هذا عند الدخول';
  @override
  String get attended => 'حضرت';
  @override
  String get missed => 'لم تُستخدم';

  @override
  String get factDate => 'التاريخ';
  @override
  String get factTime => 'الساعة';
  @override
  String get factSeats => 'المقاعد';
  @override
  String get directions => 'الاتجاهات';
  @override
  String get seeReservation => 'عرض الحجز';

  @override
  String get tapToEnlarge => 'المس الرمز لتكبيره';
  @override
  String get qrSemantics => 'رمز QR للبطاقة. المس لتكبيره.';
  @override
  String get close => 'إغلاق';

  @override
  String page(int index, int total) => 'البطاقة $index من $total';

  @override
  String get pastTitle => 'البطاقات السابقة';
  @override
  String pastSeeAll(int count) => 'عرض كل البطاقات ($count)';
  @override
  String get pastSeeLess => 'عرض أقل';

  @override
  String get noUpcomingTitle => 'لا يوجد تصوير قادم';
  @override
  String get noUpcomingBody => 'احجز برنامجك القادم وستظهر بطاقتك هنا.';
  @override
  String get browseShows => 'اكتشف البرامج';
  @override
  String get emptyTitle => 'لا توجد بطاقة بعد';
  @override
  String get emptyBody =>
      'احجز برنامجاً، وستظهر بطاقتك هنا بعد أن يؤكد فريقنا مكانك.';
  @override
  String pendingTitle(String show) => 'حجزك لـ « $show »';
  @override
  String get pendingBody =>
      'فريقنا يؤكد مكانك. ستظهر بطاقتك هنا مباشرة بعد الموافقة.';
  @override
  List<String> get pendingSteps => const ['تم الحجز', 'التأكيد', 'البطاقة'];
  @override
  String get refresh => 'تحديث';
}
