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

  String get rules;
  String get rulesTitle;
  String rulesIntro(int dailySpins);
  String oddsPoints(int points);
  String get oddsRetry;
  String oddsJackpot(String title);
  String get rulesFootnote;

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
  String get rules => 'Règles';
  @override
  String get rulesTitle => 'Les règles de la roue';
  @override
  String rulesIntro(int dailySpins) =>
      'Tu as $dailySpins essais gratuits par jour, remis à zéro à minuit. '
      'Le résultat est tiré au hasard par notre serveur, avec ces chances :';
  @override
  String oddsPoints(int points) => '$points points';
  @override
  String get oddsRetry => 'Réessaie';
  @override
  String oddsJackpot(String title) => 'Gros lot : $title';
  @override
  String get rulesFootnote =>
      'Les points gagnés comptent comme les autres : ils débloquent les '
      'récompenses de la section Récompenses. Le gros lot est limité chaque '
      'jour ; l\'équipe te contacte pour te le remettre.';

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
  String get rules => 'القواعد';
  @override
  String get rulesTitle => 'قواعد العجلة';
  @override
  String rulesIntro(int dailySpins) =>
      'لديك $dailySpins محاولات مجانية في اليوم، تتجدد عند منتصف الليل. '
      'النتيجة يختارها خادمنا عشوائيًا بهذه الحظوظ:';
  @override
  String oddsPoints(int points) => '$points نقطة';
  @override
  String get oddsRetry => 'حاول مجددًا';
  @override
  String oddsJackpot(String title) => 'الجائزة الكبرى: $title';
  @override
  String get rulesFootnote =>
      'النقاط التي تربحها تُحسب مثل غيرها: تفتح لك مكافآت قسم المكافآت. '
      'الجائزة الكبرى محدودة كل يوم، والفريق يتصل بك لتسليمها.';

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
}
