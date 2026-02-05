# Aji Tfarraj API Documentation

API contract for mobile (Flutter) and frontend (SPA) developers.

---

## General Information

| Property | Value |
|----------|-------|
| Base URL (Production) | `https://aji-tfarraj-backend-production.up.railway.app` |
| Base URL (Local) | `http://localhost:8000` |
| Content-Type | `application/json` |
| Authentication | Bearer Token (Sanctum) |

### Postman Collection

For quick API testing, import the Postman collection and environment files:

| File | Description |
|------|-------------|
| [aji-tfarraj.postman_collection.json](postman/aji-tfarraj.postman_collection.json) | Complete API collection with all endpoints and test scripts |
| [aji-tfarraj.postman_environment.json](postman/aji-tfarraj.postman_environment.json) | Production environment variables |
| [aji-tfarraj-local.postman_environment.json](postman/aji-tfarraj-local.postman_environment.json) | Local development environment variables |

**Quick Start:**
1. Import the collection file into Postman
2. Import the environment file (production or local)
3. Select the environment from the dropdown
4. Run "Login (Client)" to authenticate
5. Start testing endpoints!

### Admin Panel

| Property | Value |
|----------|-------|
| URL | `https://aji-tfarraj-backend-production.up.railway.app/admin` |
| Email | `admin@ajitfarraj.ma` |
| Password | `Admin@2026!` |

> **Note:** Only users with `admin` role can access the Filament admin panel.

### Required Headers

```http
Accept: application/json
Content-Type: application/json
```

For protected endpoints, add:

```http
Authorization: Bearer <token>
```

---

## User Roles

The API supports three user roles:

| Role | Value | Description |
|------|-------|-------------|
| Client | `client` | Default role for mobile app users. Can create reservations, view shows, etc. |
| Staff | `staff` | Staff members who can perform check-ins at events. |
| Admin | `admin` | Administrators with full access to Filament panel and all API endpoints. |

### Role-based Access

| Endpoint Type | Allowed Roles |
|---------------|---------------|
| Public endpoints | Everyone (no auth required) |
| Protected endpoints | All authenticated users |
| Staff endpoints | `staff`, `admin` |
| Admin panel | `admin` only |

---

## Authentication

### Register

Create a new user account.

```
POST /api/auth/register
```

**Request Body**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| name | string | ✅ | max 100 characters |
| email | string | ✅ | valid email, unique |
| password | string | ✅ | min 8 characters |
| password_confirmation | string | ✅ | must match password |

**Request Example**

```json
{
  "name": "Ahmed Benjelloun",
  "email": "ahmed@example.com",
  "password": "securepass123",
  "password_confirmation": "securepass123"
}
```

**Success Response** `201 Created`

```json
{
  "token": "1|a9b8c7d6e5f4g3h2i1j0k9l8m7n6o5p4q3r2s1t0",
  "user": {
    "id": 1,
    "name": "Ahmed Benjelloun",
    "email": "ahmed@example.com",
    "created_at": "2026-01-30T10:00:00.000000Z",
    "updated_at": "2026-01-30T10:00:00.000000Z"
  }
}
```

**Error Response** `422 Unprocessable Entity`

```json
{
  "message": "The email has already been taken.",
  "errors": {
    "email": ["The email has already been taken."]
  }
}
```

---

### Login

Authenticate and receive a token.

```
POST /api/auth/login
```

**Request Body**

| Field | Type | Required |
|-------|------|----------|
| email | string | ✅ |
| password | string | ✅ |

**Request Example**

```json
{
  "email": "ahmed@example.com",
  "password": "securepass123"
}
```

**Success Response** `200 OK`

```json
{
  "token": "2|x1y2z3a4b5c6d7e8f9g0h1i2j3k4l5m6n7o8p9q0",
  "user": {
    "id": 1,
    "name": "Ahmed Benjelloun",
    "email": "ahmed@example.com",
    "created_at": "2026-01-30T10:00:00.000000Z",
    "updated_at": "2026-01-30T10:00:00.000000Z"
  }
}
```

**Error Response** `401 Unauthorized`

```json
{
  "message": "Invalid credentials"
}
```

---

### Get Current User

Retrieve the authenticated user's profile.

```
GET /api/auth/me
```

🔒 **Requires Authentication**

**Success Response** `200 OK`

```json
{
  "id": 1,
  "name": "Ahmed Benjelloun",
  "email": "ahmed@example.com",
  "email_verified_at": null,
  "created_at": "2026-01-30T10:00:00.000000Z",
  "updated_at": "2026-01-30T10:00:00.000000Z"
}
```

**Error Response** `401 Unauthorized`

```json
{
  "message": "Unauthenticated."
}
```

---

### Logout

Revoke the current access token.

```
POST /api/auth/logout
```

🔒 **Requires Authentication**

**Success Response** `200 OK`

```json
{
  "message": "Logged out"
}
```

---

## Shows

### List Shows

Get paginated list of upcoming active shows with optional filters and search.

```
GET /api/shows
```

🌐 **Public**

**Query Parameters**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| page | integer | ❌ | 1 | Page number |
| per_page | integer | ❌ | 10 | Items per page (max: 50) |
| city | string | ❌ | - | Filter by city (case-insensitive exact match) |
| channel | string | ❌ | - | Filter by channel (case-insensitive exact match) |
| q | string | ❌ | - | Search in title and description (partial match) |

**Request Examples**

```
GET /api/shows
GET /api/shows?page=2&per_page=5
GET /api/shows?city=Casablanca
GET /api/shows?channel=2M
GET /api/shows?q=Lalla
GET /api/shows?city=Casablanca&channel=2M&q=show&per_page=10
```

**Default Constraints**

- Only shows where `is_active = true`
- Only future shows (`starts_at >= now()`)
- Ordered by `starts_at` ascending

**Success Response** `200 OK`

```json
{
  "current_page": 1,
  "data": [
    {
      "id": 1,
      "title": "Lalla Laaroussa",
      "description": "برنامج ترفيهي يجمع بين الألعاب والمفاجآت",
      "channel": "2M",
      "city": "Casablanca",
      "studio": "Studio 2M Ain Sebaa",
      "starts_at": "2026-02-15T20:00:00.000000Z",
      "capacity": 150,
      "reserved_seats": 45,
      "is_active": true,
      "image_url": "https://aji-tfarraj-backend-production.up.railway.app/media/shows/lalla-laaroussa.jpg",
      "created_at": "2026-01-15T09:00:00.000000Z",
      "updated_at": "2026-01-20T14:30:00.000000Z"
    },
    {
      "id": 2,
      "title": "Rachid Show",
      "description": "برنامج حواري كوميدي مع النجم رشيد",
      "channel": "Al Aoula",
      "city": "Rabat",
      "studio": "Studio SNRT Rabat",
      "starts_at": "2026-02-20T21:30:00.000000Z",
      "capacity": 200,
      "reserved_seats": 78,
      "is_active": true,
      "image_url": null,
      "created_at": "2026-01-10T11:00:00.000000Z",
      "updated_at": "2026-01-25T16:45:00.000000Z"
    }
  ],
  "first_page_url": "https://api.example.com/api/shows?page=1",
  "from": 1,
  "last_page": 3,
  "last_page_url": "https://api.example.com/api/shows?page=3",
  "links": [
    { "url": null, "label": "&laquo; Previous", "active": false },
    { "url": "https://api.example.com/api/shows?page=1", "label": "1", "active": true },
    { "url": "https://api.example.com/api/shows?page=2", "label": "2", "active": false },
    { "url": "https://api.example.com/api/shows?page=3", "label": "3", "active": false },
    { "url": "https://api.example.com/api/shows?page=2", "label": "Next &raquo;", "active": false }
  ],
  "next_page_url": "https://api.example.com/api/shows?page=2",
  "path": "https://api.example.com/api/shows",
  "per_page": 10,
  "prev_page_url": null,
  "to": 10,
  "total": 25
}
```

**Empty Response** `200 OK`

```json
{
  "current_page": 1,
  "data": [],
  "first_page_url": "https://api.example.com/api/shows?page=1",
  "from": null,
  "last_page": 1,
  "last_page_url": "https://api.example.com/api/shows?page=1",
  "links": [
    { "url": null, "label": "&laquo; Previous", "active": false },
    { "url": "https://api.example.com/api/shows?page=1", "label": "1", "active": true },
    { "url": null, "label": "Next &raquo;", "active": false }
  ],
  "next_page_url": null,
  "path": "https://api.example.com/api/shows",
  "per_page": 10,
  "prev_page_url": null,
  "to": null,
  "total": 0
}
```

**Validation Error Response** `422 Unprocessable Entity`

```json
{
  "message": "The per page field must not be greater than 50.",
  "errors": {
    "per_page": ["The per page field must not be greater than 50."]
  }
}
```

---

### Get Show Details

Get details of a specific show.

```
GET /api/shows/{id}
```

🌐 **Public**

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | Show ID |

**Success Response** `200 OK`

```json
{
  "id": 1,
  "title": "Lalla Laaroussa",
  "description": "برنامج ترفيهي يجمع بين الألعاب والمفاجآت",
  "channel": "2M",
  "city": "Casablanca",
  "studio": "Studio 2M Ain Sebaa",
  "starts_at": "2026-02-15T20:00:00.000000Z",
  "capacity": 150,
  "reserved_seats": 45,
  "is_active": true,
  "image_url": "https://aji-tfarraj-backend-production.up.railway.app/storage/shows/lalla-laaroussa.jpg",
  "created_at": "2026-01-15T09:00:00.000000Z",
  "updated_at": "2026-01-20T14:30:00.000000Z"
}
```

**Error Response** `404 Not Found`

```json
{
  "message": "No query results for model [Show]."
}
```

---

## Reservations

### Create Reservation

Submit a reservation request for a show.

```
POST /api/reservations
```

🔒 **Requires Authentication**

**Request Body**

| Field | Type | Required | Rules |
|-------|------|----------|-------|
| show_id | integer | ✅ | must exist in shows |
| seats | integer | ✅ | min: 1, max: 4 |

**Request Example**

```json
{
  "show_id": 1,
  "seats": 2
}
```

**Success Response** `201 Created`

```json
{
  "id": 15,
  "user_id": 1,
  "show_id": 1,
  "seats": 2,
  "status": "pending_review",
  "expires_at": null,
  "rejection_reason": null,
  "created_at": "2026-01-30T12:00:00.000000Z",
  "updated_at": "2026-01-30T12:00:00.000000Z"
}
```

**Validation Error Response** `422 Unprocessable Entity`

```json
{
  "message": "The show id field is required.",
  "errors": {
    "show_id": ["The show id field is required."],
    "seats": ["The seats field must be at least 1."]
  }
}
```

---

### List My Reservations

Get all reservations for the authenticated user.

```
GET /api/me/reservations
```

🔒 **Requires Authentication**

**Success Response** `200 OK`

```json
[
  {
    "id": 15,
    "user_id": 1,
    "show_id": 1,
    "seats": 2,
    "status": "approved",
    "expires_at": null,
    "rejection_reason": null,
    "created_at": "2026-01-30T12:00:00.000000Z",
    "updated_at": "2026-01-30T14:00:00.000000Z",
    "show": {
      "id": 1,
      "title": "Lalla Laaroussa",
      "description": "برنامج ترفيهي يجمع بين الألعاب والمفاجآت",
      "channel": "2M",
      "city": "Casablanca",
      "studio": "Studio 2M Ain Sebaa",
      "starts_at": "2026-02-15T20:00:00.000000Z",
      "capacity": 150,
      "reserved_seats": 47,
      "is_active": true,
      "created_at": "2026-01-15T09:00:00.000000Z",
      "updated_at": "2026-01-30T14:00:00.000000Z"
    }
  },
  {
    "id": 12,
    "user_id": 1,
    "show_id": 2,
    "seats": 1,
    "status": "rejected",
    "expires_at": null,
    "rejection_reason": "No more seats available for this date.",
    "created_at": "2026-01-25T10:00:00.000000Z",
    "updated_at": "2026-01-26T09:00:00.000000Z",
    "show": {
      "id": 2,
      "title": "Rachid Show",
      "description": "برنامج حواري كوميدي مع النجم رشيد",
      "channel": "Al Aoula",
      "city": "Rabat",
      "studio": "Studio SNRT Rabat",
      "starts_at": "2026-02-20T21:30:00.000000Z",
      "capacity": 200,
      "reserved_seats": 200,
      "is_active": true,
      "created_at": "2026-01-10T11:00:00.000000Z",
      "updated_at": "2026-01-26T09:00:00.000000Z"
    }
  }
]
```

> **Note:** Results are ordered by `created_at` descending (most recent first).

---

### Get Reservation Details

Get details of a specific reservation.

```
GET /api/reservations/{id}
```

🔒 **Requires Authentication**

⚠️ **Authorization:** User must own this reservation.

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | Reservation ID |

**Success Response** `200 OK`

```json
{
  "id": 15,
  "user_id": 1,
  "show_id": 1,
  "seats": 2,
  "status": "approved",
  "expires_at": null,
  "rejection_reason": null,
  "created_at": "2026-01-30T12:00:00.000000Z",
  "updated_at": "2026-01-30T14:00:00.000000Z",
  "show": {
    "id": 1,
    "title": "Lalla Laaroussa",
    "description": "برنامج ترفيهي يجمع بين الألعاب والمفاجآت",
    "channel": "2M",
    "city": "Casablanca",
    "studio": "Studio 2M Ain Sebaa",
    "starts_at": "2026-02-15T20:00:00.000000Z",
    "capacity": 150,
    "reserved_seats": 47,
    "is_active": true,
    "created_at": "2026-01-15T09:00:00.000000Z",
    "updated_at": "2026-01-30T14:00:00.000000Z"
  },
  "ticket": {
    "id": 8,
    "reservation_id": 15,
    "ticket_code": "AT-2026-000008",
    "qr_token": "550e8400-e29b-41d4-a716-446655440000",
    "generated_at": "2026-01-30T14:00:00.000000Z",
    "checked_in_at": null,
    "created_at": "2026-01-30T14:00:00.000000Z",
    "updated_at": "2026-01-30T14:00:00.000000Z"
  }
}
```

> **Note:** The `ticket` field is `null` if the reservation is not yet approved.

**Error Response** `403 Forbidden`

```json
{
  "message": "Forbidden"
}
```

**Error Response** `404 Not Found`

```json
{
  "message": "No query results for model [Reservation]."
}
```

---

### Cancel Reservation

Cancel a pending reservation.

```
POST /api/reservations/{id}/cancel
```

🔒 **Requires Authentication**

⚠️ **Authorization:** User must own this reservation.

⚠️ **Allowed only when status is:** `pending_review` or `contacting`

**Path Parameters**

| Parameter | Type | Description |
|-----------|------|-------------|
| id | integer | Reservation ID |

**Success Response** `200 OK`

```json
{
  "message": "Cancelled"
}
```

**Error Response** `403 Forbidden` (not owner)

```json
{
  "message": "Forbidden"
}
```

**Error Response** `422 Unprocessable Entity` (invalid status)

```json
{
  "message": "Reservation cannot be cancelled at this stage"
}
```

---

## Ticket

### Get My Ticket

Get the latest approved ticket for the authenticated user.

```
GET /api/me/ticket
```

🔒 **Requires Authentication**

**Success Response** `200 OK` (ticket exists)

```json
{
  "id": 8,
  "reservation_id": 15,
  "ticket_code": "AT-2026-000008",
  "qr_token": "550e8400-e29b-41d4-a716-446655440000",
  "generated_at": "2026-01-30T14:00:00.000000Z",
  "checked_in_at": null,
  "created_at": "2026-01-30T14:00:00.000000Z",
  "updated_at": "2026-01-30T14:00:00.000000Z",
  "reservation": {
    "id": 15,
    "user_id": 1,
    "show_id": 1,
    "seats": 2,
    "status": "approved",
    "expires_at": null,
    "rejection_reason": null,
    "created_at": "2026-01-30T12:00:00.000000Z",
    "updated_at": "2026-01-30T14:00:00.000000Z",
    "show": {
      "id": 1,
      "title": "Lalla Laaroussa",
      "description": "برنامج ترفيهي يجمع بين الألعاب والمفاجآت",
      "channel": "2M",
      "city": "Casablanca",
      "studio": "Studio 2M Ain Sebaa",
      "starts_at": "2026-02-15T20:00:00.000000Z",
      "capacity": 150,
      "reserved_seats": 47,
      "is_active": true,
      "created_at": "2026-01-15T09:00:00.000000Z",
      "updated_at": "2026-01-30T14:00:00.000000Z"
    }
  }
}
```

**Success Response** `200 OK` (no approved ticket)

```json
null
```

---

## Staff Check-in

### Check-in Ticket

Validate and check-in a ticket using QR token or ticket code. This endpoint is used by staff members at the venue entrance.

```
POST /api/staff/check-in
```

🔒 **Requires Authentication**

🛡️ **Requires Role:** `staff` or `admin`

**Request Body**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| qr_token | string | ⚠️ | UUID from QR code scan (required if `ticket_code` not provided) |
| ticket_code | string | ⚠️ | Manual ticket code entry (required if `qr_token` not provided) |

> **Note:** Provide either `qr_token` OR `ticket_code`, not both.

**Request Example (QR Token)**

```json
{
  "qr_token": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Request Example (Ticket Code)**

```json
{
  "ticket_code": "AT-2026-000008"
}
```

**Success Response** `200 OK`

```json
{
  "ticket_code": "AT-2026-000008",
  "checked_in_at": "2026-02-15T19:45:00.000000Z",
  "user": {
    "id": 1,
    "name": "Ahmed Benjelloun",
    "email": "ahmed@example.com"
  },
  "show": {
    "id": 1,
    "title": "Lalla Laaroussa",
    "city": "Casablanca",
    "starts_at": "2026-02-15T20:00:00.000000Z"
  }
}
```

**Error Response** `401 Unauthenticated`

```json
{
  "message": "Unauthenticated."
}
```

**Error Response** `403 Forbidden` (insufficient role)

```json
{
  "message": "Unauthorized. Staff access required."
}
```

**Error Response** `404 Not Found` (invalid token/code)

```json
{
  "message": "Ticket not found"
}
```

**Error Response** `409 Conflict` (already checked-in)

```json
{
  "message": "Ticket already checked in",
  "checked_in_at": "2026-02-15T19:30:00.000000Z"
}
```

**Error Response** `422 Unprocessable Entity` (validation)

```json
{
  "message": "The qr token field is required when ticket code is not present.",
  "errors": {
    "qr_token": ["The qr token field is required when ticket code is not present."]
  }
}
```

---

## Reservation Status Lifecycle

| Status | Description | User Action Available |
|--------|-------------|----------------------|
| `pending_review` | Reservation submitted, awaiting staff review | Can cancel |
| `contacting` | Staff is contacting the user for confirmation | Can cancel |
| `approved` | Reservation confirmed, ticket generated | View ticket |
| `rejected` | Reservation denied by staff (see `rejection_reason`) | Submit new request |
| `cancelled` | User cancelled the reservation | Submit new request |
| `expired` | Reservation expired (not confirmed in time) | Submit new request |
| `checked_in` | User attended the show | — |

### Status Flow Diagram

```
                    ┌──────────────┐
                    │   Created    │
                    └──────┬───────┘
                           │
                           ▼
                  ┌────────────────┐
         ┌───────│ pending_review │───────┐
         │       └────────┬───────┘       │
         │                │               │
    User cancels    Staff reviews    Time expires
         │                │               │
         ▼                ▼               ▼
   ┌───────────┐   ┌────────────┐   ┌─────────┐
   │ cancelled │   │ contacting │   │ expired │
   └───────────┘   └──────┬─────┘   └─────────┘
                          │
            ┌─────────────┼─────────────┐
            │             │             │
       User cancels  Staff approves  Staff rejects
            │             │             │
            ▼             ▼             ▼
      ┌───────────┐ ┌──────────┐ ┌──────────┐
      │ cancelled │ │ approved │ │ rejected │
      └───────────┘ └────┬─────┘ └──────────┘
                         │
                    User attends
                         │
                         ▼
                  ┌────────────┐
                  │ checked_in │
                  └────────────┘
```

---

## Notes for Frontend Developers

### Date Format

All dates are in **ISO 8601** format with timezone:

```
2026-01-30T14:00:00.000000Z
```

Use a date library (e.g., `intl` in Flutter, `dayjs` in JS) to parse and format.

### Required Headers

Always include these headers in every request:

```http
Accept: application/json
Content-Type: application/json
```

### Error Handling

Handle these HTTP status codes gracefully:

| Status | Meaning | Recommended Action |
|--------|---------|-------------------|
| `401` | Unauthenticated | Redirect to login, clear stored token |
| `403` | Forbidden | Show "Access denied" message |
| `404` | Not found | Show "Not found" message |
| `422` | Validation error | Display field-specific errors |
| `500` | Server error | Show generic error, retry later |

### Ticket Screen Logic

```
if (GET /api/me/ticket returns null) {
    Show "No ticket yet" or locked state
    Display reservation status from /api/me/reservations
} else {
    Show ticket with QR code (use qr_token)
    Display ticket_code for manual verification
}
```

### Token Storage

- Store the token securely (Keychain on iOS, EncryptedSharedPreferences on Android)
- Include in all protected requests via `Authorization: Bearer <token>`
- On logout or 401 response, clear the stored token

### Pagination

Currently, list endpoints return all results. Pagination may be added in future versions.

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.3.0 | 2026-02-03 | Added `POST /api/staff/check-in` endpoint for ticket validation |
| 1.2.0 | 2026-01-30 | Added `image_url` field to Show responses (optional show images) |
| 1.1.0 | 2026-01-30 | Added production Railway URL, admin panel credentials |
| 1.0.0 | 2026-01-30 | Initial API release |