# Aji Tfarraj — Mobile App (Flutter)

Mobile application that allows users to attend Moroccan TV show recordings
before they are broadcast on TV.

Workflow:
Browse shows → request reservation → staff phone confirmation → approval → ticket (QR) → check-in.

## Platforms
- iOS (iPhone)
- Android (Samsung and others)

## Tech Stack
- Flutter
- State management: Riverpod
- Routing: go_router
- Networking: Dio
- Models: freezed + json_serializable
- Local storage: shared_preferences, Hive (offline tickets)

## Branching
- main: production releases
- develop: staging/integration
- feature/<name>: feature branches (from develop)

## Setup
### Requirements
- Flutter SDK (stable)
- Android Studio or Xcode

### Install & Run
```bash
flutter pub get
flutter run
