# Shopping List API Documentation

> **Base URL:** `http://localhost:3000`
> **API Version:** v1
> **Authentication:** OAuth 2.0 Bearer Token

---

## Table of Contents

1. [Authentication](#authentication)
   - [Register](#register)
   - [Confirm Email](#confirm-email)
   - [Resend Confirmation](#resend-confirmation)
   - [Login (Get Token)](#login-get-token)
2. [Catalog](#catalog)
   - [Categories](#categories)
   - [Unit Types](#unit-types)
   - [Items](#items)
3. [Households](#households)
   - [Household Management](#household-management)
   - [Members](#members)
   - [Invitations (Owner)](#invitations-owner)
   - [Invitations (Invitee)](#invitations-invitee)
4. [Shopping Lists](#shopping-lists)
   - [List Management](#list-management)
   - [List Items](#list-items)
5. [Error Responses](#error-responses)
6. [Authorization Matrix](#authorization-matrix)

---

## Authentication

All protected endpoints require the `Authorization` header:

```
Authorization: Bearer <access_token>
```

### Register

Creates a new user account and sends a 6-digit OTP to their email.

**Endpoint:** `POST /api/v1/auth/register`
**Auth Required:** No

**Request Body:**
```json
{
  "user": {
    "email": "user@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

**Success Response:** `201 Created`
```json
{
  "data": {
    "id": "1",
    "type": "user",
    "attributes": {
      "email": "user@example.com",
      "email_confirmed": false,
      "created_at": "2024-02-09T12:00:00.000Z"
    }
  }
}
```

---

### Confirm Email

Verifies the OTP code and activates the user account.

**Endpoint:** `POST /api/v1/auth/confirm`
**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com",
  "otp": "847291"
}
```

**Success Response:** `200 OK`
```json
{
  "message": "Email confirmed successfully"
}
```

**Configuration:**
| Setting | Value |
|---------|-------|
| OTP Expiration | 10 minutes |
| Max Failed Attempts | 5 |

---

### Resend Confirmation

Sends a new OTP code to the user's email.

**Endpoint:** `POST /api/v1/auth/resend_confirmation`
**Auth Required:** No

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Success Response:** `200 OK`
```json
{
  "message": "Confirmation email sent"
}
```

**Rate Limit:** 1 request per minute

---

### Login (Get Token)

Obtains an OAuth access token. Only works for confirmed users.

**Endpoint:** `POST /oauth/token`
**Auth Required:** No

**Request Body:**
```json
{
  "grant_type": "password",
  "username": "user@example.com",
  "password": "password123",
  "client_id": "<application_uid>",
  "client_secret": "<application_secret>"
}
```

**Success Response:** `200 OK`
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiJ9...",
  "token_type": "Bearer",
  "expires_in": 2592000,
  "created_at": 1707480000
}
```

---

## Catalog

### Categories

#### List Categories

**Endpoint:** `GET /api/v1/categories`
**Auth Required:** Yes

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "category",
      "attributes": {
        "name": "Dairy",
        "created_at": "2024-02-09T12:00:00.000Z"
      }
    }
  ]
}
```

#### Get Category

**Endpoint:** `GET /api/v1/categories/:id`
**Auth Required:** Yes

---

### Unit Types

#### List Unit Types

**Endpoint:** `GET /api/v1/unit_types`
**Auth Required:** Yes

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "unit_type",
      "attributes": {
        "name": "Kilogram",
        "abbreviation": "kg"
      }
    }
  ]
}
```

#### Get Unit Type

**Endpoint:** `GET /api/v1/unit_types/:id`
**Auth Required:** Yes

---

### Items

#### List Items

**Endpoint:** `GET /api/v1/items`
**Auth Required:** Yes

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `search` | string | Filter by name (case-insensitive) |
| `category_id` | integer | Filter by category |
| `page` | integer | Page number for pagination |

**Example:** `GET /api/v1/items?search=milk&category_id=1`

#### Get Item

**Endpoint:** `GET /api/v1/items/:id`
**Auth Required:** Yes

#### Create Item

**Endpoint:** `POST /api/v1/items`
**Auth Required:** Yes

**Request Body:**
```json
{
  "item": {
    "name": "Oat Milk",
    "category_id": 1,
    "default_unit_type_id": 1
  }
}
```

**Note:** Custom items are created with `is_default: false`

#### Update Item

**Endpoint:** `PUT /api/v1/items/:id`
**Auth Required:** Yes

**Note:** Default items cannot be modified.

#### Delete Item

**Endpoint:** `DELETE /api/v1/items/:id`
**Auth Required:** Yes

**Note:** Default items cannot be deleted.

---

## Households

### Household Management

#### List My Households

Returns all households where the current user is a member or owner.

**Endpoint:** `GET /api/v1/households`
**Auth Required:** Yes

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "household",
      "attributes": {
        "name": "Smith Family",
        "created_at": "2024-02-09T12:00:00.000Z"
      },
      "relationships": {
        "owner": {
          "data": { "id": "1", "type": "user" }
        }
      }
    }
  ]
}
```

#### Create Household

Creates a new household. The current user becomes the owner.

**Endpoint:** `POST /api/v1/households`
**Auth Required:** Yes

**Request Body:**
```json
{
  "household": {
    "name": "Smith Family"
  }
}
```

**Success Response:** `201 Created`

**Note:** Users can only own one household.

#### Get Household

**Endpoint:** `GET /api/v1/households/:id`
**Auth Required:** Yes (member or owner)

#### Update Household

**Endpoint:** `PUT /api/v1/households/:id`
**Auth Required:** Yes (owner only)

**Request Body:**
```json
{
  "household": {
    "name": "Smith-Jones Family"
  }
}
```

#### Delete Household

**Endpoint:** `DELETE /api/v1/households/:id`
**Auth Required:** Yes (owner only)

**Success Response:** `204 No Content`

---

### Members

#### List Members

**Endpoint:** `GET /api/v1/households/:household_id/members`
**Auth Required:** Yes (member or owner)

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "household_member",
      "attributes": {
        "role": "owner",
        "created_at": "2024-02-09T12:00:00.000Z"
      },
      "relationships": {
        "user": {
          "data": { "id": "1", "type": "user" }
        }
      }
    }
  ]
}
```

#### Remove Member

**Endpoint:** `DELETE /api/v1/households/:household_id/members/:id`
**Auth Required:** Yes (owner only)

**Note:** The owner cannot be removed.

#### Leave Household

**Endpoint:** `POST /api/v1/households/:household_id/leave`
**Auth Required:** Yes (member only)

**Success Response:** `204 No Content`

**Note:** The owner cannot leave. They must delete the household or transfer ownership.

---

### Invitations (Owner)

#### List Pending Invitations

**Endpoint:** `GET /api/v1/households/:household_id/invitations`
**Auth Required:** Yes (owner only)

#### Create Invitation

**Endpoint:** `POST /api/v1/households/:household_id/invitations`
**Auth Required:** Yes (owner only)

**Request Body:**
```json
{
  "invitation": {
    "email": "friend@example.com"
  }
}
```

**Success Response:** `201 Created`
```json
{
  "data": {
    "id": "1",
    "type": "invitation",
    "attributes": {
      "email": "friend@example.com",
      "token": "abc123xyz...",
      "status": "pending",
      "expires_at": "2024-02-16T12:00:00.000Z"
    }
  }
}
```

**Configuration:**
| Setting | Value |
|---------|-------|
| Expiration | 7 days |

#### Cancel Invitation

**Endpoint:** `DELETE /api/v1/households/:household_id/invitations/:id`
**Auth Required:** Yes (owner only)

**Success Response:** `204 No Content`

---

### Invitations (Invitee)

#### View Invitation

**Endpoint:** `GET /api/v1/invitations/:token`
**Auth Required:** Yes

**Success Response:** `200 OK`
```json
{
  "data": {
    "id": "1",
    "type": "invitation",
    "attributes": {
      "email": "friend@example.com",
      "status": "pending",
      "expires_at": "2024-02-16T12:00:00.000Z"
    },
    "relationships": {
      "household": {
        "data": { "id": "1", "type": "household" }
      },
      "invited_by": {
        "data": { "id": "1", "type": "user" }
      }
    }
  }
}
```

#### Accept Invitation

Joins the household as a member.

**Endpoint:** `POST /api/v1/invitations/:token/accept`
**Auth Required:** Yes

#### Decline Invitation

**Endpoint:** `POST /api/v1/invitations/:token/decline`
**Auth Required:** Yes

---

## Shopping Lists

### List Management

#### List Shopping Lists

Returns all shopping lists for a household.

**Endpoint:** `GET /api/v1/households/:household_id/shopping_lists`
**Auth Required:** Yes (member or owner)

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "shopping_list",
      "attributes": {
        "name": "Weekly Groceries",
        "status": "active",
        "items_count": 5,
        "pending_count": 3,
        "checked_count": 2,
        "completed_at": null,
        "created_at": "2024-02-09T12:00:00.000Z"
      }
    }
  ]
}
```

#### Get Shopping List

**Endpoint:** `GET /api/v1/households/:household_id/shopping_lists/:id`
**Auth Required:** Yes (member or owner)

#### Create Shopping List

**Endpoint:** `POST /api/v1/households/:household_id/shopping_lists`
**Auth Required:** Yes (owner only)

**Request Body:**
```json
{
  "shopping_list": {
    "name": "Weekly Groceries"
  }
}
```

**Success Response:** `201 Created`

#### Update Shopping List

**Endpoint:** `PUT /api/v1/households/:household_id/shopping_lists/:id`
**Auth Required:** Yes (owner only)

**Request Body:**
```json
{
  "shopping_list": {
    "name": "Monthly Groceries"
  }
}
```

#### Delete Shopping List

**Endpoint:** `DELETE /api/v1/households/:household_id/shopping_lists/:id`
**Auth Required:** Yes (owner only)

**Success Response:** `204 No Content`

#### Complete Shopping List

Marks the list as completed with a timestamp.

**Endpoint:** `POST /api/v1/households/:household_id/shopping_lists/:id/complete`
**Auth Required:** Yes (owner only)

#### Duplicate Shopping List

Creates a copy of the list with all items reset to pending status.

**Endpoint:** `POST /api/v1/households/:household_id/shopping_lists/:id/duplicate`
**Auth Required:** Yes (owner only)

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `name` | string | Custom name for the copy (default: "Original Name (Copy)") |

**Success Response:** `201 Created`

---

### List Items

Items are ordered with pending items first, then checked/not_in_stock items.

#### List Items

**Endpoint:** `GET /api/v1/shopping_lists/:shopping_list_id/items`
**Auth Required:** Yes (member or owner)

**Success Response:** `200 OK`
```json
{
  "data": [
    {
      "id": "1",
      "type": "shopping_list_item",
      "attributes": {
        "display_name": "Whole Milk",
        "custom_name": null,
        "quantity": "2.0",
        "status": "pending",
        "checked_at": null,
        "position": 1
      },
      "relationships": {
        "item": { "data": { "id": "1", "type": "item" } },
        "unit_type": { "data": { "id": "1", "type": "unit_type" } },
        "added_by": { "data": { "id": "1", "type": "user" } }
      }
    }
  ]
}
```

#### Add Item

Add an item from the catalog or a custom free-text item.

**Endpoint:** `POST /api/v1/shopping_lists/:shopping_list_id/items`
**Auth Required:** Yes (member or owner)

**Request Body (Catalog Item):**
```json
{
  "item": {
    "item_id": 1,
    "quantity": 2,
    "unit_type_id": 1
  }
}
```

**Request Body (Custom Item):**
```json
{
  "item": {
    "custom_name": "Organic Almond Milk",
    "quantity": 1
  }
}
```

**Success Response:** `201 Created`

#### Update Item

**Endpoint:** `PUT /api/v1/shopping_lists/:shopping_list_id/items/:id`
**Auth Required:** Yes (member or owner)

**Request Body:**
```json
{
  "item": {
    "quantity": 3
  }
}
```

#### Delete Item

**Endpoint:** `DELETE /api/v1/shopping_lists/:shopping_list_id/items/:id`
**Auth Required:** Yes (member or owner)

**Success Response:** `204 No Content`

#### Check Item (Mark as Purchased)

**Endpoint:** `POST /api/v1/shopping_lists/:shopping_list_id/items/:id/check`
**Auth Required:** Yes (member or owner)

Sets `status` to `checked` and records `checked_at` timestamp.

#### Uncheck Item

**Endpoint:** `POST /api/v1/shopping_lists/:shopping_list_id/items/:id/uncheck`
**Auth Required:** Yes (member or owner)

Sets `status` back to `pending` and clears `checked_at`.

#### Mark Item Not In Stock

**Endpoint:** `POST /api/v1/shopping_lists/:shopping_list_id/items/:id/not_in_stock`
**Auth Required:** Yes (member or owner)

Sets `status` to `not_in_stock` and records `checked_at` timestamp.

---

## Error Responses

### Standard Error Format

```json
{
  "errors": [
    {
      "status": "422",
      "title": "Unprocessable Entity",
      "detail": "Name can't be blank"
    }
  ]
}
```

### Common Error Codes

| Status | Title | Description |
|--------|-------|-------------|
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid access token |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation errors |
| 429 | Too Many Requests | Rate limit exceeded |

### Email Confirmation Errors

| Error Code | Detail |
|------------|--------|
| `email_not_confirmed` | User must confirm email before accessing protected resources |
| `Invalid OTP` | The OTP code is incorrect |
| `OTP has expired` | Request a new OTP code |
| `Too many failed attempts` | Request a new OTP code |

---

## Authorization Matrix

### Household Permissions

| Action | Owner | Member | Non-member |
|--------|:-----:|:------:|:----------:|
| View household | ✅ | ✅ | ❌ |
| Update household | ✅ | ❌ | ❌ |
| Delete household | ✅ | ❌ | ❌ |
| List members | ✅ | ✅ | ❌ |
| Remove member | ✅ | ❌ | ❌ |
| Leave household | ❌ | ✅ | ❌ |
| Manage invitations | ✅ | ❌ | ❌ |

### Item Permissions

| Action | Any User | Notes |
|--------|:--------:|-------|
| List items | ✅ | |
| View item | ✅ | |
| Create item | ✅ | Creates as custom item |
| Update item | ✅ | Custom items only |
| Delete item | ✅ | Custom items only |

### Shopping List Permissions

| Action | Owner | Member | Non-member |
|--------|:-----:|:------:|:----------:|
| List shopping lists | ✅ | ✅ | ❌ |
| View shopping list | ✅ | ✅ | ❌ |
| Create shopping list | ✅ | ❌ | ❌ |
| Update shopping list | ✅ | ❌ | ❌ |
| Delete shopping list | ✅ | ❌ | ❌ |
| Complete shopping list | ✅ | ❌ | ❌ |
| Duplicate shopping list | ✅ | ❌ | ❌ |
| Add/Edit/Delete list items | ✅ | ✅ | ❌ |
| Check/Uncheck items | ✅ | ✅ | ❌ |

---

## Development Setup

### Start Services

```bash
# Start email catcher (view emails at http://localhost:1080)
mailcatcher

# Start Rails server
rails s
```

### Create OAuth Application

```bash
rails c
```

```ruby
app = Doorkeeper::Application.create!(
  name: "Mobile App",
  redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
  scopes: ""
)
puts "Client ID: #{app.uid}"
puts "Client Secret: #{app.secret}"
```

---

## Changelog

### Phase 3 - Shopping Lists
- Added shopping list management (CRUD, complete, duplicate)
- Added list items with catalog items or custom free-text items
- Added item status: pending, checked (purchased), not_in_stock
- Items ordered with pending first, checked/not_in_stock at bottom
- Owner creates/manages lists, all members can add/check items

### Phase 2 - Households & Email Confirmation
- Added OTP-based email confirmation
- Added household management (CRUD)
- Added member management
- Added invitation system with token-based acceptance

### Phase 1 - Catalog Foundation
- Added categories (read-only)
- Added unit types (read-only)
- Added items (CRUD, default items protected)
