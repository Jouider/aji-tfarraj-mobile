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

## Épisode → qui est venu, et combien chacun rapporte

Toucher un épisode dans la feuille **le déplie** : la liste des invités de ce
tournage, chacun avec ce qu'il a rapporté (`+25 DH`).

- **Présents d'abord, montant le plus élevé d'abord**, puis ceux qui ne sont pas
  venus, en gris. L'ordre vient du serveur ; l'app ne le refait pas.
- Un invité approuvé qui n'est pas venu à un tournage **passé** est marqué
  **« Absent »**. Pour un tournage à venir, on garde son statut (Approuvée, En
  attente…) ; une réservation annulée ou rejetée garde le sien dans tous les cas.
- **Les montants s'additionnent au total de l'épisode** — même règle côté serveur.
- Déplié sur place plutôt qu'une deuxième feuille par-dessus la première : le
  total de l'émission reste visible.
- Une phrase sous l'en-tête (« Touchez un épisode pour voir qui est venu ») et un
  chevron qui pivote. **Sur un serveur plus ancien sans noms**, ni l'une ni
  l'autre : la ligne reste une simple ligne.

Données : `CpShowRow.episodes` (`CpEpisodeRow`), lues depuis
`by_show[].episodes` ; les invités dans `CpEpisodeRow.guests`
(`CpEpisodeGuest`), lus depuis `episodes[].guests`. Tests :
`test/cp_dashboard_test.dart`.
