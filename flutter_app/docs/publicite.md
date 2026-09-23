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

## Mise en service — ce qu'il reste à faire

Rien de ce qui suit n'est dans le code : ce sont des comptes et des clés.

**1. Ouvrir le compte AdMob** (admob.google.com), déclarer les deux apps
(iOS et Android), créer par app une unité *interstitielle* et une unité
*récompensée*.

**2. Remplacer les identifiants d'application dans le natif.** Ce sont
aujourd'hui ceux de **test** de Google — ils affichent des pubs factices et ne
rapportent rien :

- `android/app/src/main/AndroidManifest.xml` → `com.google.android.gms.ads.APPLICATION_ID`
- `ios/Runner/Info.plist` → `GADApplicationIdentifier`

L'identifiant d'application contient un `~`, l'unité un `/` : les confondre
fait planter l'app au démarrage.

**3. Brancher la vérification côté serveur.** Dans AdMob, sur **chaque unité
récompensée** : Paramètres → Vérification côté serveur → URL de rappel :

```
https://aji-tfarraj-backend-production.up.railway.app/api/ads/admob-callback
```

Sans cette URL, les vidéos se regardent mais aucun point n'est crédité.

**4. Allumer, côté Railway :**

```
ADS_ENABLED=true
ADMOB_IOS_INTERSTITIAL=ca-app-pub-…/…
ADMOB_IOS_REWARDED=ca-app-pub-…/…
ADMOB_ANDROID_INTERSTITIAL=ca-app-pub-…/…
ADMOB_ANDROID_REWARDED=ca-app-pub-…/…
```

**5. Déclarer la publicité sur les deux stores.** Play Console → « Contient des
annonces » ; App Store Connect → confidentialité (identifiant publicitaire
utilisé pour la publicité ciblée). Une app qui sert des pubs sans l'avoir
déclaré est retirée.

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
