# Vidéos tutoriels (app)

Deux gestes bloquent des membres : **compléter le profil** et **réserver depuis
le lien d'un chargé public**. Chacun a une vidéo de 43 à 49 s, en français et
en arabe. Code : `lib/features/tutorials/`.

## D'où viennent les vidéos

`GET /api/app-config → tutorials` (voir `docs/tutorials.md` côté backend). Les
fichiers sont sur le serveur, pas dans l'app : une vidéo se remplace **sans
nouvelle version** sur les stores.

- `Tutorials.fromAppConfig()` lit le bloc ; `tutorialClipProvider(topic)` donne
  le clip dans la langue du membre.
- **Une seule langue disponible ?** L'autre lecteur reçoit ce clip : les écrans
  sont les mêmes, et une vidéo aide plus que rien.
- **Pas de clip** (serveur plus ancien, réseau coupé, entrée illisible ou lien
  non web) : aucun bouton n'apparaît. Un bouton d'aide qui ne lit rien serait
  pire que pas de bouton.

## Où elles apparaissent

| Endroit | Vidéo | Quand |
|---|---|---|
| **« ? »** dans la barre du haut — Modifier le profil | Profil | Toujours |
| **« ? »** — Réserver des places, et l'écran d'invitation (`/r/…`) | Réservation | Toujours |
| **Bandeau « Première fois ? »** en haut de Modifier le profil | Profil | Profil incomplet, jusqu'à ce que le membre regarde ou masque |
| **Bandeau « Comment réserver avec cette invitation ? »** sur l'écran d'invitation | Réservation | Jusqu'à ce que le membre regarde ou masque |
| **« Voir comment faire · 0:49 »** sous un message d'erreur | Profil / Réservation | Quand l'enregistrement du profil ou la réservation échoue |
| **Profil › Comment ça marche** (parcours spectateur) | Les deux | Toujours |

- **Le bandeau n'est proposé qu'une fois par appareil** : regarder la vidéo ou
  toucher ✕ le retire définitivement (`tutorial_offer_done_<sujet>` dans les
  préférences). Le « ? » reste.
- La **durée** est affichée avant de lancer (« 0:49 ») : on accepte plus
  volontiers une vidéo dont on connaît la longueur.
- Le lecteur (`TutorialVideoScreen`) démarre seul, se met en pause au toucher,
  propose **Revoir** à la fin, et affiche l'image du clip pendant le chargement.
  Il s'ouvre en plein écran, au-dessus de la barre de navigation.

Le parcours « parrains » de Comment ça marche n'a pas encore de vidéo : il garde
son emplacement `parrainVideoUrl` dans les textes.

## Tests

- `test/tutorials_test.dart` — langue choisie, repli sur l'autre langue, serveur
  sans vidéos, `[]` venant de PHP, entrées illisibles ou non web ignorées, durée,
  bandeau proposé une seule fois et séparément par sujet.
- `test/tutorial_widgets_test.dart` — sans clip, aucun point d'entrée ; avec un
  clip, « ? », bandeau et lien minuté ; un bandeau masqué le reste après un
  redémarrage, le « ? » reste.
