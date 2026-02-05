# Push Notifications System - Technical Documentation

## Overview

This document describes the complete push notification system implemented for the **Aji Tfarraj** mobile application. The system uses Firebase Cloud Messaging (FCM) for both iOS and Android platforms.

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Files Structure](#files-structure)
3. [Firebase Configuration](#firebase-configuration)
4. [Flutter Implementation](#flutter-implementation)
5. [Backend API Requirements](#backend-api-requirements)
6. [Notification Payload Formats](#notification-payload-formats)
7. [Deep Linking](#deep-linking)
8. [Testing Guide](#testing-guide)
9. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        FIREBASE CONSOLE                          │
│                   (Cloud Messaging Service)                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      FLUTTER APP                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  │
│  │  PushService    │  │  PushRouter     │  │ PushTokenProvider│  │
│  │  (FCM Handler)  │  │  (Navigation)   │  │  (Token Mgmt)   │  │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘  │
│           │                    │                    │            │
│           ▼                    ▼                    ▼            │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │              NotificationsProvider (State)                   ││
│  └─────────────────────────────────────────────────────────────┘│
│           │                                                      │
│           ▼                                                      │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │           NotificationRepository (Local Storage)             ││
│  │                    (SharedPreferences)                       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      BACKEND API                                 │
│              (Device Registration Endpoints)                     │
│                    POST /api/devices/register                    │
│                  DELETE /api/devices/unregister                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Structure

### Created Files

| File Path | Purpose |
|-----------|---------|
| `lib/firebase_options.dart` | Firebase configuration for iOS/Android |
| `lib/app/push/push_service.dart` | Main FCM service (handles all notification events) |
| `lib/app/push/push_router.dart` | Deep link navigation handler |
| `lib/app/push/push_token_provider.dart` | FCM token state management |
| `lib/app/push/device_repository.dart` | Backend device registration |
| `lib/features/notifications/domain/app_notification.dart` | Notification data model |
| `lib/features/notifications/data/notification_repository.dart` | Local storage persistence |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | Riverpod state management |
| `lib/features/notifications/presentation/notification_center_screen.dart` | Notification center UI |
| `lib/features/notifications/presentation/widgets/notification_card.dart` | Notification card widget |

### Modified Files

| File Path | Changes Made |
|-----------|--------------|
| `lib/main.dart` | Added Firebase initialization, SharedPreferences override, PushService setup |
| `lib/app/routes.dart` | Added `/notifications` route constant |
| `lib/app/router.dart` | Added NotificationCenterScreen route, protected route |
| `lib/features/home/home_screen.dart` | Added notification bell icon with unread badge |
| `lib/features/profile/profile_screen.dart` | Added notifications link with badge |
| `pubspec.yaml` | Added firebase_core, firebase_messaging, flutter_local_notifications dependencies |
| `android/build.gradle.kts` | Added Google services plugin declaration |
| `android/app/build.gradle.kts` | Applied Google services plugin |
| `ios/Podfile` | Added static linkage fix for Firebase, iOS platform 13.0 |

---

## Firebase Configuration

### Firebase Project Details

| Property | Value |
|----------|-------|
| **Project ID** | `aji-tfarraj` |
| **Project Number** | `600996591716` |
| **Storage Bucket** | `aji-tfarraj.firebasestorage.app` |

### Android Configuration

| Property | Value |
|----------|-------|
| **Package Name** | `com.ajitfarraj.aji_tfarraj` |
| **App ID** | `1:600996591716:android:c408a5cfb10172a6728771` |
| **API Key** | `AIzaSyCuYhmJhfJFbH2etFL60WCN_2bSK2OsRvo` |
| **Config File** | `android/app/google-services.json` |

### iOS Configuration

| Property | Value |
|----------|-------|
| **Bundle ID** | `com.ajitfarraj.ajiTfarraj` |
| **App ID** | `1:600996591716:ios:27e2a179987a6331728771` |
| **API Key** | `AIzaSyBRbKSIKFb5qWrdUer3MznKsaK21efIueg` |
| **Config File** | `ios/GoogleService-Info.plist` |

### Android Gradle Configuration

**Project-level** (`android/build.gradle.kts`):
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.4" apply false
}
```

**App-level** (`android/app/build.gradle.kts`):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // Applied here
}
```

### iOS Podfile Configuration

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks! :linkage => :static  # Required for Firebase

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Fix for Firebase non-modular header issue
    target.build_configurations.each do |config|
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end
```

---

## Flutter Implementation

### Dependencies (pubspec.yaml)

```yaml
dependencies:
  firebase_core: ^2.32.0
  firebase_messaging: ^14.9.4
  flutter_local_notifications: ^16.3.3
  shared_preferences: ^2.2.2
```

### Initialization Flow (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 3. Initialize Push Service
  await PushService.instance.init();
  
  // 4. Run app with provider overrides
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const AjiTfarrajApp(),
    ),
  );
}
```

### Riverpod Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `pushServiceProvider` | `Provider<PushService>` | PushService singleton instance |
| `pushTokenProvider` | `StateNotifierProvider` | FCM token state management |
| `fcmTokenProvider` | `Provider<String?>` | Current FCM token accessor |
| `notificationsProvider` | `StateNotifierProvider` | Notifications list state |
| `unreadNotificationsCountProvider` | `Provider<int>` | Unread count for badges |
| `hasUnreadNotificationsProvider` | `Provider<bool>` | Boolean for unread status |
| `notificationRepositoryProvider` | `Provider` | Local storage repository |
| `deviceRepositoryProvider` | `Provider` | Backend registration repository |
| `sharedPreferencesProvider` | `Provider` | SharedPreferences instance |

### Notification Types

```dart
enum NotificationType {
  reservation,  // Reservation-related notifications
  ticket,       // Ticket-related notifications
  system,       // System announcements
  unknown,      // Fallback for unrecognized types
}
```

### AppNotification Model

```dart
class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? reservationId;
  final String? ticketCode;
  final String? deepLink;
  final DateTime receivedAt;
  final bool isRead;
  final Map<String, dynamic> rawData;
}
```

---

## Backend API Requirements

### POST /api/devices/register

Register a device token for push notifications.

**Headers:**
```
Authorization: Bearer {user_auth_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "token": "fcm_device_token_string",
  "platform": "ios",
  "device_name": "iPhone 14 Pro"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `token` | string | Yes | FCM device token |
| `platform` | string | Yes | `"ios"` or `"android"` |
| `device_name` | string | No | Human-readable device name |

**Response (Success - 200/201):**
```json
{
  "success": true,
  "device_id": "uuid-of-registered-device"
}
```

### DELETE /api/devices/unregister

Unregister a device token (called on logout).

**Headers:**
```
Authorization: Bearer {user_auth_token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "token": "fcm_device_token_string"
}
```

**Response (Success - 200):**
```json
{
  "success": true
}
```

### Backend Implementation Notes

1. **Store tokens per user** - One user can have multiple devices
2. **Handle token updates** - Same device may get a new token
3. **Remove stale tokens** - When FCM returns "not registered" error
4. **Send targeted notifications** - Use stored tokens to send to specific users

---

## Notification Payload Formats

### Reservation Notification

```json
{
  "notification": {
    "title": "Réservation confirmée",
    "body": "Votre réservation pour 'Emission XYZ' est confirmée"
  },
  "data": {
    "type": "reservation",
    "reservation_id": "123",
    "title": "Réservation confirmée",
    "body": "Votre réservation pour 'Emission XYZ' est confirmée"
  }
}
```

### Ticket Ready Notification

```json
{
  "notification": {
    "title": "Votre billet est prêt",
    "body": "Téléchargez votre billet pour 'Emission XYZ'"
  },
  "data": {
    "type": "ticket",
    "ticket_code": "ABC123",
    "title": "Votre billet est prêt",
    "body": "Téléchargez votre billet pour 'Emission XYZ'"
  }
}
```

### System Notification

```json
{
  "notification": {
    "title": "Mise à jour importante",
    "body": "Une nouvelle version de l'application est disponible"
  },
  "data": {
    "type": "system",
    "title": "Mise à jour importante",
    "body": "Une nouvelle version de l'application est disponible"
  }
}
```

### Deep Link Notification

```json
{
  "notification": {
    "title": "Nouveau spectacle",
    "body": "Découvrez notre nouveau spectacle"
  },
  "data": {
    "type": "reservation",
    "deep_link": "/show/456",
    "title": "Nouveau spectacle",
    "body": "Découvrez notre nouveau spectacle"
  }
}
```

---

## Deep Linking

### Supported Routes

| Route Pattern | Description |
|---------------|-------------|
| `/home` | Home screen |
| `/my-reservations` | My reservations list |
| `/ticket` | Ticket screen |
| `/profile` | Profile screen |
| `/notifications` | Notification center |
| `/show/{showId}` | Show detail screen |
| `/reservation/{reservationId}` | Reservation detail screen |
| `/reservation-result/{reservationId}` | Reservation result screen |

### Deep Link Formats Supported

```
/reservation/123           → Reservation detail
/show/456                  → Show detail
ajitfarraj://show/456      → App scheme URL
https://app.ajitfarraj.com/show/456  → Web URL
```

### Navigation Priority

1. **Deep link** (if provided in payload)
2. **Type-based routing**:
   - `reservation` → `/reservation/{id}` or `/my-reservations`
   - `ticket` → `/ticket`
   - `system` → `/home`
   - `unknown` → `/home`

---

## Testing Guide

### Testing on Simulator (Limited)

⚠️ **Push notifications do NOT work on iOS Simulator** - APNs is not supported.

The app will run but FCM token retrieval will fail silently.

### Testing on Physical Device

1. **Build and run on device:**
   ```bash
   flutter run -d <device_id>
   ```

2. **Send test notification from Firebase Console:**
   - Go to Firebase Console → Cloud Messaging
   - Click "Send your first message"
   - Enter title and body
   - Target your app
   - Send test message

3. **Send test notification via FCM API:**
   ```bash
   curl -X POST \
     -H "Authorization: Bearer <SERVER_KEY>" \
     -H "Content-Type: application/json" \
     -d '{
       "to": "<FCM_DEVICE_TOKEN>",
       "notification": {
         "title": "Test Notification",
         "body": "This is a test"
       },
       "data": {
         "type": "reservation",
         "reservation_id": "123"
       }
     }' \
     https://fcm.googleapis.com/fcm/send
   ```

### Testing Scenarios

| Scenario | Expected Behavior |
|----------|-------------------|
| App in foreground | Material banner + local notification |
| App in background | System notification, tap opens app and navigates |
| App terminated | System notification, tap launches app and navigates |
| Notification tap | Marks as read, navigates to appropriate screen |
| Badge count | Updates in real-time on bell icon |

---

## Troubleshooting

### Common Issues

#### 1. Firebase initialization fails

**Error:** `Firebase app has not been initialized`

**Solution:** Ensure `Firebase.initializeApp()` is called before any Firebase services.

#### 2. iOS build fails with non-modular header error

**Error:** `Include of non-modular header inside framework module`

**Solution:** Add to `ios/Podfile`:
```ruby
use_frameworks! :linkage => :static

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end
```

#### 3. FCM token is null

**Possible causes:**
- Running on simulator (not supported)
- Firebase not properly configured
- Network connectivity issues

**Solution:** Test on physical device with proper Firebase setup.

#### 4. Notifications not appearing on iOS

**Checklist:**
- ✅ Push Notifications capability added in Xcode
- ✅ Background Modes → Remote notifications enabled
- ✅ APNs key uploaded to Firebase Console
- ✅ Running on physical device (not simulator)

#### 5. Android notifications not showing

**Checklist:**
- ✅ `google-services.json` in `android/app/`
- ✅ Google services plugin applied in Gradle
- ✅ Notification channel created
- ✅ App has notification permissions

---

## iOS Xcode Configuration Required

### Add Capabilities in Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Click **+ Capability**
5. Add:
   - **Push Notifications**
   - **Background Modes** → Check **Remote notifications**

### Upload APNs Key to Firebase

1. Go to [Apple Developer Portal](https://developer.apple.com)
2. Create APNs Authentication Key
3. Download the `.p8` file
4. Go to Firebase Console → Project Settings → Cloud Messaging
5. Upload the APNs key under "Apple app configuration"

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-05 | 1.0.0 | Initial implementation |

---

## Contributors

- **Mobile Development**: Push notification system implementation
- **Backend (TODO)**: Device registration endpoints required from Abdellah
