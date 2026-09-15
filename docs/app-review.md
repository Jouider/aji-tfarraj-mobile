# Demande d'avis sur les stores

Depuis 1.1.11. Objectif : de meilleures notes sur l'App Store et Play, sans
agacer — une demande mal placée coûte une étoile au lieu d'en rapporter cinq.

- Code : `flutter_app/lib/features/review/data/review_prompter.dart`
- Déclencheur : `flutter_app/lib/features/reservation/my_reservations_screen.dart`
- Bouton manuel : `flutter_app/lib/features/profile/profile_screen.dart`
- Tests : `flutter_app/test/review_prompter_test.dart`
- Paquet : [`in_app_review`](https://pub.dev/packages/in_app_review)

## Deux règles imposées par les stores

1. **La boîte native a un quota.** Apple et Google décident eux-mêmes si elle
   s'affiche, et aucune API ne dit si elle s'est affichée. Elle n'est donc
   **jamais derrière un bouton** : un bouton qui ne fait rien semble cassé, et
   gaspille le quota.
2. **Le bouton du profil ouvre la page du store** (`openStoreListing`). Ça marche
   toujours, sans quota.

## Quand la boîte native est proposée

Déclencheur : l'écran **« Mes réservations »** contient au moins une réservation
**pointée** (`checked_in`) — la personne a assisté à un enregistrement, c'est le
moment où elle sait ce que vaut l'application.

La demande n'est faite que si **toutes** ces conditions sont vraies :

| Règle | Valeur | Pourquoi |
|---|---|---|
| Soirées réussies | **au moins 2** | une soirée est un hasard ; deux, un avis |
| Délai depuis la dernière demande | **au moins 60 jours** | pas deux fois dans la même saison |
| Demandes par an | **3 maximum** | le plafond d'Apple ; au-delà rien ne s'affiche |
| A déjà noté depuis le profil | **jamais plus de demande** | il a donné son avis |
| Store disponible (`isAvailable`) | **obligatoire** | sinon rien n'est consommé, la demande reste due |

- **Chaque réservation pointée compte une seule fois** (clé `reservation-<id>`),
  quel que soit le nombre de rafraîchissements de la liste (elle se rafraîchit
  toutes les 30 s).
- La vérification est faite **une fois par visite** de l'écran, **après
  l'affichage** (jamais pendant la construction de l'écran).

## Stockage (`shared_preferences`)

| Clé | Contenu |
|---|---|
| `review_good_moments` | nombre de soirées comptées |
| `review_counted_moments` | clés déjà comptées (`reservation-<id>`) |
| `review_last_prompt_at` | date de la dernière demande |
| `review_prompts_this_year` | demandes dans l'année en cours |
| `review_year_started_at` | début de cette année glissante |
| `review_handled_manually` | le membre est allé noter depuis le profil |

## Changer les seuils

Constantes de `ReviewPrompter` : `minGoodMoments`, `cooldown`,
`maxPromptsPerYear`. Les tests couvrent chaque règle — les mettre à jour avec.

## Tester

- **Les règles** : `flutter test test/review_prompter_test.dart`. Un
  `ReviewLauncher` factice remplace le plugin et une horloge est injectée, donc
  aucun vrai quota n'est consommé.
- **La vraie boîte** :
  - iOS : en développement et sur TestFlight, la boîte s'affiche mais le bouton
    d'envoi est désactivé — seule la version App Store publie un avis ;
  - Android : uniquement sur une installation venant de Play (piste de test
    interne), jamais sur un APK installé à la main.

Identifiant App Store utilisé par le bouton du profil : `6760630862`.
