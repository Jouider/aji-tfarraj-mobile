# Campagnes dans l'app

`features/campaigns/`. Les règles (qui voit quoi, combien de fois, quand) sont
côté serveur : voir `docs/app-campaigns.md` du backend. Les campagnes se créent
dans le panneau, **Communication › Campagnes dans l'app**, sans nouvelle
version de l'app.

## Quand l'app demande

`GET /api/campaigns?device_id=…&platform=ios|android&app_version=…` (+ le
jeton si la personne est connectée — l'ApiClient l'ajoute).

- **Au lancement**, en arrivant sur l'accueil : la personne est connectée et
  rien ne s'ouvre par-dessus la connexion ou l'inscription (`AppGate`).
- **Au retour au premier plan**, si les campagnes ont plus de 30 minutes.

`device_id` : un UUID aléatoire créé au premier lancement, gardé dans les
préférences (`campaign_device_id`). Ce n'est pas l'identifiant publicitaire.

`app_version` : celle de l'app. **Une build de debug envoie 99.0.0** : on y voit
les campagnes de test (« version minimum 99.0.0 »), que personne d'autre ne
voit, même en production. `--dart-define=CAMPAIGN_APP_VERSION=…` la remplace.

## La fenêtre

- Posée par `AppGate`, **sur l'accueil seulement**, et **jamais** par-dessus la
  mise à jour forcée, le verrou Face ID ou la proposition de mise à jour.
- **Une seule par lancement** (`CampaignsState.popupDone`).
- Image 4:5, un vrai bouton (`cta`, « Voir » / « شوف » sans texte), ✕, et
  « Ne plus afficher » si `can_hide_forever`. La largeur se règle sur la
  hauteur de l'écran : tout tient sans défiler, même sur un petit iPhone.

## Les bannières

Sur l'accueil, **sous l'affiche** (la barre du haut est transparente, l'affiche
y monte). Image 16:9, carrousel avec des points s'il y en a plusieurs. Le ✕ la
cache **jusqu'à demain** (`campaign_banner_hidden_<id>`).

## Au toucher (`action.type`)

| type | l'app |
|---|---|
| `url` | le navigateur du téléphone (`LaunchMode.externalApplication`), à défaut Safari View Controller / Custom Tabs. **Jamais une WebView** (vidéos de 300 Mo du casting). Liens http(s) seulement. |
| `show` | la fiche de l'émission |
| `episode` | la fiche de l'émission, puis l'épisode choisi par-dessus (réservation) ; le retour ramène à la fiche |
| `screen` | voir ci-dessous ; un nom inconnu ramène à l'accueil |
| `none`, autre | rien |

| `screen` | écran |
|---|---|
| `home` | Accueil |
| `shows` | Émissions (onglet) |
| `my_reservations` | Mes réservations (onglet) |
| `profile` | Profil (onglet) |
| `profile_photo` | Modifier le profil (la photo s'y change) |
| `rewards` | Récompenses |
| `referral` | Parrainage (tableau de bord) |
| `lucky_wheel` | Roue de la chance |
| `casting_profile` | Casting (le book) |
| `store` | la fiche de l'app sur l'App Store / Play Store |

## Les événements

`POST /api/campaigns/{id}/events` — envoyés sans attendre, erreurs ignorées :
`impression` (fenêtre ou bannière visible, une fois), `click` (avant
l'action), `dismiss` (✕), `never` (« Ne plus afficher »). Les impressions
comptent : c'est avec elles que le serveur applique « une fois par jour, trois
fois au plus ».

## Tests

`test/campaigns_test.dart` : lecture de la réponse, textes FR/AR, écrans,
identifiant et version, une fenêtre par lancement, rechargement après 30 min,
bannière cachée jusqu'au lendemain, rendu à 375 px dans les deux langues,
heures des épisodes.
