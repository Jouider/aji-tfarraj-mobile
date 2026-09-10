# Casting (app)

Une section où le membre constitue son **book** — cinq photos dans des poses
imposées, plus ses mensurations — et **postule** aux annonces. Le contrat
serveur est décrit dans le repo backend : `docs/casting.md`.

## Où ça vit

`Profil › Casting`. La barre du bas a déjà cinq onglets ; un sixième aurait été
illisible.

L'entrée est visible **pour tout le monde**. Un compte non éligible ouvre la
section et lit pourquoi, au lieu de trouver un menu où il manque une ligne.

## Majeurs uniquement

Le serveur refuse en 403 avec deux codes distincts, et l'app les traite
différemment parce que l'un des deux se répare :

| Code | Ce que voit la personne |
|---|---|
| `BIRTHDAY_REQUIRED` | « Renseignez votre date de naissance » + un bouton vers le profil |
| `MINOR_NOT_ELIGIBLE` | « Le casting est réservé aux personnes majeures » |

## Le book

Cinq emplacements, toujours les mêmes.

| Pose | |
|---|---|
| Plein pied — de face | obligatoire |
| Plein pied — de profil | obligatoire |
| Portrait | obligatoire |
| Plein pied — de dos | facultatif |
| Portrait souriant | facultatif |

Les emplacements vides **restent affichés** : ce sont eux la consigne, et les
masquer ferait croire que le book est fini.

`is_complete` et `missing_poses` viennent du **serveur**. L'app ne recalcule
jamais la règle : les deux pourraient sinon être en désaccord sur qui a le droit
de postuler.

Une pose inconnue de cette version est **ignorée** plutôt que devinée — la
ranger dans le mauvais emplacement serait pire que ne pas l'afficher.

### La prise de vue

```
   toucher un emplacement
              │
              ▼
     CONSIGNES (bottom sheet)      ← lues avant que la caméra s'ouvre
   étapes numérotées + « faites-vous photographier »
              │
              ▼
     CAMÉRA ARRIÈRE + cadre        ← une seule ligne de rappel
              │
              ▼
       upload dans l'emplacement
```

**Les consignes sont un écran à part, avant la caméra.** Un texte affiché
par-dessus une preview n'est pas lu : la personne est déjà en position et se
regarde. Lire d'abord, photographier ensuite, c'est l'ordre qui produit un book
exploitable.

**Caméra arrière.** Quelqu'un d'autre tient le téléphone — on ne se photographie
pas en pied à bout de bras, et c'est justement le cadrage sur lequel le book est
jugé. Pas de galerie : c'est la même position que pour les avatars.

**Résolution `high`, pas `medium`.** Sur un plein pied, le visage occupe une
fraction de l'image ; en `medium` il devient illisible.

**Le cadre dessiné n'est pas décoratif.** À qui on dit « tenez-vous droit, en
pied », les gens se coupent les pieds. Avec une forme à remplir, ils reculent.
Le cadre plein pied porte deux repères — haut du crâne et pieds — parce que les
deux erreurs sont de couper les pieds et de reculer si loin que le visage
disparaît.

Les consignes vivent dans les fichiers de copie (FR + AR), pas sur le serveur :
traduites, lisibles hors ligne, et sans aller-retour au moment où la personne
est déjà devant l'objectif.

### Les mensurations

Jamais bloquantes. Un directeur de casting convoque quelqu'un sur ses photos ;
il ne fait rien de chiffres sans visage.

## Postuler

Le bouton n'existe **pas** tant que le book est incomplet : à la place, la
raison et un bouton vers le book. Un « Postuler » grisé inviterait à insister.

Un statut de candidature inconnu de cette version compte quand même comme
**« déjà postulé »** — l'inverse proposerait de postuler une seconde fois à
quelqu'un qui l'a déjà fait.

Le retrait n'est proposé que si le serveur dit `withdrawable`. Le défaut est
`false` : offrir le bouton par erreur effacerait une décision déjà prise.

## Traductions garanties par le compilateur

`CastingCopy` (`app/copywriting/casting_copy.dart`) est une classe abstraite de
**57 membres** que `CastingCopyFr` et `CastingCopyAr` implémentent toutes les
deux. Une chaîne ajoutée dans une langue et pas dans l'autre **ne compile pas**.
Dans une app bilingue, c'est le seul mécanisme qui attrape de façon fiable un
écran à moitié traduit.

`AppStrings.casting` renvoie l'objet entier plutôt que cinquante getters : la
copie est structurée — chaque pose porte ses propres étapes — et l'aplatir
perdrait cette forme.

## Fichiers

| Fichier | Rôle |
|---|---|
| `features/casting/domain/casting_pose.dart` | Les cinq poses, lesquelles sont obligatoires, laquelle est un plein pied |
| `features/casting/domain/casting_models.dart` | Book, annonces, candidatures |
| `features/casting/data/casting_repository.dart` | Les 9 appels API + providers |
| `features/casting/presentation/casting_home_screen.dart` | Onglets castings / publications + bandeau book |
| `features/casting/presentation/casting_book_screen.dart` | Les cinq emplacements + mensurations |
| `features/casting/presentation/pose_guide_sheet.dart` | Les consignes, avant la caméra |
| `features/casting/presentation/pose_capture_screen.dart` | Caméra + cadre |
| `features/casting/presentation/casting_detail_screen.dart` | Une annonce + postuler |
| `features/casting/presentation/my_applications_screen.dart` | Mes candidatures |

## Tests

`test/casting_test.dart` (19) : les clés de pose qui doivent correspondre au
contrat serveur, obligatoire contre facultatif, plein pied contre portrait, une
pose inconnue ignorée, la complétude qui vient du serveur, le repli du titre
arabe, un statut inconnu qui compte quand même comme « déjà postulé », et les
défauts prudents (`can_apply` et `withdrawable` à `false` quand le serveur se
tait).

Le rendu réel — caméra, cadre, upload — n'est pas couvert : il demande un
appareil.
