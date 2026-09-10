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

## La feuille de retour

Quand le tournage est fini, quelqu'un doit dire au responsable transport combien
de personnes attendent à chaque arrêt. La porte a enregistré les réponses une
par une ; cet écran les additionne.

**Où** : l'icône navette en haut de l'écran de check-in, ou
`Profil › Feuille de retour`. Mêmes rôles que la porte (staff, admin,
**scanner**).

L'icône passe l'épisode du billet qui vient d'être scanné, donc l'écran s'ouvre
directement sur le bon tournage. Sans contexte — quelqu'un qui ouvre l'app en
fin de soirée — il demande lequel, et **ne pose pas la question s'il n'y a qu'un
seul tournage** : confirmer la seule réponse possible ne sert à rien.

### Ce qu'on lit

```
   26 attendent · 16 repartent seules · 42 entrees
              |
              v
   Ain Sebaa       7 pers.   > (deplier -> les noms)
   Maarif          6 pers.   >
   Zenata       personne
              |
              v
        << Envoyer au transport >>
```

Le **nombre de personnes** est en gros. Une réservation est plafonnée à
**une place** par l'API (`seats: min:1|max:1`), donc afficher en plus un nombre
de billets répéterait le même chiffre en plus petit — la colonne a été retirée.
Le modèle lit quand même les deux : d'anciennes réservations multi-places
existent, et en sous-déclarer une laisserait quelqu'un sur le trottoir.

Les **noms sont repliés**. On les ouvre au pied du véhicule pour faire l'appel,
pas pendant qu'on lit les totaux.

Un arrêt **à zéro reste affiché**, en gris. C'est ainsi que le dispatcher sait
qu'il n'a pas à y envoyer de véhicule — le masquer forcerait à deviner entre
« personne » et « oublié ».

Un arrêt marqué **« hors liste de ce tournage »** (encadré rouge + bandeau
d'alerte) veut dire qu'un admin l'a retiré *après* que des gens l'aient choisi.
Ces gens attendent quand même : l'anomalie se voit au lieu de se taire.

### L'envoyer

Deux formats, parce qu'ils sont lus par des gens différents :

| Format | Pour qui |
|---|---|
| **PDF** | Le dossier, et le chauffeur qui coche les noms au pied du véhicule (une case vide devant chaque nom) |
| **Message** | Le responsable transport, qui veut juste les chiffres sur WhatsApp à 23 h |

Le PDF tient en trois colonnes — **arrêt, repère, personnes** — puis liste les
**noms par arrêt sur deux colonnes**, avec une case à cocher : un arrêt chargé
fait vingt et quelques personnes, et un nom par ligne ferait tourner les pages
au chauffeur sur le trottoir. Le titre d'un arrêt reste collé à ses noms
(`pw.Inseparable`), sauf au-delà de 24 passagers — `MultiPage` **lève une
exception** sur un bloc insécable plus haut qu'une page, et planter dans les
mains du scanneur serait pire qu'un titre en bas de page.

Le PDF embarque **Cairo** (sous-ensemble latin + arabe, OFL, ~73 Ko × 2). Les
polices intégrées d'un PDF n'ont **aucun glyphe arabe** : sans ça un nom en
arabe sortirait en blancs. Chaque chaîne reçoit la direction de son propre
script — l'arabe a besoin du RTL pour se lier et se réordonner — mais tout reste
**aligné à gauche**, pour que le chauffeur lise les noms dans une seule colonne.

**Aucun numéro de téléphone n'y figure.** Cette feuille est faite pour être
transmise, et le scanneur peut de toute façon retrouver un numéro à la porte.

Le contrat serveur est dans le repo backend : `docs/return-points.md`
§ « La feuille de route de la navette ».

## Fichiers

| Fichier | Rôle |
|---|---|
| `features/staff/domain/ticket_preview.dart` | Le modèle et les règles de décision (`canAdmit`, `canReplacePhoto`, `asksReturnPoint`) |
| `features/staff/presentation/ticket_preview_view.dart` | L'écran d'aperçu |
| `features/staff/presentation/staff_check_in_screen.dart` | Scan QR + saisie manuelle |
| `features/staff/data/staff_repository.dart` | Appels API et machine à états |
| `features/staff/domain/return_manifest.dart` | La feuille et ses règles de lecture (`servedTonight`, `hasOrphanedPassengers`) |
| `features/staff/presentation/return_manifest_screen.dart` | L'écran de la feuille |
| `features/staff/data/return_manifest_export.dart` | Génération du PDF et du message |

## Tests

`test/ticket_preview_test.dart` couvre la logique dont dépend la décision
d'admettre quelqu'un : refus non admissibles, **statut inconnu bloquant**,
photo remplaçable ou non, arrêts desservis, absence de navette, effacement du
choix, repli du libellé arabe, et champs optionnels absents.

`test/return_manifest_test.dart` (13) couvre la lecture de la feuille : on
compte des personnes et pas des billets, un arrêt vide reste affiché, un
passager sur un arrêt retiré lève une alerte, le repli du libellé arabe, le nom
de repli d'un épisode sans titre, et le message envoyé au transport (chiffres,
alerte « hors liste », aucun numéro de téléphone).

`test/return_manifest_pdf_test.dart` (3) construit un vrai PDF, avec des noms en
arabe. La police est un **asset** : si elle cessait d'être embarquée, rien
n'échouerait à la compilation et l'export planterait dans les mains du scanneur
en fin de tournage — le pire moment pour l'apprendre.

Le rendu réel (caméra, upload, agrandissement, partage) n'est pas couvert : il
demande un compte scanneur et un billet du jour sur un appareil.
