# Photo de profil

## Vérification du visage à la prise de vue

La photo est vérifiée **sur le téléphone, avant l'envoi**, par le détecteur de
visage de Google ML Kit. Rien ne quitte le téléphone et aucune empreinte
biométrique n'est calculée ni conservée — c'est la différence avec la recherche
de doublons côté serveur, dont les empreintes relèvent de la loi 09-08 et de
l'autorisation CNDP.

Elle s'applique partout où `FaceCaptureScreen` sert : la photo de profil du
membre, l'inscription sur place, et la photo refaite par le staff à la porte.

### Ce qui est refusé, et le message affiché

| Verdict | Quand | Message |
|---|---|---|
| `noFace` | Aucun visage | « Aucun visage détecté… » |
| `tooSmall` | Le visage fait moins de 15 % de la largeur | « Rapprochez-vous : le visage doit remplir le cadre. » |
| `multipleFaces` | Un 2ᵉ visage au moins moitié aussi large que le 1ᵉʳ | « Une seule personne sur la photo. » |
| `notFacing` | Tête tournée ou penchée de plus de 25° | « Le visage doit être tourné vers l'objectif. » |
| `eyesClosed` | **Les deux** yeux sous 0,15 de probabilité d'ouverture | « Les yeux doivent être ouverts. » |

### Chaque seuil penche vers l'acceptation

Une photo refusée à tort, c'est une personne bloquée à l'écran de profil. Une
photo un peu imparfaite reste utilisable à la porte. Donc :

- **La taille** reprend exactement le seuil d'avant (15 %) : la vérification ne
  refuse pas plus de photos pour ce motif, elle explique mieux. Le détecteur
  cherche jusqu'à 10 %, pour pouvoir dire « rapprochez-vous » plutôt que « aucun
  visage ».
- **Un visage plus petit en arrière-plan ne compte pas** : les photos sont prises
  dans la rue, au café, à la porte du studio.
- **Un seul œil fermé n'est pas un clignement** : clin d'œil, plissement au
  soleil, mèche de cheveux. Et un seuil bas pour que les yeux étroits et les
  lunettes ne passent pas pour fermés.
- **Une mesure absente ne compte pas contre la photo.**
- **En cas d'erreur du détecteur, la photo est acceptée** : une panne passagère
  ne doit jamais bloquer une photo valable.

La taille est mesurée par rapport au **plus petit côté** de l'image : si le
fichier garde une étiquette d'orientation, largeur et hauteur peuvent être
inversées par rapport à ce que voit le détecteur. Pour une photo en portrait
c'est la largeur ; sinon, la règle ne peut devenir que plus souple.

### Ce que la vérification ne fait pas

Elle ne distingue pas une personne réelle d'une photo tenue devant l'objectif
(« liveness ») — il faudrait un outil spécialisé, payant et plus biométrique.
La prise de vue uniquement par la caméra, la recherche de doublons et la
comparaison visage/photo par le scanneur à la porte couvrent ce risque.

### Où

Les règles vivent dans `features/profile/domain/face_check.dart`
(`evaluateFaces`), séparées de ML Kit pour être testées sans appareil ;
`FaceDetectionService` fait le lien avec le détecteur. Tests :
`test/face_check_test.dart` — la plupart vérifient ce qui doit **encore être
accepté**.
