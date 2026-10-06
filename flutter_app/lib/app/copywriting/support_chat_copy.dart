/// Copy for the support chat — the client writing to the Aji Tfarraj team.
///
/// A contract, so French and Arabic cannot drift apart: a string added here and
/// missing in one language does not compile. Addressed with « vous », like the
/// rest of support.
abstract class SupportChatCopy {
  // The list of conversations
  String get listTitle;
  String get newConversation;
  String get emptyTitle;
  String get emptyBody;
  String get emptyButton;
  String get you;
  String get team;
  String get loadError;
  String get retry;
  String get statusOpen;
  String get statusInProgress;
  String get statusClosed;

  // Starting a conversation
  String get createTitle;
  String get createIntro;
  String get subjectLabel;
  String get subjectHint;
  String get subjectRequired;
  String get messageLabel;
  String get messageHint;
  String get messageRequired;
  String get start;

  // The conversation
  String get inputHint;
  String get sendFailed;
  String get retrySend;
  String get closedNotice;
  String get waitingNotice;
  String get today;
  String get yesterday;
  String get tooLong;
}

class SupportChatCopyFr implements SupportChatCopy {
  const SupportChatCopyFr();

  @override
  String get listTitle => 'Support';
  @override
  String get newConversation => 'Nouvelle conversation';
  @override
  String get emptyTitle => 'Une question ? Écrivez-nous';
  @override
  String get emptyBody =>
      'L\'équipe Aji Tfarraj vous répond ici, dans l\'application. '
      'Vous recevez une notification à chaque réponse.';
  @override
  String get emptyButton => 'Écrire au support';
  @override
  String get you => 'Vous : ';
  @override
  String get team => 'Équipe Aji Tfarraj';
  @override
  String get loadError => 'Impossible de charger vos conversations.';
  @override
  String get retry => 'Réessayer';
  @override
  String get statusOpen => 'En attente';
  @override
  String get statusInProgress => 'En cours';
  @override
  String get statusClosed => 'Fermée';

  @override
  String get createTitle => 'Nouvelle conversation';
  @override
  String get createIntro =>
      'Décrivez votre question : l\'équipe vous répond dans cette conversation, '
      'et vous recevez une notification.';
  @override
  String get subjectLabel => 'Sujet';
  @override
  String get subjectHint => 'Ex. : je n\'ai pas reçu mon billet';
  @override
  String get subjectRequired => 'Indiquez un sujet.';
  @override
  String get messageLabel => 'Votre message';
  @override
  String get messageHint =>
      'Expliquez ce qui se passe. Si c\'est une réservation, précisez l\'émission et la date.';
  @override
  String get messageRequired => 'Écrivez votre message.';
  @override
  String get start => 'Envoyer';

  @override
  String get inputHint => 'Écrire un message…';
  @override
  String get sendFailed => 'Non envoyé';
  @override
  String get retrySend => 'Réessayer';
  @override
  String get closedNotice =>
      'Conversation fermée. Écrivez un message pour la rouvrir.';
  @override
  String get waitingNotice =>
      'Message bien reçu. L\'équipe vous répond ici, et vous recevez une notification.';
  @override
  String get today => 'Aujourd\'hui';
  @override
  String get yesterday => 'Hier';
  @override
  String get tooLong => 'Message trop long (2000 caractères au plus).';
}

class SupportChatCopyAr implements SupportChatCopy {
  const SupportChatCopyAr();

  @override
  String get listTitle => 'الدعم';
  @override
  String get newConversation => 'محادثة جديدة';
  @override
  String get emptyTitle => 'عندك سؤال؟ راسلنا';
  @override
  String get emptyBody => 'فريق Aji Tfarraj يجيبك هنا، داخل التطبيق. '
      'تتوصل بإشعار مع كل رد.';
  @override
  String get emptyButton => 'راسل الدعم';
  @override
  String get you => 'أنت: ';
  @override
  String get team => 'فريق Aji Tfarraj';
  @override
  String get loadError => 'تعذر تحميل محادثاتك.';
  @override
  String get retry => 'إعادة المحاولة';
  @override
  String get statusOpen => 'في الانتظار';
  @override
  String get statusInProgress => 'قيد المعالجة';
  @override
  String get statusClosed => 'مغلقة';

  @override
  String get createTitle => 'محادثة جديدة';
  @override
  String get createIntro =>
      'اكتب سؤالك: الفريق يجيبك في هذه المحادثة، وتتوصل بإشعار.';
  @override
  String get subjectLabel => 'الموضوع';
  @override
  String get subjectHint => 'مثال: لم أتوصل بتذكرتي';
  @override
  String get subjectRequired => 'اكتب الموضوع.';
  @override
  String get messageLabel => 'رسالتك';
  @override
  String get messageHint =>
      'اشرح ما يحدث. إذا كان الأمر يتعلق بحجز، اذكر البرنامج والتاريخ.';
  @override
  String get messageRequired => 'اكتب رسالتك.';
  @override
  String get start => 'إرسال';

  @override
  String get inputHint => 'اكتب رسالة…';
  @override
  String get sendFailed => 'لم تُرسل';
  @override
  String get retrySend => 'أعد المحاولة';
  @override
  String get closedNotice => 'المحادثة مغلقة. اكتب رسالة لإعادة فتحها.';
  @override
  String get waitingNotice => 'وصلت رسالتك. الفريق يجيبك هنا، وتتوصل بإشعار.';
  @override
  String get today => 'اليوم';
  @override
  String get yesterday => 'أمس';
  @override
  String get tooLong => 'الرسالة طويلة جداً (2000 حرف على الأكثر).';
}
