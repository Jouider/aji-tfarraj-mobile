# Push Notifications System - Technical Documentation

## Overview

This document describes the complete push notification system implemented for the **Aji Tfarraj** mobile application. The system uses Firebase Cloud Messaging (FCM) for both iOS and Android platforms.

**Backend Status: ✅ PRODUCTION READY**
- Backend URL: `https://aji-tfarraj-backend-production.up.railway.app`
- Device registration endpoint: `POST /api/devices/register`
- Push notifications sent automatically when reservation is approved

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Files Structure](#files-structure)
3. [Firebase Configuration](#firebase-configuration)
4. [Flutter Implementation](#flutter-implementation)
5. [Backend API (Production)](#backend-api-production)
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
│              PRODUCTION BACKEND (Railway)                        │
│      https://aji-tfarraj-backend-production.up.railway.app      │
│                                                                  │
│  POST /api/devices/register    ← Register FCM token             │
│  DELETE /api/devices/unregister ← Unregister on logout          │
│                                                                  │
│  PushNotificationService → Sends FCM when reservation approved  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Files Structure

### Push Notification Files

| File Path | Purpose |
|-----------|---------|
| `lib/app/push/push_service.dart` | Main FCM service (handles all notification events) |
| `lib/app/push/push_router.dart` | Deep link navigation handler |
| `lib/app/push/push_token_provider.dart` | FCM token state management & backend registration |
| `lib/app/push/device_repository.dart` | Backend API calls for device registration |

### Notification Feature Files

| File Path | Purpose |
|-----------|---------|
| `lib/features/notifications/domain/app_notification.dart` | Notification data model |
| `lib/features/notifications/data/notification_repository.dart` | Local storage persistence |
| `lib/features/notifications/presentation/providers/notifications_provider.dart` | Riverpod state management |
| `lib/features/notifications/presentation/notification_center_screen.dart` | Notification center UI |
| `lib/features/notifications/presentation/widgets/notification_card.dart` | Notification card widget |

### Modified Files

| File Path | Changes Made |
|-----------|--------------|
| `lib/features/auth/data/auth_repository.dart` | Registers device token after login/registration, clears on logout |
| `lib/main.dart` | Firebase initialization, SharedPreferences override, PushService setup |

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
| `isTokenRegisteredProvider` | `Provider<bool>` | Check if token registered with backend |
| `notificationsProvider` | `StateNotifierProvider` | Notifications list state |
| `unreadNotificationsCountProvider` | `Provider<int>` | Unread count for badges |
| `hasUnreadNotificationsProvider` | `Provider<bool>` | Boolean for unread status |
| `deviceRepositoryProvider` | `Provider` | Backend registration repository |

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

## Backend API (Production)

### POST /api/devices/register

Register a device token for push notifications. **Called automatically after login/registration.**

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

**Backend Behavior:**
- Saves FCM token into `devices` table
- Associates token with authenticated user
- Updates existing token if already exists
- Removes invalid tokens automatically when detected

### DELETE /api/devices/unregister

Unregister a device token. **Called automatically on logout.**

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

---

## Notification Payload Formats

The backend sends notifications in three formats:

### Format A: Reservation Notification
```json
{
  "type": "reservation",
  "reservation_id": "123",
  "title": "Réservation confirmée",
  "body": "Votre billet est prêt"
}
```
**Navigation:** `/reservation/123`

### Format B: Ticket Notification
```json
{
  "type": "ticket",
  "title": "Votre billet est prêt",
  "body": "Vous pouvez accéder à votre billet"
}
```
**Navigation:** `/ticket`

### Format C: Deep Link Notification
```json
{
  "deep_link": "/reservation/123"
}
```
**Navigation:** Uses the provided deep link directly

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

### Navigation Priority

1. **Deep link** (if `deep_link` provided in payload)
2. **Type-based routing**:
   - `type: "reservation"` + `reservation_id` → `/reservation/{id}`
   - `type: "reservation"` (no id) → `/my-reservations`
   - `type: "ticket"` → `/ticket`
   - `type: "system"` → `/home`

---

## Testing Guide

### Testing on Physical Device (Required for Real Push)

1. **Connect device via USB**
2. **Run the app:**
   ```bash
   flutter run -d <device_id>
   ```
3. **Login to the app** - device token will be registered automatically
4. **Check console logs for:**
   ```
   [PushTokenNotifier] FCM Token obtained: ...
   [DeviceRepository] Registering device with backend: platform=ios
   [DeviceRepository] Device registered successfully with backend
   ```
5. **Trigger a notification from backend** (approve a reservation)

### Testing Notification UI (Simulator)

Even without real push notifications, you can test:
- ✅ Notification Center screen (`/notifications`)
- ✅ Bell icon with badge
- ✅ Mark as read functionality
- ✅ Delete notifications

### Console Logs to Verify

**On Login:**
```
[PushTokenNotifier] FCM Token obtained: abc123...
[DeviceRepository] Registering device with backend: platform=ios
[DeviceRepository] Device registered successfully with backend
[PushTokenNotifier] Backend registration: success
```

**On Push Received (Foreground):**
```
[PushService] Foreground message received: msg123
[PushService] Showing foreground notification
```

**On Push Tap:**
```
[PushRouter] Navigating to route: /reservation/123
```

**On Logout:**
```
[PushTokenNotifier] Token cleared and unregistered
[DeviceRepository] Device unregistered successfully
```

---

## Troubleshooting

### FCM Token is null

**Possible causes:**
- Running on iOS simulator (APNs not supported)
- Push Notifications capability not added in Xcode
- Firebase not properly configured

**Solution:** Test on physical device with proper setup.

### Device registration returns 401

**Cause:** User not authenticated or token expired.

**Solution:** Device registration only works for authenticated users. Ensure login was successful.

### Notifications not appearing

**iOS Checklist:**
- ✅ Push Notifications capability in Xcode
- ✅ Background Modes → Remote notifications
- ✅ APNs key uploaded to Firebase Console
- ✅ Physical device (not simulator)

**Android Checklist:**
- ✅ `google-services.json` in `android/app/`
- ✅ Google services plugin applied
- ✅ Notification channel created

### Token not refreshing

The `onTokenRefresh` listener automatically handles token refresh. If issues persist:
```dart
// Manual refresh
ref.read(pushTokenProvider.notifier).refreshToken();
```

---

## TODO(Backend - Abdellah)

This endpoint is implemented in production.
In staging environment, ensure FIREBASE credentials are configured:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_PRIVATE_KEY`
- `FIREBASE_CLIENT_EMAIL`

---

## Version History

| Date | Version | Changes |
|------|---------|---------|
| 2026-02-06 | 1.1.0 | Production backend integration |
| 2026-02-05 | 1.0.0 | Initial implementation |

---

## Contributors

- **Mobile Development**: Push notification system implementation
- **Backend (TODO)**: Device registration endpoints required from Abdellah
