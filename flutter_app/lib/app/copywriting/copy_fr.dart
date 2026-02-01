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
  String get soldOut =>
      'Ce spectacle est complet. Aucune place disponible.';
  String get unknownError =>
      'Une erreur inattendue est survenue. Veuillez réessayer.';
  String get invalidCredentials =>
      'Email ou mot de passe incorrect.';
  String get emailAlreadyExists =>
      'Un compte avec cet email existe déjà.';
  String get validationError =>
      'Veuillez vérifier les informations saisies.';
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

  String get acceptance =>
      'J\'ai lu et j\'accepte le règlement du spectacle.';
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
