# Parcours du scanneur (app mobile)

Ce que voit et fait le staff à la porte du studio. Le contrat serveur
correspondant est décrit dans le repo backend : `docs/scanner-flow.md`,
`docs/check-in-rules.md` et `docs/return-points.md`.

## Qui y a accès

`Profil › Check-in billets`, visible pour les rôles **staff**, **admin** et
**scanner**. Les scanneurs sont des comptes de pointage uniquement : ils ne
peuvent rien faire d'autre dans l'app.

## Le flux, en deux temps

```
   scan du QR (ou saisie du code)
              │
              ▼
        APERÇU  ← personne n'est encore admis
   photo · nom · places · épisode · statut
              │
              ├── photo inutilisable ?  → bouton appareil photo
              ├── navette ce soir ?     → choix du point de retour
              │
              ▼
      « Valider l'entrée »  ← admet réellement
```

Avant, scanner **pointait directement** : le scanneur découvrait qui il venait
de laisser entrer après coup. Il ne pouvait ni comparer le visage à la photo du
compte, ni corriger une photo ratée pendant que la personne est devant lui.

L'aperçu appelle `POST /api/staff/ticket/lookup`, **sans aucun effet de bord** :
scanner pour regarder est gratuit, on n'admet personne à moitié.

## L'aperçu

| Élément | Détail |
|---|---|
| **Photo** | 160 px, **agrandissable en plein écran** — 160 px ne suffisent pas toujours pour être sûr d'un visage |
| **Bandeau de statut** | Ce qui va se passer, avant que la personne s'attende à entrer |
| **Mineur** | Signalé en rouge |
| **Détails** | Places, émission, épisode, date, studio, téléphone, n° de billet |

### Les statuts

| Statut | Bandeau | Bouton Valider |
|---|---|---|
| `can_check_in` | Billet valide — vérifiez le visage | **présent** |
| `already_checked_in` | Déjà pointé à HH:MM | absent |
| `not_approved` | Réservation non approuvée | absent |
| `wrong_date` | Passé / à venir / sans date | absent |
| inconnu | Vérifiez avec un responsable | absent |

Le bouton **n'existe pas** quand la validation est impossible : un bouton grisé
invite à insister. Et un statut qu'une version plus récente du backend
introduirait **bloque** au lieu d'admettre — laisser entrer sur une règle que ce
build ne sait pas lire serait pire que d'appeler un responsable.

## Corriger la photo

Un bouton appareil photo sur la photo ouvre la capture en **caméra arrière** :
le staff photographie la personne en face de lui, pas lui-même. L'aperçu se met
à jour sur place, donc corriger puis valider se fait d'un trait, sans re-scanner.

Le bouton **n'apparaît pas** si l'avatar a été verrouillé par un administrateur
(`avatar_locked`). Les erreurs du serveur sont affichées telles quelles — elles
disent quoi faire (photo verrouillée, personne pas à la porte).

## Le point de retour

Après le tournage, le staff raccompagne les gens en navette. La question est
posée **à la porte** : elle ne prend son sens qu'une fois la personne réellement
venue, et les plans changent le soir même.

La section n'apparaît **que si une navette roule ce soir** — `return_points`
vide veut dire aucun véhicule, et la question serait alors sans objet.

La réponse est **facultative** : « Repart par ses propres moyens » est un choix
à part entière, aussi accessible que les autres. Beaucoup de gens viennent en
voiture, et un champ obligatoire remplirait les chiffres de transport de
réponses au hasard.

Un choix déjà exprimé lors d'un scan précédent est **pré-sélectionné**, pour ne
pas reposer la question.

> Les arrêts eux-mêmes sont créés par un **administrateur** dans le dashboard
> (Contenu › Points de retour), puis activés **par épisode**. Le staff à la
> porte ne crée jamais d'arrêt.

## Fichiers

| Fichier | Rôle |
|---|---|
| `features/staff/domain/ticket_preview.dart` | Le modèle et les règles de décision (`canAdmit`, `canReplacePhoto`, `asksReturnPoint`) |
| `features/staff/presentation/ticket_preview_view.dart` | L'écran d'aperçu |
| `features/staff/presentation/staff_check_in_screen.dart` | Scan QR + saisie manuelle |
| `features/staff/data/staff_repository.dart` | Appels API et machine à états |

## Tests

`test/ticket_preview_test.dart` couvre la logique dont dépend la décision
d'admettre quelqu'un : refus non admissibles, **statut inconnu bloquant**,
photo remplaçable ou non, arrêts desservis, absence de navette, effacement du
choix, repli du libellé arabe, et champs optionnels absents.

Le rendu réel (caméra, upload, agrandissement) n'est pas couvert : il demande un
compte scanneur et un billet du jour sur un appareil.
