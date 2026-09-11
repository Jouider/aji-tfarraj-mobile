# Réseaux sociaux (app)

`Profil › Modifier › Réseaux sociaux` : **Instagram, TikTok, Facebook**, tous
facultatifs, avec la raison écrite juste au-dessus — « pour vous proposer des
collaborations et des castings ».

## Sans copier-coller

- La plupart des gens connaissent leur nom Instagram ou TikTok par cœur : ils le
  **tapent après le `@`** déjà affiché devant le champ.
- Un lien **collé** devient le nom d'utilisateur **sur-le-champ**.
- Un `@` tapé par habitude est retiré (il est déjà affiché).
- **« Vérifier »** apparaît dès que la saisie est valable et ouvre le profil
  dans l'app du réseau : une faute de frappe se voit avant l'enregistrement.
- Facebook n'a pas de `@` devant : beaucoup de profils n'ont qu'un identifiant
  numérique, et le lien collé reste le plus simple.

Chaque champ porte la marque du réseau (TikTok et Facebook via Material,
Instagram dessiné), pour être reconnu avant d'être lu.

La connexion « en un toucher » (se connecter avec Instagram…) n'est pas
utilisée : pour Instagram elle ne marche qu'avec les comptes pro ou créateur, et
elle impose une validation de l'app par Meta et TikTok.

## Règles

`features/profile/domain/social_handles.dart` — identiques à celles du serveur
(`app/Support/SocialHandles.php`). Un champ vide efface le compte ; un lien qui
n'est pas un profil (publication, lien court, lien de partage) est refusé avec
« Tapez votre nom d'utilisateur, ou collez le lien de votre profil ».

Le **niveau d'influence** est donné par le staff dans le dashboard et n'est
jamais envoyé à l'app.

Tests : `test/social_handles_test.dart`.
