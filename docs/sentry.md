# Sentry (app)

Initialisé dans `main.dart` (quand `AppConfig.sentryEnabled`).

## Ce qui n'est jamais envoyé

- **Les 401** : un jeton expiré est normal ; l'app le rafraîchit ou renvoie à
  la connexion.
- **Les coupures réseau** (depuis la 1.1.20) : pas de réseau, délai dépassé
  (`ApiException.isNetwork`, `ApiException.isNetworkFailure`). Ce n'est ni un
  bug de l'app ni du serveur, et l'écran affiche déjà « Réessayer ».
  Filtrées à deux endroits : l'observateur Riverpod
  (`app/monitoring/provider_observer.dart`) et `beforeSend`.

Pourquoi : 2 800 erreurs « Impossible de se connecter au serveur » avaient
épuisé le quota gratuit le 21/09/2026. Plus rien d'autre n'arrivait — c'est
pour ça que le bug de la photo de profil (1.1.19) n'est jamais apparu dans
Sentry.

Tests : `test/api_exception_test.dart` (groupe `ApiException.isNetwork`).
