# Navigation : glisser pour revenir, et les feuilles

Deux règles que ni la compilation ni la relecture ne montrent. Chacune a coûté
un bug en production ; un test lit le code pour qu'elles ne reviennent pas.

## Glisser pour revenir : `push`, pas `go`

Sur iOS, glisser depuis le bord gauche fait `pop`. Il n'y a un écran précédent
que si l'on est venu par **`context.push`**. **`context.go`** reconstruit la pile
à partir de l'adresse : vers un écran de détail, il efface l'écran d'où l'on
venait.

Ce qui était cassé (corrigé dans #72) :

- Émission → Réserver avec `go` : revenu sur l'émission, plus rien dessous —
  l'accueil avait disparu de la pile ;
- Mes réservations → une réservation avec `go` : la réservation est déclarée
  dans l'onglet Accueil, `go` changeait donc d'onglet, sans retour.

Règle : **un écran de détail s'ouvre avec `push`**. Un `push` depuis un autre
onglet reste dans cet onglet (Explorer → une émission → retour à Explorer).
`go` reste juste pour changer d'espace (après la connexion, « Retour à
l'accueil », après l'envoi d'une réservation — pour qu'on ne puisse pas revenir
dans un formulaire déjà envoyé). Les flèches retour font `pop` quand elles le
peuvent.

Test : `test/swipe_back_test.dart` refuse un `go` vers la réservation et rejoue
la disposition des onglets.

## Les feuilles au-dessus de la barre d'onglets

Depuis la 1.1.19, les feuilles s'ouvrent sur le **navigateur racine**
(`useRootNavigator: true`) pour passer au-dessus de la barre d'onglets
flottante. Mais les écrans restent sur le navigateur de **leur onglet**.

Conséquence : **une feuille se ferme avec le `context` de son `builder`**, jamais
avec celui de l'écran. `Navigator.pop(context)` avec le context de l'écran
ferme l'**écran**, pas la feuille.

C'est ce qui a cassé la photo de profil en 1.1.19 : « Prendre une photo »
fermait l'écran Modifier le profil, la caméra s'ouvrait quand même, et la photo
revenait vers un écran disparu (`!mounted`) — jamais envoyée, sans une erreur.
Les envois sont tombés de 665 à 6 par jour en une semaine. Corrigé en 1.1.20.

Le bon modèle : la feuille **renvoie un choix** en se fermant
(`Navigator.pop(sheetContext, action)`), et l'écran agit une fois qu'elle est
fermée.

Test : `test/root_sheet_pop_test.dart` refuse toute feuille racine qui se
ferme avec le context de l'écran ou qui branche directement une méthode de
l'écran (`onTap: _pickAvatar`).
