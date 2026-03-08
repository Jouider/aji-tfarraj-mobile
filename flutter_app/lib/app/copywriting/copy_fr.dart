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
