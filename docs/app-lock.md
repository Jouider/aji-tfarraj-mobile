# Verrouillage Face ID (app)

Facultatif : le membre l'active dans Profil (« Verrouillage biométrique »).
`features/app_lock/`, piloté par `AppGate` (`app/app_gate.dart`).

## Ce que voit la personne

Pas d'écran « Application verrouillée » : il a été retiré (cadenas, titre,
paragraphe, bouton qui tournait), jugé peu professionnel.

- **Au lancement** : la vidéo de lancement joue en entier. Sur son **dernier
  plan** (le logo), le verrou prend le relais — c'est la même image,
  `assets/splash/splash_last.jpg` — et Face ID s'ouvre dessus. Pas de fondu
  au noir entre les deux : la splash part tout de suite quand l'app est
  verrouillée.
- **Au retour d'arrière-plan** (après plus de 30 s) : le même logo, Face ID
  demandé tout seul.
- **Annulé ou échoué** : un seul bouton discret, « Déverrouiller », en bas.
  Rien pendant que le système demande.

La proposition de mise à jour facultative attend le déverrouillage.

## Comment c'est câblé

- `AppGate` cache le verrou tant que le routeur est sur `Routes.splash` :
  pendant la vidéo, il n'y a rien de privé à l'écran.
- `SplashScreen` précharge l'image du verrou ; à la fin de la vidéo, s'il est
  verrouillé, il quitte sans le fondu.
- Si la vidéo change, régénérer le dernier plan :

  ```bash
  ffmpeg -sseof -0.05 -i assets/splash/splash.mp4 -frames:v 1 -q:v 3 assets/splash/splash_last.jpg
  ```

## Tests

`test/lock_screen_test.dart` : Face ID demandé seul, aucun bouton pendant la
demande, le bouton après une annulation, rendu FR/AR.
