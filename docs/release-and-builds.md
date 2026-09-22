# Versions et builds

Comment on numérote, construit, vérifie et livre une version — et les pièges
rencontrés entre 1.1.8 et 1.1.11, qui ont tous coûté du temps.

## Numérotation

- `flutter_app/pubspec.yaml` : `version: X.Y.Z+N` (N = numéro de build).
- Chaque montée de version passe par une PR `chore/bump-X.Y.Z`.
- **Un numéro utilisé sur App Store Connect est consommé** : on ne le réutilise
  jamais, même si la build n'a pas été publiée (un train fermé renvoie 409).
- Play refuse aussi un `versionCode` déjà envoyé.
- Même numéro sur les deux stores.

| Version | Contenu |
|---|---|
| 1.1.8 (41) | réseaux sociaux du membre, zones de tap de l'avatar |
| 1.1.9 (42) | book vérifié en studio ⭐ |
| 1.1.10 (43) | « Présents » et sorties avant la fin (staff) |
| 1.1.11 (44) | correctif 16 ko Android, état vide centré, demande d'avis |
| 1.1.12 (45) | vidéos tutoriels (feuille + « ? »), Snapchat, invités et gains par épisode (chargé public) |

## Après une mise en production

- **Backend** : si la version s'accompagne d'une migration, `php artisan migrate`
  en production. Sans elle, les écrans qui lisent les nouvelles colonnes
  échouent (ex. « Présents ») ou n'affichent rien (ex. l'étoile du studio).
- **Railway** : mettre à jour `APP_LATEST_VERSION_IOS` / `APP_LATEST_VERSION_ANDROID`
  pour que l'invitation à mettre à jour propose la nouvelle version.
- **Notes de version** : Play limite à **500 caractères par langue**, l'App Store
  à 4 000. Écrire d'abord pour Play.

## Android

```bash
cd flutter_app && flutter build appbundle --release
```

Résultat : `build/app/outputs/bundle/release/app-release.aab`.

Signé via `android/key.properties` → `android/release.keystore`, alias
`ajitfarraj`. Play vérifie l'empreinte :
`SHA1 4C:66:F1:97:33:66:43:E5:67:45:44:75:BE:13:E0:72:BB:03:FD:71`.

Vérifier que le bundle est signé avec cette clé et pas une clé de debug :

```bash
unzip -o app-release.aab 'META-INF/*' -d /tmp/aab && keytool -printcert -file /tmp/aab/META-INF/*.RSA | grep SHA1
```

### Pages mémoire de 16 ko

Play signale les bibliothèques natives qui peuvent planter sur les appareils à
pages de 16 ko. **Il ne regarde pas seulement l'alignement** : il lit aussi la
version du NDK inscrite dans chaque `.so` (section `.note.android.ident`).

Deux vérifications sur chaque bibliothèque `arm64-v8a` du bundle :
- **alignement minimal** des segments `PT_LOAD` ≥ 16384 (le *minimum*, pas le
  maximum : un seul segment à 4 ko suffit à être refusé) ;
- **NDK** inscrit : Play demande r28+ ; r20 est refusé.

Cas rencontré en 1.1.10 : `libdatastore_shared_counter.so`, livrée compilée en
**NDK r20** par `androidx.datastore` 1.2.0, tirée par `shared_preferences_android`.
Nous ne compilons pas cette bibliothèque, seul le plugin peut la changer :

- `shared_preferences_android` **2.4.21** revient à datastore **1.1.7** (NDK r25c) ;
- **2.4.23 ne se construit pas** avec notre AGP 8.11.1 : son module Gradle de
  nouvelle génération n'est jamais configuré, et la build échoue sur
  `GeneratedPluginRegistrant.java: cannot find symbol SharedPreferencesPlugin` ;
- d'où l'épingle `shared_preferences_android: 2.4.21` dans `dependency_overrides`.
  **À retirer au passage à AGP 9** (2.4.24+ exige Flutter 3.44 / Dart 3.12).

## iOS

```bash
cd flutter_app && LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 flutter build ipa --release
```

Résultat : `build/ios/ipa/aji_tfarraj.ipa`, livré par **Transporter**.

### Signature de distribution

Le certificat « Apple Distribution » est **géré dans le cloud** : il vit avec le
compte Apple ID, pas dans le trousseau local. Si Xcode n'a plus de compte
connecté, l'archive se construit mais l'export échoue :

```
error: exportArchive No Accounts
error: exportArchive No signing certificate "iOS Distribution" found
```

Correctif : Xcode › **Settings › Accounts** › se connecter (équipe `6U4S82LM57`),
puis exporter l'archive existante — **pas besoin de tout reconstruire** :

```bash
xcodebuild -exportArchive -archivePath build/ios/archive/Runner.xcarchive -exportOptionsPlist ExportOptions.plist -exportPath build/ios/ipa -allowProvisioningUpdates
```

`ExportOptions.plist` : `method` = `app-store-connect`, `teamID` = `6U4S82LM57`,
`signingStyle` = `automatic`.

### Si `flutter build ipa` reste bloqué

Symptôme : « Running Xcode build… » qui ne bouge plus, `xcodebuild` à 0 % de CPU
pendant de longues minutes, rien d'écrit dans DerivedData. En 1.1.11, Xcode et
le projet étaient sains — c'est la commande Flutter qui bloquait. Contournement :
archiver directement, puis exporter comme ci-dessus.

```bash
xcodebuild archive -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' -archivePath build/ios/archive/Runner.xcarchive -allowProvisioningUpdates
```

(90 secondes au lieu d'une attente sans fin.)

**Mais `xcodebuild archive` seul ne construit pas les « native assets » Flutter**
(`objective_c.framework`, requis par `path_provider_foundation`) : il embarque ce
qu'il trouve dans `build/native_assets/ios/`. Toujours les construire avant :

```bash
rm -rf build/ios build/native_assets .dart_tool/flutter_build   # le 3e aussi, voir plus bas
flutter build ios --release --no-codesign   # construit objective_c.framework pour iPhone
ls build/native_assets/ios/objective_c.framework/objective_c   # doit exister avant d'archiver
# puis xcodebuild archive, puis -exportArchive, comme ci-dessus
```

### 409 « unsupported platform in the arm64 slice » (`objective_c.framework`)

Rencontré en 1.1.12. Transporter refuse l'IPA :
`Runner.app/Frameworks/objective_c.framework/objective_c … Simulator platforms
aren't permitted`.

Cause : une build **simulateur** (`flutter run` sur un simulateur) laisse
`build/native_assets/ios/objective_c.framework` compilé pour le simulateur, et
l'archive le recopie tel quel. En supprimant ce dossier sans le reconstruire,
c'est pire : l'IPA part **sans** le framework, passe la validation, et plante au
lancement sur iPhone (`path_provider_foundation` ne trouve pas sa bibliothèque).

Procédure : celle ci-dessous (supprimer — `.dart_tool/flutter_build` compris —,
`flutter build ios --release --no-codesign`, archiver, exporter), puis vérifier
l'IPA.

**Supprimer `build/native_assets` ne suffit pas : il faut aussi `.dart_tool/flutter_build`.**
Rencontré en 1.1.13 puis en 1.1.14, simulateur ou pas. L'étape qui installe le
framework (`install_code_assets`) garde son tampon « à jour » dans
`.dart_tool/flutter_build/` : le dossier effacé n'est pas recopié,
`build/native_assets/ios` reste vide, et **l'archive réussit sans
`objective_c.framework`** — l'IPA passe la validation et plante au lancement.
La bonne séquence, qui garde le cache des bibliothèques natives :

```bash
rm -rf build/ios build/native_assets .dart_tool/flutter_build
flutter build ios --release --no-codesign
ls build/native_assets/ios/objective_c.framework/objective_c   # doit exister
```

Ne jamais archiver tant que ce fichier n'existe pas. (`flutter clean` marche aussi,
mais efface `build/app`, donc l'AAB : le mettre à l'abri d'abord.)

Vérifier l'IPA avant de la livrer :
- version et build dans `Payload/Runner.app/Info.plist` ;
- `codesign -dv Payload/Runner.app` doit afficher `Authority=Apple Distribution` ;
- `Payload/Runner.app/Frameworks` contient **exactement** `App`, `Flutter` et
  `objective_c`, tous compilés pour iOS (plateforme **2** ; 7 = simulateur) :
  ```bash
  otool -l Payload/Runner.app/Frameworks/objective_c.framework/objective_c | grep -A3 LC_BUILD_VERSION
  ```

## Pièges

- **Artefacts périmés.** Une build qui échoue laisse l'ancien `.aab` / `.ipa` à
  sa place. Avant d'envoyer un fichier, vérifier **sa date** et **la version à
  l'intérieur** — pas seulement qu'il existe.
- **Disque plein.** Sous quelques Go libres, la build iOS bloque sans message
  clair. Régénérables sans risque : `~/Library/Developer/Xcode/DerivedData`,
  `~/Library/Developer/Xcode/iOS DeviceSupport`, `flutter_app/build`,
  `~/Library/Caches/CocoaPods`. Le cache Gradle (`~/.gradle/caches`) l'est aussi,
  mais tout sera retéléchargé.
- **Une seule build Flutter à la fois.** Deux builds lancées ensemble partagent
  `.dart_tool` et `build/` et se corrompent.
- **`flutter clean`** efface aussi les `.aab` / `.ipa` déjà construits : ne pas le
  lancer tant qu'une build n'est pas livrée.
