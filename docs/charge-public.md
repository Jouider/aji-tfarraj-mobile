# Mode Chargé Public (app)

Le tableau de bord du chargé public : `features/charge_public/`.

## Gains par émission → détail par épisode

Toucher une émission dans « Gains par émission » ouvre une feuille qui détaille
**chaque tournage** : sa date, invités · présents, et ce qu'il a rapporté.
Même comportement sur l'accueil (les 3 premières émissions) et sur l'onglet
Gains (toutes).

- **Le total en tête de la feuille est celui de la ligne touchée.** Les épisodes
  en dessous sont calculés par le serveur avec la même règle, donc ils
  s'additionnent toujours à ce total.
- **La ligne n'est touchable que s'il y a un détail à montrer** — un chevron le
  signale, et il se retourne en arabe. Sur un serveur plus ancien sans ventilation,
  la ligne reste une simple ligne : ouvrir une feuille vide serait pire que ne
  rien ouvrir.
- **Tournage le plus récent en premier.** Les invités enregistrés avant le suivi
  par épisode apparaissent dans une ligne « Date non précisée », en dernier, pour
  que rien ne manque au total.
- **Un soir à 0 DH est affiché en gris, pas masqué** : le chargé public a amené
  des gens, il doit voir qu'ils ont été comptés.
- Le titre de l'épisode n'est affiché que s'il dit autre chose que le titre de
  l'émission.

Données : `CpShowRow.episodes` (`CpEpisodeRow`), lues depuis
`by_show[].episodes`. Tests : `test/cp_dashboard_test.dart`.
