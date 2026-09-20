import 'package:aji_tfarraj/app/copywriting/casting_copy.dart';
import 'package:aji_tfarraj/app/copywriting/departure_copy.dart';

export 'package:aji_tfarraj/app/copywriting/casting_copy.dart';

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
  static const departures = DepartureCopyFr();
  static const casting = CastingCopyFr();

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
  // How it works / Comment ça marche
  // ============================================
  static const howItWorks = HowItWorksCopyFr();
  static const onSite = OnSiteCopyFr();

  // ============================================
  // Charge public ("Mode Chargé Public")
  // ============================================
  static const chargePublic = ChargePublicCopyFr();

  // ============================================
  // Episodes
  // ============================================
  static const episode = EpisodeCopyFr();

  // ============================================
  // Reservation Result / Confirmation screen
  // ============================================
  static const reservationResult = ReservationResultCopyFr();

  // ============================================
  // Reservation Detail screen
  // ============================================
  static const reservationDetail = ReservationDetailCopyFr();

  // ============================================
  // Support Tickets
  // ============================================
  static const support = SupportCopyFr();

  // ============================================
  // App gate (update prompt + biometric lock)
  // ============================================
  static const appGate = AppGateCopyFr();
}

/// Update-prompt + biometric-lock copy in French
class AppGateCopyFr {
  const AppGateCopyFr();

  // Update prompt
  String get updateTitle => 'Mise à jour disponible';
  String get updateMessage =>
      'Une nouvelle version d\'Aji Tfarraj est disponible. Mettez à jour pour profiter des dernières améliorations.';
  String get updateForcedTitle => 'Mise à jour requise';
  String get updateForcedMessage =>
      'Cette version n\'est plus prise en charge. Veuillez mettre à jour pour continuer à utiliser l\'application.';
  String get updateNow => 'Mettre à jour';
  String get updateLater => 'Plus tard';

  // Biometric lock
  String get biometricLockLabel => 'Verrouillage biométrique';
  String get biometricLockSubtitle => 'Face ID / empreinte à l\'ouverture';
  String get biometricUnlockTitle => 'Application verrouillée';
  String get biometricUnlockSubtitle =>
      'Authentifiez-vous pour accéder à vos billets et à votre profil.';
  String get biometricUnlockButton => 'Déverrouiller';
  String get biometricReason => 'Confirmez votre identité pour déverrouiller Aji Tfarraj';
  String get biometricUnavailable =>
      'Aucune méthode biométrique n\'est configurée sur cet appareil.';
  String get biometricEnableFailed =>
      'Impossible d\'activer le verrouillage. Réessayez.';
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
              'L\'accès au spectacle est réservé aux personnes âgées de 18 ans et plus.',
        ),
        RuleItem(
          title: 'Vérification d\'identité',
          description:
              'Veuillez présenter votre propre pièce d\'identité et joindre une photocopie de votre CIN.',
        ),
        RuleItem(
          title: 'Tenue vestimentaire',
          description:
              'L\'accès est refusé à toute personne portant une tenue inappropriée ou comportant des logos commerciaux ou publicitaires.',
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
  String get back => 'Retour';
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
  String get groupPreferences => 'Préférences';
  String get groupAccount => 'Compte';
  String get groupSettings => 'Paramètres';
  String get helpLabel => 'Aide';
  String get aboutLabel => 'À propos';
  String get logoutLabel => 'Se déconnecter';

  // Edit profile
  String get editTitle => 'Modifier le profil';
  String get editSectionPersonal => 'Informations personnelles';
  String get editSectionLocation => 'Localisation';
  String get editSectionContact => 'Contact';
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
  String get permissionNeededTitle => 'Autorisation requise';
  String get cameraPermissionMessage =>
      "Pour prendre votre photo de profil, autorisez l'accès à la caméra dans "
      'les réglages.';
  String get openSettings => 'Ouvrir les réglages';
  String get profileStillIncomplete =>
      'Certaines informations obligatoires sont encore manquantes. '
      'Veuillez vérifier le formulaire avant de continuer.';

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

  // Gender
  String get genderLabel => 'Genre';
  String get genderMale => 'Homme';
  String get genderFemale => 'Femme';
  String get genderRequired => 'Veuillez sélectionner votre genre';

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

/// A single step in a "Comment ça marche" tutorial track.
class HowToStep {
  final String title;
  final String body;
  const HowToStep({required this.title, required this.body});
}

/// Inscription sur place (porte du studio) — French
class OnSiteCopyFr {
  const OnSiteCopyFr();

  String get title => 'Inscription sur place';
  String get subtitle =>
      'Ouvre un compte et pointe la personne qui se présente sans réservation.';
  String get profileTileSubtitle => 'Inscrire quelqu\'un à la porte';

  // Session (choisie une fois, gardée pour les inscriptions suivantes)
  String get sessionTitle => 'Session';
  String get chooseShow => 'Choisis l\'émission';
  String get chooseEpisode => 'Choisis l\'épisode';
  String get chooseChargePublic => 'Chargé public (optionnel)';
  String get noChargePublic => 'Personne / venu seul';
  String get searchChargePublic => 'Rechercher un chargé public';
  String get changeSession => 'Changer';
  String get startSession => 'Commencer';
  String get noEpisodes =>
      'Aucun épisode ouvert à l\'inscription pour le moment.';
  String registeredCount(int n) => n <= 1 ? '$n inscrit' : '$n inscrits';

  // Étapes
  String get stepPhoto => 'Photo';
  String get stepIdentity => 'Identité';
  String get stepLocation => 'Localisation';
  String stepCounter(int current, int total) => 'Étape $current / $total';

  // Photo
  String get takePhoto => 'Prendre la photo';
  String get retakePhoto => 'Reprendre';
  String get photoHint =>
      'Photo du visage, prise à la porte. Elle sert à reconnaître la personne les prochaines fois.';
  String get photoRequired => 'La photo est obligatoire.';

  // Identité
  String get firstName => 'Prénom';
  String get lastName => 'Nom';
  String get gender => 'Sexe';
  String get male => 'Homme';
  String get female => 'Femme';
  String get birthday => 'Date de naissance';
  String get phone => 'Téléphone (optionnel)';
  String get email => 'E-mail (optionnel)';
  String get emailHint =>
      'Laisse vide : un identifiant sera généré automatiquement.';

  // Localisation
  String get city => 'Ville';
  String get district => 'Secteur';

  // Actions
  String get next => 'Suivant';
  String get back => 'Retour';
  String get submit => 'Inscrire et pointer';
  String get nextPerson => 'Personne suivante';
  String get close => 'Terminer';

  // Résultat
  String get doneTitle => 'Inscrit et pointé';
  String doneSubtitle(String name) => '$name est enregistré et déjà pointé.';
  String get credentials => 'Identifiants à communiquer';
  String get credentialsHint =>
      'Note-les ou dicte-les maintenant : le mot de passe ne sera plus affiché.';
  String get copyCredentials => 'Copier';
  String get copied => 'Copié';
  String rewardEarned(int amount) => 'Commission chargé public : $amount DH';

  // Erreurs
  String get requiredFields => 'Remplis tous les champs obligatoires.';
  String get genericError => 'Inscription impossible. Réessaye.';
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
        ConditionSection(
          title: 'Réseaux sociaux (facultatif)',
          body:
              'Vous pouvez indiquer vos comptes Instagram, TikTok, Snapchat et Facebook dans votre profil. Ils servent uniquement à vous proposer des collaborations et des castings. Notre équipe peut consulter ces profils publics pour estimer votre audience ; cette estimation reste interne et n\'est jamais publiée. Ces informations sont facultatives, n\'ont aucun effet sur vos réservations, et vous pouvez les modifier ou les supprimer à tout moment depuis votre profil.',
        ),
      ];
}


/// Casting strings in French.
class CastingCopyFr implements CastingCopy {
  const CastingCopyFr();

  String get title => 'Casting';
  String get subtitle => 'Votre book et les annonces ouvertes';

  // ── Le book ──
  String get bookTitle => 'Mon book';
  String get bookIntro =>
      'Cinq photos, toujours les mêmes poses. C\'est ce qui permet de vous comparer équitablement : sans poses communes, on choisit le meilleur photographe, pas la bonne personne.';
  String get bookHelper => 'Faites-vous photographier par quelqu\'un d\'autre.';
  String get bookRequired => 'Obligatoire';
  String get bookOptional => 'Facultatif';
  String get bookComplete => 'Book complet';
  String get bookMissing => 'Il manque %d photo(s)';
  String get bookRetake => 'Reprendre';
  String get bookDelete => 'Supprimer';
  String get bookTake => 'Prendre la photo';

  // ── Avant de photographier ──
  String get rulesTitle => 'Avant de commencer';
  List<String> get rules => const [
        'Un mur uni et clair derrière vous, rien qui traîne.',
        'À la lumière du jour, face à une fenêtre — jamais à contre-jour.',
        'Vêtements ajustés et unis : on doit voir votre silhouette.',
        'Pas de lunettes de soleil, pas de casquette, cheveux dégagés du visage.',
        'Aucun filtre, aucune retouche.',
        'La personne qui photographie tient le téléphone à hauteur de votre poitrine.',
      ];

  // ── Les poses ──
  CastingPoseCopy get fullFront => const CastingPoseCopy(
        label: 'Plein pied — de face',
        hint: 'Debout, de face, bras le long du corps',
        steps: [
          'Reculez jusqu\'à ce que vous teniez entièrement dans le cadre, de la tête aux pieds.',
          'Debout bien droit, pieds légèrement écartés.',
          'Bras détendus le long du corps, mains visibles.',
          'Regardez l\'objectif, visage neutre — ne souriez pas.',
        ],
      );

  CastingPoseCopy get fullProfile => const CastingPoseCopy(
        label: 'Plein pied — de profil',
        hint: 'Tournez-vous complètement sur le côté',
        steps: [
          'Tournez-vous d\'un quart de tour : une épaule vers l\'objectif.',
          'Restez droit, bras le long du corps.',
          'Regardez droit devant vous, pas vers l\'objectif.',
          'Toujours de la tête aux pieds dans le cadre.',
        ],
      );

  CastingPoseCopy get portrait => const CastingPoseCopy(
        label: 'Portrait',
        hint: 'Visage et épaules, expression neutre',
        steps: [
          'Cadrez de la tête au haut de la poitrine.',
          'Face à l\'objectif, épaules droites.',
          'Visage neutre, bouche fermée, regard vers l\'objectif.',
          'Dégagez les cheveux du visage.',
        ],
      );

  CastingPoseCopy get fullBack => const CastingPoseCopy(
        label: 'Plein pied — de dos',
        hint: 'Tournez le dos à l\'objectif',
        steps: [
          'Tournez complètement le dos à l\'objectif.',
          'Debout droit, bras le long du corps.',
          'De la tête aux pieds dans le cadre.',
        ],
      );

  CastingPoseCopy get portraitSmile => const CastingPoseCopy(
        label: 'Portrait souriant',
        hint: 'Même cadrage, sourire naturel',
        steps: [
          'Même cadrage que le portrait : tête et haut de la poitrine.',
          'Regardez l\'objectif et souriez naturellement.',
        ],
      );

  // ── Mensurations ──
  String get measurementsTitle => 'Mensurations';
  String get measurementsIntro =>
      'Facultatif pour postuler, mais c\'est ce sur quoi les annonces filtrent.';
  String get height => 'Taille (cm)';
  String get weight => 'Poids (kg)';
  String get clothingSize => 'Taille de vêtement';
  String get shoeSize => 'Pointure';
  String get save => 'Enregistrer';
  String get saved => 'Enregistré';

  // ── Annonces ──
  String get tabCastings => 'Castings';
  String get tabPublications => 'Publicités';
  String get noCastings => 'Aucune annonce pour le moment';
  String get noCastingsSubtitle =>
      'Les nouvelles annonces apparaîtront ici. Préparez votre book en attendant.';
  String get closesAt => 'Clôture le';
  String get apply => 'Postuler';
  String get applied => 'Candidature envoyée';
  String get applyBlocked => 'Complétez votre book pour postuler';
  String get applyNote => 'Message (facultatif)';
  String get applyNoteHint => 'Une expérience, une disponibilité particulière…';
  String get applySent => 'Votre candidature a été envoyée.';
  String get applyError => 'Impossible d\'envoyer la candidature.';

  // ── Candidatures ──
  String get myApplications => 'Mes candidatures';
  String get noApplications => 'Aucune candidature';
  String get noApplicationsSubtitle =>
      'Postulez à une annonce et vous la retrouverez ici.';
  String get withdraw => 'Retirer';
  String get withdrawConfirm => 'Retirer cette candidature ?';
  String get withdrawn => 'Candidature retirée.';
  String get statusPending => 'En attente';
  String get statusShortlisted => 'Présélectionné';
  String get statusAccepted => 'Retenu';
  String get statusRejected => 'Non retenu';
  String get statusUnknown => 'En cours';

  // ── Accès ──
  String get adultsOnly => 'Le casting est réservé aux personnes majeures.';
  String get birthdayRequired =>
      'Renseignez votre date de naissance pour accéder au casting.';
  String get completeProfile => 'Compléter mon profil';
  String get loadError => 'Impossible de charger le casting.';
  String get photoError => 'Impossible d\'envoyer la photo.';
  String get profileTile => 'Espace Casting';
  String get profileTileSubtitle => 'Découvrez les offres et postulez';

  // ── Ouvrir une annonce ──
  String get infoTitle => 'Le casting';
  String get infoDate => 'Date';
  String get infoLocation => 'Lieu';
  String get infoCompensation => 'Rémunération';
  String get aboutTitle => 'À propos';
  String get callRulesTitle => 'Règles';
  String get detailsLoadError => 'Impossible de charger les détails.';

  // ── Vérifier une photo casting ──
  String get poseNoPerson => 'Personne n\'est visible sur la photo.';
  String get poseHeadCut => 'La tête semble coupée : reculez un peu.';
  String get poseFeetCut => 'On ne voit pas les pieds : reculez jusqu\'à ce qu\'ils soient dans le cadre.';
  String get poseNotFacing => 'Vous ne semblez pas de face : mettez-vous bien face à l\'objectif.';
  String get poseNotSideways => 'Vous ne semblez pas de profil : tournez-vous complètement sur le côté.';
  String get portraitNotSmiling => 'Souriez franchement pour cette photo.';
  String get adviceTitle => 'Cette photo n\'est peut-être pas conforme';
  String get adviceKeep => 'Garder quand même';

  // ── Vérifié en studio ──
  String get studioVerifiedTitle => 'Book vérifié en studio';
  String studioVerifiedOn(String date) => 'Photographié par notre équipe le $date';
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

  /// Second step of the door flow: the scanner has looked, now admits.
  String get validateEntry => "Valider l'entrée";

  // ── Retour en navette après le tournage ──
  String get returnPointTitle => 'Retour après le tournage';
  String get returnPointQuestion => 'Où déposer cette personne ?';
  String get returnPointNone => 'Repart par ses propres moyens';
  String get returnPointSaveError => "Impossible d'enregistrer le point.";

  // ── Feuille de retour : combien de monde à chaque arrêt ──
  String get manifestTitle => 'Feuille de retour';
  String get manifestSubtitle => 'Qui attend la navette, et où';
  String get manifestPickEpisode => 'Quel tournage ?';
  String get manifestNoEpisodes => 'Aucun tournage ce soir';
  String get manifestNoEpisodesSubtitle =>
      'La feuille se remplit pendant le pointage à la porte.';
  String get manifestNoShuttle => 'Pas de navette ce soir';
  String get manifestNoShuttleSubtitle =>
      'Aucun point de retour n\'est activé pour ce tournage.';
  String get manifestNobody => 'Personne n\'attend la navette';
  String get manifestNobodySubtitle =>
      'Les arrêts se remplissent au fur et à mesure des entrées.';
  String get manifestPeopleIn => 'personnes entrées';
  String get manifestWaiting => 'attendent la navette';
  String get manifestOwnMeans => 'repartent seules';
  String get manifestPeople => 'pers.';
  String get manifestEmptyStop => 'personne';
  String get manifestOffList => 'hors liste de ce tournage';
  String get manifestOrphanWarning =>
      'Un arrêt a été retiré après que des personnes l\'aient choisi. Elles attendent quand même.';
  String get manifestShare => 'Envoyer au transport';
  String get manifestSharePdf => 'Envoyer le PDF';
  String get manifestShareText => 'Envoyer en message';
  String get manifestShareError => 'Impossible de préparer la feuille.';
  String get manifestRefresh => 'Actualiser';
  String get manifestLoadError => 'Impossible de charger la feuille.';
  String get manifestGeneratedAt => 'Établie le';
  String get profileManifestTile => 'Feuille de retour';
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
  String episodeShareMessage(
          String showTitle, String episodeLabel, String dateStr, String link) =>
      'Rejoins-moi à « $showTitle » — $episodeLabel ($dateStr) ! '
      'Réserve ta place gratuitement ici : $link';
  String get noLinksYet => 'Aucun lien partagé';
  String get noReferralsYet => 'Aucun parrainage pour le moment';
  String get inviteFriendsEarnPoints =>
      'Invite tes amis et gagne des points !';
  String get profileTileLabel => 'Parrainage';
  String get statsTitle => 'Mes parrainages';
  String get linksTitle => 'Mes liens';
}

// ─────────────────────────────────────────────────────────────────────────────
// How it works / Comment ça marche
// ─────────────────────────────────────────────────────────────────────────────
class HowItWorksCopyFr {
  const HowItWorksCopyFr();

  String get title => 'Comment ça marche';

  // Profile entry point
  String get profileTileLabel => 'Comment ça marche';
  String get profileTileSubtitle => 'Guide d\'utilisation de l\'application';

  // Track selector
  String get trackClient => 'Pour les spectateurs';
  String get trackParrain => 'Pour les parrains';

  // Actions
  String get watchVideo => 'Regarder la vidéo';
  String get gotIt => 'J\'ai compris';
  String get next => 'Suivant';
  String stepCounter(int current, int total) => 'Étape $current / $total';

  // Client track — how to use the app
  String get clientHeadline => 'Réserve ta place en 5 étapes';
  String get clientSubtitle =>
      'Assiste gratuitement à l\'enregistrement de tes émissions préférées.';
  List<HowToStep> get clientSteps => const [
        HowToStep(
          title: 'Explore les émissions',
          body:
              'Parcours les tournages TV disponibles et trouve l\'émission qui te plaît.',
        ),
        HowToStep(
          title: 'Choisis tes places',
          body:
              'Ouvre une émission et réserve jusqu\'à 4 places, gratuitement.',
        ),
        HowToStep(
          title: 'Attends la validation',
          body:
              'Notre équipe te contacte pour confirmer ta présence. Tu reçois une notification à chaque étape.',
        ),
        HowToStep(
          title: 'Reçois ton billet',
          body:
              'Une fois approuvé, ton billet avec QR code apparaît dans l\'application.',
        ),
        HowToStep(
          title: 'Présente-toi au tournage',
          body:
              'Montre ton QR code à l\'entrée le jour J et profite du spectacle !',
        ),
      ];

  // Parrain track — how to refer and earn
  String get parrainHeadline => 'Invite, partage et gagne';
  String get parrainSubtitle =>
      'Partage tes liens, remplis les studios et sois rémunéré pour chaque invité présent.';
  List<HowToStep> get parrainSteps => const [
        HowToStep(
          title: 'Récupère ton lien',
          body:
              'Ouvre une émission et génère ton lien de parrainage personnalisé depuis le bouton Partager.',
        ),
        HowToStep(
          title: 'Partage avec tes contacts',
          body:
              'Envoie le lien par WhatsApp, SMS ou sur les réseaux sociaux à un maximum de personnes.',
        ),
        HowToStep(
          title: 'Ils réservent leur place',
          body:
              'Chaque personne qui réserve via ton lien est automatiquement rattachée à ton compte.',
        ),
        HowToStep(
          title: 'Suis tes résultats en direct',
          body:
              'Consulte les clics et les réservations de chaque lien dans « Mes parrainages ».',
        ),
        HowToStep(
          title: 'Gagne ta rémunération',
          body:
              'Tu es payé pour chaque invité réellement présent au tournage. Plus tu remplis, plus tu gagnes.',
        ),
      ];

  /// Video URLs — null until the tutorial clips are produced/hosted.
  /// When set, a "Regarder la vidéo" button appears at the top of the track.
  String? get parrainVideoUrl => null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Charge public ("Mode Chargé Public") — shared FR/AR contract
// ─────────────────────────────────────────────────────────────────────────────

/// Localized copy for the "Mode Chargé Public" space. FR/AR implementations
/// share this contract so `AppStrings.cp` can return one type.
abstract class ChargePublicCopy {
  const ChargePublicCopy();

  String get spaceSubtitle;
  String get modePublic;
  String get roleFallbackName;
  String get modeCardTitle;
  String get modeCardSubtitle;

  String get tabHome;
  String get tabShare;
  String get tabGuests;
  String get tabEarnings;

  String get navHome;
  String get navShare;
  String get navGuests;
  String get navEarnings;

  String get greetingMorning;
  String get greetingEvening;

  String get balanceTitle;
  String money(int v);
  String earnedShort(int v);
  String paidShort(int v);

  String get kpiBrought;
  String get kpiAttended;
  String get kpiPending;
  String get kpiPoints;

  String get earningsByShow;

  /// The per-episode sheet opened by tapping a show in "Gains par émission".
  String get episodeTotal;
  String get episodeUndated;
  String episodeCount(int n);

  /// Under the sheet header: episodes open to show who came.
  String get episodeTapHint;
  String get recentGuests;
  String get myReferred;
  String get seeAll;
  String get retry;

  String get noGuests;
  String get detailSoon;
  String filterAll(int n);
  String filterAttended(int n);
  String filterApproved(int n);
  String filterPending(int n);
  String filterCancelled(int n);

  String get statusPresent;
  String get statusApproved;
  String get statusContacting;
  String get statusRejected;
  String get statusCancelled;
  String get statusExpired;
  String get statusPending;

  /// A guest who did not come to a recording that has already happened.
  String get statusAbsent;

  String visitsCount(int n);
  String gain(int v);
  String get totalEarned;
  String get alreadyPaid;
  String get paymentHistory;
  String get payment;
  String invitedAttended(int inv, int att);

  String get noUpcoming;
  String get shareHeader;
  String get soldOut;
  String seatsCount(int n);
  String get shareBtn;
}

class ChargePublicCopyFr extends ChargePublicCopy {
  const ChargePublicCopyFr();

  @override
  String get spaceSubtitle => 'Espace Chargé public';
  @override
  String get modePublic => 'Mode public';
  @override
  String get roleFallbackName => 'Chargé public';
  @override
  String get modeCardTitle => 'Mode Chargé public';
  @override
  String get modeCardSubtitle => 'Voir mes invités et mes gains';

  @override
  String get tabHome => 'Mon espace';
  @override
  String get tabShare => 'Partager';
  @override
  String get tabGuests => 'Mes invités';
  @override
  String get tabEarnings => 'Mes gains';

  @override
  String get navHome => 'Accueil';
  @override
  String get navShare => 'Partager';
  @override
  String get navGuests => 'Invités';
  @override
  String get navEarnings => 'Gains';

  @override
  String get greetingMorning => 'Bonjour';
  @override
  String get greetingEvening => 'Bonsoir';

  @override
  String get balanceTitle => 'Solde à recevoir';
  @override
  String money(int v) => '$v DH';
  @override
  String earnedShort(int v) => 'Gagné $v DH';
  @override
  String paidShort(int v) => 'Payé $v DH';

  @override
  String get kpiBrought => 'Personnes ramenées';
  @override
  String get kpiAttended => 'Ont assisté';
  @override
  String get kpiPending => 'En attente';
  @override
  String get kpiPoints => 'Mes points';

  @override
  String get earningsByShow => 'Gains par émission';
  @override
  String get episodeTotal => 'Total';
  @override
  String get episodeUndated => 'Date non précisée';
  @override
  String episodeCount(int n) => n == 1 ? '1 épisode' : '$n épisodes';
  @override
  String get episodeTapHint => 'Touchez un épisode pour voir qui est venu.';
  @override
  String get recentGuests => 'Invités récents';
  @override
  String get myReferred => 'Mes filleuls';
  @override
  String get seeAll => 'Tout voir';
  @override
  String get retry => 'Réessayer';

  @override
  String get noGuests => 'Aucun invité pour le moment';
  @override
  String get detailSoon => 'Liste détaillée bientôt disponible.';
  @override
  String filterAll(int n) => 'Tous ($n)';
  @override
  String filterAttended(int n) => 'Présents ($n)';
  @override
  String filterApproved(int n) => 'Approuvés ($n)';
  @override
  String filterPending(int n) => 'En attente ($n)';
  @override
  String filterCancelled(int n) => 'Annulés ($n)';

  @override
  String get statusPresent => 'Présent';
  @override
  String get statusApproved => 'Approuvée';
  @override
  String get statusContacting => 'En contact';
  @override
  String get statusRejected => 'Rejetée';
  @override
  String get statusCancelled => 'Annulée';
  @override
  String get statusExpired => 'Expirée';
  @override
  String get statusPending => 'En attente';
  @override
  String get statusAbsent => 'Absent';

  @override
  String visitsCount(int n) => '$n présence${n > 1 ? 's' : ''}';
  @override
  String gain(int v) => '+$v DH';
  @override
  String get totalEarned => 'Total gagné';
  @override
  String get alreadyPaid => 'Déjà payé';
  @override
  String get paymentHistory => 'Historique des paiements';
  @override
  String get payment => 'Paiement';
  @override
  String invitedAttended(int inv, int att) => '$inv invités · $att présents';

  @override
  String get noUpcoming => 'Aucune émission à venir';
  @override
  String get shareHeader =>
      'Partage une émission pour inviter tes contacts et gagner à chaque présence.';
  @override
  String get soldOut => 'Complet';
  @override
  String seatsCount(int n) => '$n places';
  @override
  String get shareBtn => 'Partager';
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

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Result / Confirmation screen
// ─────────────────────────────────────────────────────────────────────────────
class ReservationResultCopyFr {
  const ReservationResultCopyFr();

  String get title => 'Réservation envoyée';
  String get statusBadge => 'En attente de validation';
  String get summaryShowLabel => 'Spectacle';
  String get summaryNumberLabel => 'Numéro de réservation';
  String get summarySeatsLabel => 'Places réservées';
  String get summaryDateLabel => 'Date du spectacle';
  String get summaryExpiresLabel => 'Expire le';
  String seats(int n) => '$n ${n == 1 ? 'place' : 'places'}';
  String get nextStepsTitle => 'Prochaines étapes';
  String get step1 => 'Votre demande est en cours de traitement.';
  String get step2 =>
      'Notre équipe vous contactera pour confirmer votre réservation.';
  String get step3 =>
      'Une fois approuvée, vous recevrez votre billet électronique.';
  String get ctaMyReservations => 'Voir mes réservations';
  String get ctaHome => "Retour à l'accueil";
}

// ─────────────────────────────────────────────────────────────────────────────
// Reservation Detail screen
// ─────────────────────────────────────────────────────────────────────────────
class ReservationDetailCopyFr {
  const ReservationDetailCopyFr();

  String get appBarTitle => 'Ma réservation';

  // Status messages
  String get msgPending =>
      'Votre demande est en cours de traitement. Vous serez notifié une fois approuvée.';
  String get msgApproved =>
      'Votre réservation est confirmée ! Consultez votre billet ci-dessous.';
  String get msgRejected =>
      'Votre demande a été refusée. Vous pouvez en faire une nouvelle.';
  String get msgCheckedIn => 'Vous avez assisté à cette émission. Merci !';
  String get msgCancelled => 'Vous avez annulé cette réservation.';
  String get msgExpired =>
      'Cette réservation a expiré. Vous pouvez réserver une autre émission.';

  // Section labels
  String get sectionShow => 'Émission';
  String get sectionDetails => 'Détails de la réservation';

  // Detail row labels
  String get labelNumber => 'Numéro de réservation';
  String get labelSeats => 'Nombre de places';
  String get labelCreatedAt => 'Date de réservation';
  String get labelExpiresAt => 'Expire le';
  String get labelExpiredAt => 'Expirée le';
  String seats(int n) => '$n place${n > 1 ? 's' : ''}';

  // Alert boxes
  String get alertRejectionTitle => 'Raison du refus';
  String get alertExpiredTitle => 'Réservation expirée';
  String get alertExpiredBody =>
      "Cette réservation a expiré car elle n'a pas été confirmée à temps. Vous pouvez faire une nouvelle réservation.";
  String get alertCheckedInTitle => 'Entrée validée';
  String get alertCheckedInBody =>
      "Votre billet a été utilisé pour accéder à l'émission. Merci de votre participation !";

  // Action buttons
  String get btnViewTicket => 'Voir mon billet';
  String get btnViewUsedTicket => 'Voir le billet utilisé';
  String get btnDiscoverShows => 'Découvrir les émissions';
  String get btnCancelReservation => 'Annuler la réservation';

  // Cancel dialog
  String get cancelDialogTitle => 'Annuler la réservation ?';
  String get cancelDialogBody =>
      'Cette action est irréversible. Votre place sera libérée.';
  String get cancelDialogBack => 'Retour';
  String get cancelDialogConfirm => 'Confirmer';

  // Snackbar
  String get cancelSuccess => 'Réservation annulée';
  String get copiedLabel => 'Copié !';

  // Error view
  String get retry => 'Réessayer';
}

/// Support Tickets copy in French
class SupportCopyFr {
  const SupportCopyFr();

  // App bar titles
  String get listTitle => 'Support / Aide';
  String get createTitle => 'Nouveau ticket';
  String get newButton => 'Nouveau';

  // Status badges
  String get statusOpen => 'En attente';
  String get statusInProgress => 'En cours';
  String get statusClosed => 'Résolu';

  // Status banner titles & messages
  String get bannerOpenTitle => 'En attente';
  String get bannerOpenMsg =>
      'Votre demande est en file d\'attente.\nNotre équipe vous contactera bientôt.';
  String get bannerInProgressTitle => 'En cours de traitement';
  String get bannerInProgressMsg =>
      'Un agent s\'occupe de votre demande.\nVous serez contacté par téléphone.';
  String get bannerClosedTitle => 'Résolu';
  String get bannerClosedMsg =>
      'Ce ticket a été traité et clôturé.\nMerci de nous avoir contactés.';

  // Card
  String get cardSubtitle => 'Notre équipe vous contactera par téléphone.';

  // Empty state
  String get emptyTitle => 'Aucun ticket';
  String get emptySubtitle =>
      'Vous n\'avez pas encore contacté\nnotre support.';
  String get emptyButton => 'Créer un ticket';

  // Error state
  String get errorMsg => 'Impossible de charger vos tickets.';
  String get retryButton => 'Réessayer';

  // Create screen
  String get infoBannerTitle => 'Bon à savoir';
  String get infoBannerBody =>
      'Notre équipe vous rappellera au numéro associé à votre compte. '
      'Décrivez votre problème en détail pour accélérer le traitement.';
  String get subjectLabel => 'Sujet *';
  String get subjectHint => 'Ex: Problème avec ma réservation...';
  String get subjectRequired => 'Le sujet est requis';
  String get messageLabel => 'Description *';
  String get messageHint =>
      'Décrivez votre problème en détail...\nMentionnez le numéro de réservation si applicable.';
  String get submitButton => 'Envoyer ma demande';

  // Confirmation screen
  String get confirmationTitle => 'Demande envoyée !';
  String get confirmationBadge => 'En attente de traitement';
  String get summarySubject => 'Sujet';
  String get summaryTicket => 'Ticket';
  String get summarySubmitted => 'Soumis le';
  String get stepsTitle => 'Prochaines étapes';
  String get step1 => 'Votre demande a bien été reçue.';
  String get step2 => 'Un agent vous rappellera sous 24–48h.';
  String get step3 => 'Le ticket sera clôturé une fois résolu.';
  String get btnViewTickets => 'Voir mes tickets';
  String get btnBackHome => 'Retour à l\'accueil';

  // Detail screen
  String get detailSubjectSection => 'Sujet';
  String get detailMessageSection => 'Votre message';
  String get detailMetaSection => 'Détails';
  String get metaTicketNumber => 'Numéro de ticket';
  String get metaSubmittedAt => 'Date de soumission';
  String get metaUpdatedAt => 'Dernière mise à jour';
  String get infoCallPending =>
      'Vous recevrez un appel de notre équipe.\nAssurez-vous que votre numéro est à jour.';
  String get infoClosed => 'Ce ticket est clôturé.';
  String get detailError => 'Erreur de chargement';
  String get detailForbidden => 'Accès non autorisé';
  String get detailRetry => 'Réessayer';

  // Profile entry point
  String get profileTitle => 'Support / Aide';
  String get profileSubtitle => 'Contactez notre équipe';
}

/// "Présents" and departures, in French.
class DepartureCopyFr implements DepartureCopy {
  const DepartureCopyFr();

  String get tile => 'Présents';
  String get tileSubtitle => 'Qui est dans la salle, qui est parti';

  String get title => 'Présents';
  String get refresh => 'Actualiser';
  String get loadError => 'Impossible de charger la liste des présents.';
  String get searchHint => 'Nom ou code billet';
  String counts(int present, int left) =>
      '$present présent${present > 1 ? 's' : ''} · $left sortie${left > 1 ? 's' : ''}';
  String get empty => "Personne n'a encore été pointé";
  String get emptySubtitle => "Les personnes scannées à l'entrée apparaîtront ici.";
  String get noMatch => 'Personne ne correspond à cette recherche.';
  String get walkIn => 'Sans compte';
  String broughtBy(String name) => 'Chargé public : $name';
  String checkedInAt(String time) => 'Entrée $time';
  String leftAt(String time) => 'Sortie $time';
  String excludedBefore(int count) =>
      count > 1 ? '$count exclusions précédentes' : 'Exclusion précédente';

  String reason(String key) => switch (key) {
        'left' => 'Départ volontaire',
        'unwell' => 'Malaise / santé',
        'excluded' => 'Exclusion : comportement',
        'other' => 'Autre',
        _ => 'Raison inconnue',
      };

  String get sheetTitle => 'Signaler une sortie';
  String get reasonQuestion => 'Raison de la sortie';
  String get noteLabel => 'Note';
  String get noteHintOptional => "Facultatif : ce qui s'est passé";
  String get noteRequired => 'Obligatoire : précisez la raison';
  String get consequence =>
      'Les points de cette émission lui seront retirés, et son chargé public ne sera pas payé pour cette venue.';
  String get consequenceWalkIn =>
      'Son chargé public ne sera pas payé pour cette venue.';
  String get exclusionNote =>
      "Une exclusion reste visible par l'équipe à ses prochaines venues.";
  String get confirm => 'Confirmer la sortie';
  String get cancel => 'Annuler';
  String get recorded => 'Sortie enregistrée';
  String get saveError => "La sortie n'a pas pu être enregistrée. Réessayez.";

  String recordedBy(String name) => 'Notée par $name';
  String get undo => 'Annuler la sortie';
  String get undoConfirmTitle => 'Annuler cette sortie ?';
  String get undoConfirmBody =>
      'À utiliser si la sortie a été notée sur la mauvaise personne : ses points et la part de son chargé public lui sont rendus.';
  String get undone => 'Sortie annulée';

  String doorExcludedBefore(int count, String? date, String? show) =>
      '${count > 1 ? '$count exclusions précédentes' : 'Exclusion précédente'}'
      '${date != null ? ' — le $date' : ''}'
      '${show != null && show.isNotEmpty ? ' ($show)' : ''}';
  String doorAlreadyLeft(String time, String reason) => 'Sortie à $time · $reason';
}
