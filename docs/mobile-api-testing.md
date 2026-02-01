# Aji Tfarraj Mobile API Testing Checklist

## Setup

1. **Base URL**: `https://aji-tfarraj-backend-production.up.railway.app`
2. **Admin Panel**: `https://aji-tfarraj-backend-production.up.railway.app/admin`
   - Email: `admin@ajitfarraj.ma`
   - Password: `Admin@2026!`

## Testing Flow

### 1. Launch the App
```bash
cd flutter_app
flutter run
```

### 2. Home Screen - Shows List
- [ ] App loads and displays splash screen
- [ ] Navigate to Home screen
- [ ] Shows list loads from API
- [ ] Show cards display:
  - [ ] Image (or placeholder if no image)
  - [ ] Title
  - [ ] City and Channel
  - [ ] Date formatted correctly
  - [ ] Available seats count
  - [ ] "COMPLET" badge if sold out
- [ ] Pull-to-refresh works
- [ ] Tap on show navigates to detail

### 3. Show Detail Screen
- [ ] Hero image displays correctly
- [ ] Show title in app bar
- [ ] Channel badge visible
- [ ] Description text
- [ ] Date, time, location cards
- [ ] Available seats with color (green/red)
- [ ] "Réserver des places" button (disabled if sold out)

### 4. Authentication (Manual Token Setup)
Since login is not fully implemented, set token manually for testing:

```dart
// In your app, temporarily add this to set a token:
final authNotifier = ref.read(authStateProvider.notifier);
await authNotifier.setToken('YOUR_TOKEN_HERE');
```

Or use the admin panel to:
1. Register a user via API
2. Login to get token
3. Use token for authenticated requests

### 5. Reserve Seats
- [ ] Navigate from show detail to reserve screen
- [ ] Show info card displays correctly
- [ ] Seat selector: +/- buttons work
- [ ] Cannot exceed 4 seats or available seats
- [ ] Info message about approval process
- [ ] Submit reservation
- [ ] Success screen appears
- [ ] Navigate to My Reservations

### 6. My Reservations Screen
- [ ] List loads from `/api/me/reservations`
- [ ] Each reservation shows:
  - [ ] Show title
  - [ ] City
  - [ ] Status badge with correct color
  - [ ] Seats count
  - [ ] Show date
  - [ ] Created date
- [ ] Rejected reservations show rejection reason
- [ ] Tap navigates to detail

### 7. Reservation Detail Screen
- [ ] Status card with icon and message
- [ ] Show information
- [ ] Reservation details (ID, seats, date)
- [ ] If rejected: show rejection reason
- [ ] If approved: "Voir mon billet" button
- [ ] If pending: "Annuler la réservation" button
- [ ] Cancel dialog works

### 8. Admin Approval Flow
1. Login to admin panel
2. Find the reservation
3. Change status to "approved"
4. Refresh My Reservations in app
5. Status should update to "Approuvée"

### 9. Ticket Screen
- [ ] If no approved ticket: shows locked view
- [ ] Pull-to-refresh works
- [ ] After approval:
  - [ ] Ticket card appears
  - [ ] Green header "Billet valide"
  - [ ] Show info (title, date, time, location)
  - [ ] QR code generated from `qr_token`
  - [ ] Ticket code displayed
  - [ ] "Présentez ce QR code" message
- [ ] If checked in:
  - [ ] Teal header "Billet utilisé"
  - [ ] Check-in date displayed

### 10. Error Handling
- [ ] Network error shows retry button
- [ ] 401 error handled (unauthenticated)
- [ ] 404 shows not found message
- [ ] 422 validation errors displayed

## Status Mapping Reference

| API Status | French Label | Color |
|------------|--------------|-------|
| `pending_review` | En attente | Orange |
| `contacting` | En cours d'appel | Blue |
| `approved` | Approuvée | Green |
| `rejected` | Refusée | Red |
| `cancelled` | Annulée | Grey |
| `expired` | Expirée | Brown |
| `checked_in` | Check-in effectué | Teal |

## Common Issues

1. **401 Unauthenticated**: Token expired or missing. Re-login.
2. **Images not loading**: Check `image_url` in API response.
3. **Dates showing wrong**: Ensure timezone handling with `.toLocal()`.
4. **QR not scanning**: Verify `qr_token` UUID format.

## API Endpoints Used

| Screen | Endpoint | Auth |
|--------|----------|------|
| Home | `GET /api/shows` | No |
| Show Detail | `GET /api/shows/{id}` | No |
| My Reservations | `GET /api/me/reservations` | Yes |
| Create Reservation | `POST /api/reservations` | Yes |
| Cancel Reservation | `POST /api/reservations/{id}/cancel` | Yes |
| My Ticket | `GET /api/me/ticket` | Yes |
