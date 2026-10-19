# Publicité dans l'app

Deux emplacements, et deux seulement. Ils sont écrits, testés, et **éteints** :
`ADS_ENABLED` vaut `false` par défaut, donc rien ne s'affiche tant que
personne ne l'allume.

| Emplacement | Où | Format | Règle |
|---|---|---|---|
| Après une réservation | entre « Réserver » et la confirmation | interstitiel | la place est enregistrée avant qu'elle ne s'ouvre ; préchargée pendant la saisie ; une seule par 30 min |
| Points en vidéo | écran fidélité | vidéo récompensée | le membre la déclenche ; +5 points, 3 par jour |

## Où exactement la pub se place

La personne appuie sur « Réserver ». **La réservation part et s'enregistre**,
puis la pub s'ouvre, puis l'écran « réservation envoyée » s'affiche. La place
est donc acquise avant la première image de la publicité : même si le
téléphone s'éteint pendant, la réservation est faite.

La pub est préchargée dès l'ouverture de l'écran de réservation, pendant que
la personne lit et coche. Sans ce préchargement, il y aurait trois à quatre
secondes d'écran vide entre l'appui et la confirmation — et c'est l'attente,
pas la publicité, qui fait désinstaller. Si elle n'est pas prête en quatre
secondes, on passe directement à la confirmation.

La vidéo récompensée, elle, ne peut pas être imposée : le règlement AdMob
exige que le membre choisisse de la regarder. Un « regardez pour réserver »
ferait suspendre le compte.

## Les points ne sont jamais crédités par le téléphone

L'app dit à AdMob qui regarde (`ServerSideVerificationOptions(userId:)`).
Quand la vidéo est allée au bout, **Google** appelle le serveur, avec une
signature. Le serveur vérifie la signature, refuse les rejeux
(`transaction_id` unique), applique le plafond du jour, et écrit la ligne de
points.

Sans ça, l'URL de crédit serait publique et un `curl` suffirait à se donner
des points — qui s'échangent contre de vrais cadeaux.

Conséquence visible : les points arrivent une ou deux secondes après la fin de
la vidéo, pas à la seconde même. Le texte affiché le dit (« tes points
arrivent »), l'écran relit le solde trois secondes plus tard.

## Mise en service (19/10/2026, version 1.1.24)

**Fait :**

| | Android | iOS |
|---|---|---|
| App ID (natif) | `ca-app-pub-2833493160230222~8782023439` | `ca-app-pub-2833493160230222~2281948283` |
| Interstitiel | `ca-app-pub-2833493160230222/9983882282` | `ca-app-pub-2833493160230222/8743697664` |
| Récompensée | `ca-app-pub-2833493160230222/5797225267` | `ca-app-pub-2833493160230222/4216375278` |

- App ID dans `AndroidManifest.xml` et `Info.plist` (un `~` ; une unité à la
  place fait planter l'app au démarrage).
- Rappel de vérification côté serveur (SSV) posé sur les deux unités
  récompensées : `https://aji-tfarraj-backend-production.up.railway.app/api/ads/admob-callback`.
- Android : permission `AD_ID` déclarée.
- iOS : `NSUserTrackingUsageDescription` (traduite fr/ar) et la demande ATT,
  faite une fois par `AdMobGateway`, après le consentement, quand le SDK
  démarre. Le SDK démarre ~3 s après l'ouverture dès que le serveur allume la
  publicité (`adsWarmUpProvider`, regardé par la coquille) : la question ne
  tombe jamais au milieu d'une réservation.

**Reste, hors code :**

1. **Railway** (service backend) — les unités passent par le serveur, l'app
   ne reçoit que celles de sa plateforme :
   ```
   ADMOB_IOS_INTERSTITIAL=ca-app-pub-2833493160230222/8743697664
   ADMOB_IOS_REWARDED=ca-app-pub-2833493160230222/4216375278
   ADMOB_ANDROID_INTERSTITIAL=ca-app-pub-2833493160230222/9983882282
   ADMOB_ANDROID_REWARDED=ca-app-pub-2833493160230222/5797225267
   ADS_ENABLED=true
   ```
   `ADS_ENABLED=true` **seulement une fois la 1.1.24 publiée** : avant, les
   versions installées portent l'App ID de test.
2. **App Store Connect** → Confidentialité de l'app : identifiant
   publicitaire utilisé **à des fins de suivi** et pour la publicité tierce.
   Obligatoire avec la clé ATT de la 1.1.24.
3. **Play Console** → Contenu de l'application → « Contient des annonces » :
   oui ; formulaire « Identifiant publicitaire » : utilisé pour la publicité.
4. **app-ads.txt** à la racine du site déclaré sur les deux fiches, avec la
   ligne donnée par AdMob (`google.com, pub-2833493160230222, DIRECT, f08c47fec0942fa0`).

### Tester sur TestFlight sans rien allumer

`ADS_TESTERS=8,36` (ids des comptes, sur Railway) : ces comptes reçoivent la
publicité **avec les unités de test de Google**, même `ADS_ENABLED=false`.
Tout le monde d'autre ne voit rien. Les pubs affichent « Test Ad » : c'est
voulu — taper sur ses propres vraies pubs fait suspendre le compte AdMob.

À vérifier sur la 1.1.24 TestFlight, connecté avec un compte testeur :
la demande de suivi (iOS) quelques secondes après l'ouverture, la vidéo de
l'écran Fidélité, l'interstitiel après une réservation (une fois par 30 min).
Les points d'une vidéo de **test** n'arrivent pas : Google n'appelle le rappel
signé que pour les vraies unités. Le rappel lui-même se vérifie dans AdMob,
bouton « Vérifier l'URL » de chaque unité récompensée.

### Le jour de l'allumage

Les versions avant la 1.1.24 portent l'App ID de test : avec les vraies
unités, leurs pubs échouent. En même temps que `ADS_ENABLED=true`, passer la
version minimale à 1.1.24 (mise à jour obligatoire) sur Railway.

### Les réglages qu'on peut bouger sans publier de version

| Variable | Défaut | Effet |
|---|---|---|
| `ADS_ENABLED` | `false` | l'interrupteur général |
| `ADS_RESERVATION_ENABLED` | `true` | l'interstitiel de la réservation |
| `ADS_RESERVATION_COOLDOWN_MINUTES` | `30` | une pub par tranche de |
| `ADS_REWARDED_ENABLED` | `true` | la vidéo pour des points |
| `ADS_REWARDED_POINTS` | `5` | points par vidéo |
| `ADS_REWARDED_DAILY_CAP` | `3` | vidéos créditées par jour |

Une unité laissée vide éteint son emplacement : l'app ne l'annonce pas.

## Ce qu'il faut surveiller les deux premières semaines

Le revenu n'est pas le seul chiffre qui bouge.

- **le taux de réservation** (visites de l'écran épisode → réservations
  envoyées). S'il baisse, l'interstitiel coûte plus qu'il ne rapporte :
  `ADS_RESERVATION_ENABLED=false`, et on n'y revient pas.
- **la rétention J7.** Elle était autour de 10 % avant la publicité.
- **les points distribués par la vidéo** contre ceux gagnés en venant au
  tournage (`points_ledger.type = 'ad_reward'` contre `'attendance'`). Si les
  vidéos prennent le dessus, baisser `ADS_REWARDED_POINTS` ou le plafond : les
  points doivent rester la monnaie de la présence.

## Ordre de grandeur, pour mémoire

Avec ~1 500 membres actifs par mois et des eCPM marocains (0,20–2,50 $ selon le
format), les deux emplacements rapportent entre **80 et 1 600 MAD par mois**,
autour de **300 MAD** dans le scénario central. C'est peu : le revenu
publicitaire n'arrive qu'avec l'audience, vers 10 000 membres actifs. Le
parrainage direct (une marque, un contrat) rapporte davantage bien avant ce
seuil.
