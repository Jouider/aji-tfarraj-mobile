/// Copy for the « Roue de la chance ».
///
/// A contract, so French and Arabic cannot drift apart. Addressed with « tu »,
/// like the rest of the rewards space.
abstract class WheelCopy {
  String get title;

  /// La carte d'entrée, sur l'accueil et dans Fidélité.
  String get entryTitle;
  String entrySpinsLeft(int n);
  String get entryComeBack;
  String get entryPlay;

  String get headline;
  String subtitle(int dailySpins);
  String balance(int points);
  String spinsLeft(int n);
  String nextSpinsIn(Duration d);

  String get spin;
  String get spinning;
  String get comeBackTomorrow;

  /// Le chiffre d'une case, et son unité en dessous.
  String get pointsUnit;

  String jackpotOfTheDay(String title);
  String get jackpotGoneToday;

  String winTitle(int points);
  String winBody(int balance);
  String get retryTitle;
  String retryBody(int spinsLeft);
  String get jackpotTitle;
  String get jackpotBody;
  String get myRewards;
  String get again;
  String get close;

  String get closed;
  String get noSpinsLeft;
  String get error;

  // ─── Un essai de plus avec une vidéo ─────────────────────────────────
  String subtitleWithVideo(int freeSpins);
  String videoSpinsLeft(int n);
  String get entryVideoSpin;
  String get watchVideo;

  /// Le même, en plus court, pour le bouton du résultat.
  String get watchVideoShort;
  String get retryBodyVideo;
  String get videoLoading;
  String get unlocking;
  String get videoNotFinished;
  String get unlockSlow;
  String get adRequired;
}

class WheelCopyFr implements WheelCopy {
  const WheelCopyFr();

  @override
  String get title => 'Roue de la chance';

  @override
  String get entryTitle => 'Roue de la chance';
  @override
  String entrySpinsLeft(int n) => n == 1
      ? '1 essai gratuit aujourd\'hui'
      : '$n essais gratuits aujourd\'hui';
  @override
  String get entryComeBack => 'Nouveaux essais demain';
  @override
  String get entryPlay => 'Jouer';

  @override
  String get headline => 'Tente ta chance';
  @override
  String subtitle(int dailySpins) => '$dailySpins essais gratuits chaque jour';
  @override
  String balance(int points) => '$points points';
  @override
  String spinsLeft(int n) => switch (n) {
        0 => 'Plus d\'essai aujourd\'hui',
        1 => '1 essai restant aujourd\'hui',
        _ => '$n essais restants aujourd\'hui',
      };
  @override
  String nextSpinsIn(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return 'Nouveaux essais dans $m min';
    return 'Nouveaux essais dans $h h ${m.toString().padLeft(2, '0')}';
  }

  @override
  String get spin => 'Tourner la roue';
  @override
  String get spinning => 'La roue tourne…';
  @override
  String get comeBackTomorrow => 'Reviens demain';

  @override
  String get pointsUnit => 'pts';

  @override
  String jackpotOfTheDay(String title) => 'Gros lot du jour : $title';
  @override
  String get jackpotGoneToday =>
      'Le gros lot du jour est déjà parti. Il revient demain.';

  @override
  String winTitle(int points) => 'Bravo ! +$points points';
  @override
  String winBody(int balance) =>
      'Ils sont déjà dans ton solde : $balance points.';
  @override
  String get retryTitle => 'Pas cette fois !';
  @override
  String retryBody(int spinsLeft) => spinsLeft > 0
      ? (spinsLeft == 1
          ? 'Il te reste 1 essai aujourd\'hui.'
          : 'Il te reste $spinsLeft essais aujourd\'hui.')
      : 'Reviens demain pour de nouveaux essais.';
  @override
  String get jackpotTitle => 'Incroyable, tu as gagné !';
  @override
  String get jackpotBody =>
      'L\'équipe te contacte pour te la remettre. Tu la retrouves dans '
      'Mes récompenses.';
  @override
  String get myRewards => 'Mes récompenses';
  @override
  String get again => 'Rejouer';
  @override
  String get close => 'Fermer';

  @override
  String get closed => 'La roue de la chance est fermée pour le moment.';
  @override
  String get noSpinsLeft =>
      'Tu as utilisé tes essais d\'aujourd\'hui. Reviens demain !';
  @override
  String get error => 'La roue n\'a pas pu tourner. Réessaie.';

  @override
  String subtitleWithVideo(int freeSpins) => freeSpins == 1
      ? '1 essai gratuit par jour, puis une vidéo par essai'
      : '$freeSpins essais gratuits par jour, puis une vidéo par essai';
  @override
  String videoSpinsLeft(int n) => n == 1
      ? '1 essai à débloquer avec une vidéo'
      : '$n essais à débloquer avec une vidéo';
  @override
  String get entryVideoSpin => 'Un essai de plus avec une vidéo';
  @override
  String get watchVideo => 'Regarder une vidéo pour un nouvel essai';
  @override
  String get watchVideoShort => 'Nouvel essai avec une vidéo';
  @override
  String get retryBodyVideo => 'Regarde une vidéo pour un nouvel essai.';
  @override
  String get videoLoading => 'La vidéo arrive…';
  @override
  String get unlocking => 'Ton essai arrive…';
  @override
  String get videoNotFinished =>
      'La vidéo n\'est pas allée jusqu\'au bout. Réessaie dans un instant.';
  @override
  String get unlockSlow =>
      'Ton essai n\'est pas encore arrivé. Réessaie dans un instant.';
  @override
  String get adRequired => 'Regarde une vidéo pour tourner encore la roue.';
}

class WheelCopyAr implements WheelCopy {
  const WheelCopyAr();

  @override
  String get title => 'عجلة الحظ';

  @override
  String get entryTitle => 'عجلة الحظ';
  @override
  String entrySpinsLeft(int n) =>
      n == 1 ? 'محاولة مجانية واحدة اليوم' : '$n محاولات مجانية اليوم';
  @override
  String get entryComeBack => 'محاولات جديدة غدًا';
  @override
  String get entryPlay => 'العب';

  @override
  String get headline => 'جرّب حظك';
  @override
  String subtitle(int dailySpins) => '$dailySpins محاولات مجانية كل يوم';
  @override
  String balance(int points) => '$points نقطة';
  @override
  String spinsLeft(int n) => switch (n) {
        0 => 'لا محاولات متبقية اليوم',
        1 => 'محاولة واحدة متبقية اليوم',
        _ => '$n محاولات متبقية اليوم',
      };
  @override
  String nextSpinsIn(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h == 0) return 'محاولات جديدة بعد $m د';
    return 'محاولات جديدة بعد $h س ${m.toString().padLeft(2, '0')} د';
  }

  @override
  String get spin => 'أدر العجلة';
  @override
  String get spinning => 'العجلة تدور…';
  @override
  String get comeBackTomorrow => 'ارجع غدًا';

  @override
  String get pointsUnit => 'نقطة';

  @override
  String jackpotOfTheDay(String title) => 'الجائزة الكبرى اليوم: $title';
  @override
  String get jackpotGoneToday =>
      'الجائزة الكبرى لهذا اليوم ربحها شخص آخر. تعود غدًا.';

  @override
  String winTitle(int points) => 'مبروك! +$points نقطة';
  @override
  String winBody(int balance) => 'أُضيفت إلى رصيدك: $balance نقطة.';
  @override
  String get retryTitle => 'ليس هذه المرة!';
  @override
  String retryBody(int spinsLeft) => spinsLeft > 0
      ? (spinsLeft == 1
          ? 'بقيت لك محاولة واحدة اليوم.'
          : 'بقيت لك $spinsLeft محاولات اليوم.')
      : 'ارجع غدًا لمحاولات جديدة.';
  @override
  String get jackpotTitle => 'رائع، لقد ربحت!';
  @override
  String get jackpotBody => 'سيتصل بك الفريق لتسليمها. تجدها في مكافآتي.';
  @override
  String get myRewards => 'مكافآتي';
  @override
  String get again => 'العب مجددًا';
  @override
  String get close => 'إغلاق';

  @override
  String get closed => 'عجلة الحظ مغلقة حاليًا.';
  @override
  String get noSpinsLeft => 'استعملت محاولاتك لليوم. ارجع غدًا!';
  @override
  String get error => 'لم تتمكن العجلة من الدوران. حاول مجددًا.';

  @override
  String subtitleWithVideo(int freeSpins) => freeSpins == 1
      ? 'محاولة مجانية واحدة كل يوم، ثم فيديو لكل محاولة'
      : '$freeSpins محاولات مجانية كل يوم، ثم فيديو لكل محاولة';
  @override
  String videoSpinsLeft(int n) =>
      n == 1 ? 'محاولة واحدة تُفتح بفيديو' : '$n محاولات تُفتح بفيديو';
  @override
  String get entryVideoSpin => 'محاولة إضافية بفيديو';
  @override
  String get watchVideo => 'شاهد فيديو لمحاولة جديدة';
  @override
  String get watchVideoShort => 'محاولة جديدة بفيديو';
  @override
  String get retryBodyVideo => 'شاهد فيديو لمحاولة جديدة.';
  @override
  String get videoLoading => 'جارٍ تحميل الفيديو…';
  @override
  String get unlocking => 'محاولتك في الطريق…';
  @override
  String get videoNotFinished => 'لم يكتمل الفيديو. حاول بعد قليل.';
  @override
  String get unlockSlow => 'محاولتك لم تصل بعد. حاول بعد قليل.';
  @override
  String get adRequired => 'شاهد فيديو لتدير العجلة مرة أخرى.';
}
