/// Copy for the waiting list, on a reservation still « En attente ».
///
/// The staff puts someone on the list when the set is full; the app only says
/// that much, and what to do next. How sure the staff thinks they are stays on
/// the dashboard. A contract, so French and Arabic cannot drift apart.
abstract class WaitlistCopy {
  /// Le badge, à la place de « En attente ».
  String get waitingBadge;
  String get comingBadge;

  /// Ce que ça veut dire, et quoi faire.
  String get waitingBody;
  String get comingBody;
}

class WaitlistCopyFr implements WaitlistCopy {
  const WaitlistCopyFr();

  @override
  String get waitingBadge => 'Liste d\'attente';
  @override
  String get comingBadge => 'Venue notée';
  @override
  String get waitingBody =>
      'Le plateau est complet pour le moment. Si une place se libère, on '
      't\'appelle : garde ton téléphone allumé.';
  @override
  String get comingBody =>
      'Tu nous as dit que tu peux venir. Dès qu\'une place est à toi, ton '
      'billet arrive ici avec une notification.';
}

class WaitlistCopyAr implements WaitlistCopy {
  const WaitlistCopyAr();

  @override
  String get waitingBadge => 'لائحة الانتظار';
  @override
  String get comingBadge => 'حضورك مسجّل';
  @override
  String get waitingBody =>
      'البلاتو عامر دابا. إلا تحررات شي بلاصة غادي نعيطو ليك: خلّي التيليفون '
      'ديالك مشعول.';
  @override
  String get comingBody =>
      'قلتي لينا بلي تقدر تجي. ملي تولّي البلاصة ديالك، غادي توصلك التذكرة هنا '
      'مع إشعار.';
}
