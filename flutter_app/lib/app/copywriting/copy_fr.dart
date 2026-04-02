/// French copywriting for Aji Tfarraj app
/// Starter pack - not final marketing copy
class CopyFr {
  CopyFr._();

  // ============================================
  // Buttons
  // ============================================
  static const buttons = ButtonsCopyFr();

  // ============================================
  // Reservation Statuses
  // ============================================
  static const statuses = StatusesCopyFr();

  // ============================================
  // Error Messages
  // ============================================
  static const errors = ErrorsCopyFr();

  // ============================================
  // Rules Page
  // ============================================
  static const rules = RulesCopyFr();

  // ============================================
  // Loyalty / Fidélité
  // ============================================
  static const loyalty = LoyaltyCopyFr();

  // ============================================
  // Auth (login / register)
  // ============================================
  static const auth = AuthCopyFr();

  // ============================================
  // Common UI
  // ============================================
  static const common = CommonCopyFr();

  // ============================================
  // Profile screen
  // ============================================
  static const profile = ProfileCopyFr();

  // ============================================
  // My Reservations screen
  // ============================================
  static const myReservations = MyReservationsCopyFr();

  // ============================================
  // Home screen
  // ============================================
  static const home = HomeCopyFr();

  // ============================================
  // Show Detail screen
  // ============================================
  static const showDetail = ShowDetailCopyFr();

  // ============================================
  // Reserve Seats screen
  // ============================================
  static const reserveSeats = ReserveSeatsCopyFr();

  // ============================================
  // Ticket screen
  // ============================================
  static const ticket = TicketCopyFr();

  // ============================================
  // Browse screen
  // ============================================
  static const browse = BrowseCopyFr();

  // ============================================
  // Notifications screen
  // ============================================
  static const notifications = NotificationsCopyFr();

  // ============================================
  // Bottom Nav Tabs
  // ============================================
  static const navTabs = NavTabsCopyFr();

  // ============================================
  // Staff Check-in
  // ============================================
  static const staff = StaffCopyFr();

  // ============================================
  // Conditions de participation
  // ============================================
  static const conditions = ConditionsCopyFr();

  // ============================================
  // Rewards
  // ============================================
  static const rewards = RewardsCopyFr();

  // ============================================
  // Referral / Parrainage
  // ============================================
  static const referral = ReferralCopyFr();

  // ============================================
  // Episodes
  // ============================================
  static const episode = EpisodeCopyFr();
}

/// Rewards screen copy in French
class RewardsCopyFr {
  const RewardsCopyFr();

  String get rewardsTitle => 'Récompenses';
  String get myRewardsTitle => 'Mes demandes';
  String get collectReward => 'Obtenir';
  String get rewardRequestSent =>
      'Demande envoyée. En attente d\'approbation.';
  String get pendingLabel => 'En attente';
  String get approvedLabel => 'Approuvé';
  String get rejectedLabel => 'Refusé';
  String get insufficientPoints => 'Vous n\'avez pas assez de points.';
  String get duplicatePending =>
      'Vous avez déjà demandé cette récompense.';
  String get rewardInactive => 'Cette récompense n\'est plus disponible.';
  String get noRewardsYet => 'Aucune récompense disponible.';
  String get noMyRewardsYet => 'Aucune demande pour le moment.';
  String get pointsRequired => 'pts requis';
  String get seeAllRewards => 'Voir toutes les récompenses';
  String get requestedAt => 'Demandée le';
}

/// Button labels in French
class ButtonsCopyFr {
  const ButtonsCopyFr();

  String get login => 'Se connecter';
  String get register => 'S\'inscrire';
  String get reserve => 'Réserver';
  String get confirm => 'Confirmer';
  String get cancel => 'Annuler';
  String get logout => 'Se déconnecter';
  String get viewTicket => 'Voir mon billet';
}

/// Reservation status labels in French
class StatusesCopyFr {
  const StatusesCopyFr();

  String get pendingReview => 'En attente de validation';
  String get contacting => 'En cours de contact';
  String get approved => 'Réservation confirmée';
  String get rejected => 'Réservation refusée';
  String get cancelled => 'Réservation annulée';
  String get expired => 'Réservation expirée';
  String get checkedIn => 'Entrée validée';

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

/// Error messages in French
class ErrorsCopyFr {
  const ErrorsCopyFr();

  String get networkError =>
      'Impossible de se connecter au serveur. Veuillez vérifier votre connexion internet.';
  String get unauthorized =>
      'Votre session a expiré. Veuillez vous reconnecter.';
  String get soldOut => 'Ce spectacle est complet. Aucune place disponible.';
  String get unknownError =>
      'Une erreur inattendue est survenue. Veuillez réessayer.';
  String get invalidCredentials => 'Email ou mot de passe incorrect.';
  String get emailAlreadyExists => 'Un compte avec cet email existe déjà.';
  String get validationError => 'Veuillez vérifier les informations saisies.';
  String get errorTitle => 'Une erreur est survenue';
}

/// Rules page content in French
class RulesCopyFr {
  const RulesCopyFr();

  String get title => 'Règlement du spectacle';
  String get introduction =>
      'En réservant une place, vous acceptez les conditions suivantes :';

  List<RuleItem> get items => const [
        RuleItem(
          title: 'Restriction d\'âge',
          description:
              'L\'accès au spectacle est réservé aux personnes âgées de 16 ans et plus.',
        ),
        RuleItem(
          title: 'Vérification d\'identité',
          description:
              'Une pièce d\'identité peut être demandée à l\'entrée pour vérifier votre âge.',
        ),
        RuleItem(
          title: 'Tenue vestimentaire',
          description:
              'Une tenue correcte est exigée. L\'accès peut être refusé en cas de tenue inappropriée.',
        ),
        RuleItem(
          title: 'Interdiction de photos et vidéos',
          description:
              'L\'enregistrement photo et vidéo est strictement interdit pendant le spectacle.',
        ),
        RuleItem(
          title: 'Respect des consignes',
          description:
              'Veuillez respecter les instructions du personnel et des agents de sécurité.',
        ),
      ];

  String get acceptance => 'J\'ai lu et j\'accepte le règlement du spectacle.';
}

/// Loyalty copy in French
class LoyaltyCopyFr {
  const LoyaltyCopyFr();

  String get loyaltyTitle => 'Fidélité';
  String get pointsTotal => 'Points';
  String get pointsSubtitle => 'Gagnez des points après chaque check-in';
  String get history => 'Historique';
  String get rewards => 'Récompenses';
  String get comingSoon => 'Bientôt disponible';
  String get noPointsYet => 'Aucun point pour le moment';
  String get attendanceLabel => 'Présence';
}

/// Rule item model
class RuleItem {
  final String title;
  final String description;

  const RuleItem({
    required this.title,
    required this.description,
  });
}

/// Auth (login / register) copy in French
class AuthCopyFr {
  const AuthCopyFr();

  // Login
  String get loginSubtitle => 'Connectez-vous pour réserver';
  String get noAccount => 'Pas encore de compte ?';
  String get registerLink => 'S\'inscrire';

  // Register
  String get registerTitle => 'Créer un compte';
  String get registerSubtitle => 'Inscrivez-vous pour réserver vos places';
  String get alreadyAccount => 'Déjà un compte ?';
  String get loginLink => 'Se connecter';

  // Form fields
  String get emailLabel => 'Email';
  String get emailHint => 'votre@email.com';
  String get passwordLabel => 'Mot de passe';
  String get nameLabel => 'Nom complet';
  String get nameHint => 'Ahmed Benjelloun';
  String get confirmPasswordLabel => 'Confirmer le mot de passe';

  // Validation
  String get emailRequired => 'Veuillez entrer votre email';
  String get emailInvalid => 'Veuillez entrer un email valide';
  String get passwordRequired => 'Veuillez entrer votre mot de passe';
  String get passwordMin => 'Le mot de passe doit contenir au moins 8 caractères';
  String get passwordWeak => 'Le mot de passe doit contenir au moins 1 majuscule, 1 minuscule et 1 chiffre.';
  String get nameRequired => 'Veuillez entrer votre nom';
  String get nameMin => 'Le nom doit contenir au moins 2 caractères';
  String get confirmPasswordRequired => 'Veuillez confirmer votre mot de passe';
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  // Auth landing
  String get authLandingTitle => 'Bienvenue';
  String get authLandingSubtitle =>
      'Réservez vos places pour les émissions TV marocaines';
  String get continueWithGoogle => 'Continuer avec Google';
  String get continueWithApple => 'Continuer avec Apple';
  String get continueWithEmail => 'Se connecter par email';
  String get createAccount => 'Créer un compte';
  String get orDivider => 'ou';
  String get termsNotice =>
      'En continuant, vous acceptez nos Conditions d\'utilisation';

  // Forgot password
  String get forgotPassword => 'Mot de passe oublié ?';
  String get forgotPasswordTitle => 'Mot de passe oublié';
  String get forgotPasswordSubtitle =>
      'Saisissez votre email pour recevoir un lien de réinitialisation';
  String get forgotPasswordButton => 'Envoyer le lien';
  String get forgotPasswordSuccess => 'Email envoyé !';
  String get forgotPasswordSuccessMessage =>
      'Vérifiez votre boîte mail et suivez les instructions pour réinitialiser votre mot de passe.';
  String get backToLogin => 'Retour à la connexion';
}

/// Common UI copy in French
class CommonCopyFr {
  const CommonCopyFr();

  String get retry => 'Réessayer';
  String get seeAll => 'Voir tout';
  String get loading => 'Chargement...';
  String get unknownUser => 'Utilisateur';
  String get place => 'place';
  String get places => 'places';
  String get backToHome => 'Retour à l\'accueil';
  String get browseShows => 'Voir d\'autres émissions';
  String get reservationSuccessBody =>
      'Votre demande est en cours de traitement. Vous serez contacté pour confirmer votre participation.';
}

/// Profile screen copy in French
class ProfileCopyFr {
  const ProfileCopyFr();

  String get title => 'Mon profil';
  String get languageLabel => 'Langue';
  String get languageValueFr => 'Français';
  String get languageValueAr => 'العربية';
  String get themeLabel => 'Apparence';
  String get themeSystem => 'Système';
  String get themeLight => 'Clair';
  String get themeDark => 'Sombre';
  String get loyaltyLabel => 'Fidélité';
  String get notificationsLabel => 'Notifications';
  String unreadCount(int n) => '$n non lue${n > 1 ? 's' : ''}';
  String get helpLabel => 'Aide';
  String get aboutLabel => 'À propos';
  String get logoutLabel => 'Se déconnecter';

  // Edit profile
  String get editTitle => 'Modifier le profil';
  String get incompleteWarning => 'Complétez votre profil pour pouvoir réserver';
  String get incompleteMessage =>
      'Veuillez renseigner votre prénom, nom, ville, quartier et vérifier votre numéro de téléphone avant de réserver.';
  String get completeProfileButton => 'Compléter mon profil';
  String get firstNameLabel => 'Prénom';
  String get lastNameLabel => 'Nom';
  String get cityLabel => 'Ville';
  String get districtLabel => 'Quartier';
  String get firstNameRequired => 'Veuillez entrer votre prénom';
  String get lastNameRequired => 'Veuillez entrer votre nom';
  String get cityRequired => 'Veuillez sélectionner votre ville';
  String get districtRequired => 'Veuillez sélectionner votre quartier';
  String get saveChanges => 'Enregistrer';
  String get savedSuccess => 'Profil mis à jour';
  String get uploadPhoto => 'Changer la photo';
  String get takePhoto => 'Prendre une photo';
  String get chooseFromGallery => 'Choisir depuis la galerie';
  String get removePhoto => 'Supprimer la photo';
  String get avatarDeletedSuccess => 'Photo de profil supprimée';
  String get addPhotoHint => 'Appuyez pour ajouter une photo (optionnel)';
  String get skipForNow => "Ignorer pour l'instant";
  String get cameraAccessDenied =>
      "Accès à la caméra refusé. Autorisez l'accès dans les réglages.";

  // Phone section
  String get phoneLabel => 'Téléphone';
  String get phoneNumberHint => '6XXXXXXXX';
  String get phoneVerified => 'Numéro vérifié';
  String get phoneNotVerified => 'Numéro non vérifié';
  String get phoneNumberInvalid => 'Veuillez entrer un numéro valide.';
  String get verifyPhoneButton => 'Vérifier mon numéro';
  String get phoneAlreadyUsed => 'Ce numéro est déjà utilisé par un autre compte.';

  // Date of birth
  String get dateOfBirthLabel => 'Date de naissance';
  String get dateOfBirthRequired => 'Veuillez saisir votre date de naissance';

  // Avatar
  String get avatarRequiredHint => 'Photo requise pour compléter le profil';

  // OTP screen
  String get otpScreenTitle => 'Vérification du numéro';
  String otpScreenSubtitle(String maskedPhone) =>
      'Nous avons envoyé un code à $maskedPhone';
  String get otpCodeHint => 'Code à 6 chiffres';
  String get otpCodeRequired => 'Veuillez entrer le code à 6 chiffres.';
  String get otpVerifyButton => 'Vérifier';
  String get otpResendButton => 'Renvoyer le code';
  String otpResendCountdown(int s) => 'Renvoyer dans ${s}s';
  String get otpSentSuccess => 'Code envoyé par SMS.';
  String get otpVerifiedSuccess => 'Numéro vérifié avec succès.';
  String get otpInvalidCode => 'Code invalide ou expiré.';
  String get otpSendFailed => "Impossible d'envoyer le code pour le moment.";
  String get otpVerifyFailed => 'Impossible de vérifier le code pour le moment.';
}

/// Home screen copy in French
class HomeCopyFr {
  const HomeCopyFr();

  String get sectionUpcoming => 'Prochains spectacles';
  String get sectionComingSoon => 'Bientôt disponible';
  String get sectionPopular => 'Les plus demandés';
  String get soldOut => 'Complet';
  String get comingSoonBadge => 'BIENTÔT';
  String get soldOutBadge => 'COMPLET';
  String get dateTbc => 'Date à confirmer';
  String get notificationsTooltip => 'Notifications';
}

/// Show Detail screen copy in French
class ShowDetailCopyFr {
  const ShowDetailCopyFr();

  String get soldOut => 'Complet';
  String availableSeats(int n) =>
      '$n ${n == 1 ? 'place disponible' : 'places disponibles'}';
  String reservations(int reserved, int cap) =>
      '$reserved réservations sur $cap';
  String get about => 'À propos';
  String get seeLess => 'Voir moins';
  String get seeMore => 'Voir plus';
  String get dateLabel => 'Date';
  String get timeLabel => 'Heure';
  String get locationLabel => 'Lieu';
  String get channelLabel => 'Chaîne';
  String get loyaltyPointsLabel => 'Points fidélité';
  String loyaltyPointsValue(int pts) => '+$pts points à la présence';
  String get rulesTitle => 'Règles de participation';
  String get reserveNow => 'Réserver maintenant';
  String get soldOutCta => 'Complet';
}

/// Reserve Seats screen copy in French
class ReserveSeatsCopyFr {
  const ReserveSeatsCopyFr();

  String get title => 'Réserver des places';
  String get soldOutBadge => 'Complet — aucune place disponible';
  String availableSeats(int n) =>
      '$n ${n == 1 ? 'place restante' : 'places restantes'}';
  String get seatsCountLabel => 'Nombre de places';
  String maxHint(int n) => 'Maximum 4 places par réservation · $n restantes';
  String get infoTitle => 'Bon à savoir';
  String get infoBody =>
      'Votre demande sera examinée par notre équipe. Vous recevrez une confirmation par notification une fois approuvée.';
  String get recap => 'Récapitulatif';
  String get confirm => 'Confirmer la réservation';
  String get soldOutCta => 'Complet';
  String get errSoldOut => 'Places complètes. Pas assez de places disponibles.';
  String get errNotEnough => 'Pas assez de places disponibles.';
  String get agreementCheckboxLabel =>
      "J'ai lu et j'accepte les conditions de participation.";
  String get agreementReadRules => 'Lire le règlement';
}

/// Ticket screen copy in French
class TicketCopyFr {
  const TicketCopyFr();

  String get title => 'Mes billets';
  String get loading => 'Chargement de vos billets...';
  String get pendingTitle => 'En attente de confirmation';
  String get pendingDesc =>
      'Vos billets seront disponibles ici une fois vos réservations approuvées par notre équipe.';
  String get showTickets => 'Afficher mes billets';
  String get viewReservations => 'Voir mes réservations';
  String get rulesReminder => 'Rappel des règles';
  String get refresh => 'Rafraîchir';
  String get offlineBanner => 'Mode hors ligne - Dernière version des billets';
  String get countSingle => '1 billet approuvé';
  String countMultiple(int idx, int total) =>
      '${idx + 1} / $total billets approuvés';
  String get swipeHint => 'Glissez pour voir vos autres billets';
  String get ticketUsed => 'Billet utilisé';
  String get ticketValid => 'Billet valide';
  String get checkedInLabel => 'Entrée validée';
  String get usedLabel => 'UTILISÉ';
  String seats(int n) => '$n place${n > 1 ? 's' : ''}';
  String get qrHintValid => 'Présentez ce QR code à l\'entrée';
  String get qrHintUsed => 'Ce billet a déjà été utilisé';
  String codeCopied(String code) => 'Code copié: $code';
  String checkinAt(String date) => 'Check-in le $date';
}

/// Browse screen copy in French
class BrowseCopyFr {
  const BrowseCopyFr();

  String get title => 'Explorer';
  String get filterTooltip => 'Filtres';
  String get noResults => 'Aucun résultat';
  String get noResultsDesc => 'Aucune émission ne correspond à votre recherche.';
  String get clearFilters => 'Effacer les filtres';
  String get searchHint => 'Rechercher une émission...';
  String get allCities => 'Toutes';
  String get filterByChannel => 'Filtrer par chaîne';
  String get noChannels => 'Aucune chaîne disponible';
  String get clearAllFilters => 'Effacer tous les filtres';
  String get soldOutBadge => 'COMPLET';
  String availableSeats(int n) => '$n ${n == 1 ? 'place' : 'places'}';
}

/// Notifications screen copy in French
class NotificationsCopyFr {
  const NotificationsCopyFr();

  String get title => 'Notifications';
  String get markAllRead => 'Tout marquer comme lu';
  String get markAllReadSuccess =>
      'Toutes les notifications marquées comme lues';
  String get deleteAll => 'Tout supprimer';
  String get deleteAllTitle => 'Supprimer toutes les notifications';
  String get deleteAllContent =>
      'Êtes-vous sûr de vouloir supprimer toutes les notifications ? Cette action est irréversible.';
  String get deleteAllConfirm => 'Supprimer';
  String get deleteAllSuccess => 'Toutes les notifications ont été supprimées';
  String get dismissed => 'Notification supprimée';
  String get emptyTitle => 'Aucune notification';
  String get emptyDesc => 'Vous n\'avez pas encore reçu de notification.';
}

/// My Reservations screen copy in French
class MyReservationsCopyFr {
  const MyReservationsCopyFr();

  String get title => 'Mes réservations';

  // Tabs
  String get tabPending => 'En attente';
  String get tabApproved => 'Approuvées';
  String get tabPast => 'Passées';

  // Empty states
  String get emptyPending => 'Aucune réservation en attente';
  String get emptyPendingSubtitle => 'Vos demandes en cours apparaîtront ici';
  String get emptyApproved => 'Aucune réservation approuvée';
  String get emptyApprovedSubtitle => 'Vos réservations confirmées apparaîtront ici';
  String get emptyPast => 'Aucune réservation passée';
  String get emptyPastSubtitle => 'Votre historique apparaîtra ici';

  // Cancel dialog
  String get cancelDialogTitle => 'Annuler la réservation';
  String get cancelDialogContent =>
      'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.';
  String get cancelDialogKeep => 'Non, garder';
  String get cancelDialogConfirm => 'Oui, annuler';

  // Snackbars
  String get cancelSuccess => 'Réservation annulée';
  String get cancelErrorForbidden => 'Vous ne pouvez pas annuler cette réservation.';
  String get cancelErrorConflict => 'Cette réservation ne peut plus être annulée.';
  String get cancelErrorGeneric => 'Une erreur est survenue. Veuillez réessayer.';

  // Card banners
  String get expiredBanner => 'Réservation expirée';
  String get checkedInBanner => 'Entrée validée — Ticket utilisé';

  // Misc
  String get retryLabel => 'Réessayer';
  String seatCount(int n) => '$n ${n == 1 ? 'place' : 'places'}';
}

/// Bottom nav tab labels in French
class NavTabsCopyFr {
  const NavTabsCopyFr();

  String get emissions => 'Émissions';
  String get explorer => 'Explorer';
  String get reservations => 'Réservation';
  String get ticket => 'Billet';
  String get profile => 'Profil';
}

/// A single numbered section in the participation conditions document
class ConditionSection {
  final String title;
  final String body;
  const ConditionSection({required this.title, required this.body});
}

/// Conditions de participation du public — French
class ConditionsCopyFr {
  const ConditionsCopyFr();

  String get title => 'Conditions de participation';
  String get subtitle => 'Autorisation de droit à l\'image et règlement';
  String get profileTileLabel => 'Règlement';
  String get validationTitle => 'Validation et signature électronique';

  List<String> get checkboxItems => const [
        'Je confirme avoir plus de 18 ans et accepter les conditions de participation.',
        'J\'autorise l\'utilisation de mon image, ma voix et ma présence dans les émissions et contenus audiovisuels.',
        'Je m\'engage à respecter la confidentialité du tournage (NDA).',
        'Je reconnais que ma validation électronique vaut signature et acceptation légale des présentes conditions.',
      ];

  List<ConditionSection> get sections => const [
        ConditionSection(
          title: 'Âge minimum',
          body:
              'La participation aux émissions et tournages est réservée aux personnes âgées de 18 ans minimum et 65 ans maximum.\nToute personne inscrite confirme être majeure (18 ans minimum).',
        ),
        ConditionSection(
          title: 'Pièce d\'identité obligatoire',
          body:
              'L\'accès au studio ou au lieu de tournage est soumis à la présentation d\'une pièce d\'identité valide (CIN ou passeport).\nL\'organisateur se réserve le droit de refuser l\'accès en cas d\'absence de pièce d\'identité.',
        ),
        ConditionSection(
          title: 'Autorisation de droit à l\'image',
          body:
              'En participant à un tournage ou événement, le participant autorise expressément et gratuitement l\'organisateur, les producteurs, les chaînes de télévision et leurs partenaires à :\n• filmer, photographier et enregistrer son image, sa voix et sa silhouette,\n• utiliser ces images dans le cadre des émissions, programmes audiovisuels ou contenus promotionnels.\n\nCes images pourront être diffusées sur tous supports : télévision, internet, plateformes numériques, réseaux sociaux et supports promotionnels.\nCette autorisation est accordée pour le monde entier et sans limitation de durée, sans compensation financière.',
        ),
        ConditionSection(
          title: 'Confidentialité (NDA)',
          body:
              'Le participant s\'engage à ne pas divulguer :\n• le contenu de l\'émission\n• les images du tournage\n• les invités ou résultats\n• les informations liées à la production\n\navant la diffusion officielle.\n\nIl est strictement interdit de publier des photos ou vidéos du tournage sur les réseaux sociaux.',
        ),
        ConditionSection(
          title: 'Téléphones et enregistrements',
          body:
              'Pendant le tournage :\n• les téléphones doivent être éteints ou en mode silencieux\n• il est interdit de filmer, photographier ou enregistrer.',
        ),
        ConditionSection(
          title: 'Comportement et respect',
          body:
              'Les participants doivent :\n• respecter l\'équipe de production\n• suivre les instructions des assistants de plateau\n• respecter les autres membres du public.\n\nTout comportement violent ou perturbant peut entraîner l\'exclusion immédiate du studio.',
        ),
        ConditionSection(
          title: 'Bagarres et conflits',
          body:
              'L\'organisateur n\'est pas responsable des bagarres ou conflits entre participants, que ce soit dans le studio ou à l\'extérieur des locaux.',
        ),
        ConditionSection(
          title: 'Objets personnels',
          body:
              'Les participants restent responsables de leurs objets personnels.\nL\'organisateur décline toute responsabilité en cas de :\n• perte\n• vol\n• détérioration.',
        ),
        ConditionSection(
          title: 'Horaires et durée du tournage',
          body:
              'Les horaires communiqués sont indicatifs.\nLes tournages peuvent durer plus longtemps que prévu.\nL\'organisateur ne pourra être tenu responsable des retards de fin de tournage.',
        ),
        ConditionSection(
          title: 'Accès et sécurité',
          body:
              'L\'accès au studio peut être soumis à un contrôle de sécurité.\nL\'organisateur se réserve le droit de refuser l\'accès ou d\'exclure toute personne ne respectant pas les règles.',
        ),
        ConditionSection(
          title: 'Tenue vestimentaire',
          body:
              'Certaines émissions peuvent exiger une tenue vestimentaire spécifique.\nLes vêtements avec logos ou messages inappropriés peuvent être refusés.',
        ),
        ConditionSection(
          title: 'Protection des données',
          body:
              'Les informations collectées dans l\'application sont utilisées uniquement pour :\n• la gestion des inscriptions du public\n• l\'organisation des tournages\n• la communication liée aux événements.',
        ),
        ConditionSection(
          title: 'Droit d\'annulation',
          body:
              'L\'organisateur se réserve le droit de modifier ou annuler la participation d\'un utilisateur pour des raisons organisationnelles ou de sécurité.',
        ),
        ConditionSection(
          title: 'Acceptation des conditions',
          body:
              'Toute inscription via l\'application implique l\'acceptation complète du présent règlement.',
        ),
      ];
}

/// Staff check-in strings in French
class StaffCopyFr {
  const StaffCopyFr();

  String get checkInTitle => 'Check-in billets';
  String get tabScanQr => 'Scanner QR';
  String get tabManualCode => 'Code manuel';
  String get scanInstruction => 'Pointez la caméra sur le QR code du billet';
  String get manualPlaceholder => 'AT-2026-000008';
  String get validateButton => 'Valider le billet';
  String get successTitle => 'Billet validé';
  String get alreadyUsed => 'Billet déjà utilisé';
  String get notFound => 'Billet introuvable';
  String get accessDenied => 'Accès staff requis';
  String get accessDeniedSubtitle =>
      'Vous n\'avez pas les droits pour accéder à cette section.';
  String get sessionExpired => 'Session expirée. Reconnectez-vous.';
  String get networkError =>
      'Impossible de vérifier le billet pour le moment.';
  String get scanAnother => 'Scanner un autre billet';
  String get cameraPermissionDenied => 'Accès caméra refusé';
  String get cameraPermissionSubtitle =>
      'Autorisez l\'accès à la caméra pour scanner les QR codes.';
  String get openSettings => 'Ouvrir les paramètres';
  String get checkedInAt => 'Scanné le';
  String get profileStaffTile => 'Check-in billets';
  String get retry => 'Réessayer';
  String get back => 'Retour';
  String get attendeeName => 'Spectateur';
  String get showLabel => 'Émission';
  String get ticketCodeLabel => 'Code billet';
}

// ─────────────────────────────────────────────────────────────────────────────
// Referral / Parrainage
// ─────────────────────────────────────────────────────────────────────────────
class ReferralCopyFr {
  const ReferralCopyFr();

  String get title => 'Parrainage';
  String get myReferralCode => 'Mon code de parrainage';
  String get copyCode => 'Copier le code';
  String get codeCopied => 'Code copié !';
  String get inviteFriend => 'Inviter un ami';
  String get generateLink => 'Générer un lien';
  String get shareLink => 'Partager le lien';
  String invitesYou(String name) => '$name t\'invite à cette émission';
  String get reserveNow => 'Réserver maintenant';
  String get referralCodeLabel => 'Code de parrainage (optionnel)';
  String get referralCodeHint => 'Entrez le code d\'un ami';
  String get totalInvited => 'Invités';
  String get totalAttended => 'Présents';
  String get pending => 'En attente';
  String get pointsEarned => 'Points gagnés';
  String get myLinks => 'Mes liens de parrainage';
  String get clicks => 'clics';
  String get conversions => 'réservations';
  String get expired => 'Expiré';
  String get linkExpired => 'Ce lien a expiré';
  String get linkInvalid => 'Lien invalide';
  String get showUnavailable => 'Cette émission n\'est plus disponible';
  String shareMessage(String showTitle, String link) =>
      'Rejoins-moi pour assister à $showTitle ! Réserve ta place ici : $link';
  String get noLinksYet => 'Aucun lien partagé';
  String get noReferralsYet => 'Aucun parrainage pour le moment';
  String get inviteFriendsEarnPoints =>
      'Invite tes amis et gagne des points !';
  String get profileTileLabel => 'Parrainage';
  String get statsTitle => 'Mes parrainages';
  String get linksTitle => 'Mes liens';
}

// ─────────────────────────────────────────────────────────────────────────────
// Episodes
// ─────────────────────────────────────────────────────────────────────────────
class EpisodeCopyFr {
  const EpisodeCopyFr();

  String get sectionTitle => 'Épisodes';
  String episodeCount(int n) => '$n épisode${n > 1 ? 's' : ''}';
  String get reserveEpisode => 'Réserver cet épisode';
  String get noUpcomingEpisodes => 'Aucun tournage à venir';
  String get nextEpisode => 'Prochain épisode';
  String get pastEpisode => 'Épisode passé';
  String get allEpisodes => 'Tous les épisodes';
  String get upcomingEpisodes => 'Épisodes à venir';
  String get soldOut => 'Complet';
  String availableSeats(int n) =>
      '$n ${n == 1 ? 'place disponible' : 'places disponibles'}';
}
