# Login Docs

This project uses cookie-based authentication plus optional school context.

## Main flow

1. FE can load schools for the login dropdown with `GET /api/v1/schools`.
2. FE logs in with `POST /api/v1/auth/login`.
3. Backend sets an encrypted `HttpOnly` auth cookie and returns:
   - `user`
   - selected `school` if one is resolved
   - `session_expires_at`
4. FE sends requests with credentials included.
5. FE can restore session state with `GET /api/v1/auth/me`.

Forgot-password should use the public password reset flow instead of the school-scoped login flow.

## Login endpoint

`POST /api/v1/auth/login`

Accepted request bodies:

Top-level:
```json
{
  "email": "teacher@example.com",
  "password": "password123",
  "school_id": 12
}
```

Wrapped:
```json
{
  "auth": {
    "email": "teacher@example.com",
    "password": "password123",
    "school_id": 12
  }
}
```

Notes:
- `email` and `password` are required.
- `school_id` is optional.
- if `school_id` is sent, the user must belong to that school
- if `school_id` is omitted and the user is a teacher or student who belongs to schools, backend picks the first school ordered by name
- if `school_id` is omitted and the user is an admin, login succeeds without forcing a selected school

## Login success response

```json
{
  "user": {
    "id": 7,
    "email": "teacher@example.com",
    "first_name": "Ana",
    "last_name": "Petrova",
    "full_name": "Ana Petrova",
    "roles": ["teacher"]
  },
  "school": {
    "id": 12,
    "name": "ООУ Климент Охридски",
    "code": "KLO-01"
  },
  "session_expires_at": "2026-03-28T11:00:00.000Z"
}
```

## Auth cookie behavior

Protected endpoints expect:
- the encrypted `HttpOnly` auth cookie set by login
- frontend requests sent with `credentials: 'include'`

When FE is working in a school context, also send:

```http
X-School-Id: <school_id>
```

## `GET /api/v1/auth/me`

Use this after refresh/app boot to rebuild auth state.

Response:
```json
{
  "user": {
    "id": 7,
    "email": "teacher@example.com",
    "first_name": "Ana",
    "last_name": "Petrova",
    "full_name": "Ana Petrova",
    "roles": ["teacher"]
  },
  "schools": [
    { "id": 12, "name": "ООУ Климент Охридски", "code": "KLO-01" }
  ],
  "current_school": {
    "id": 12,
    "name": "ООУ Климент Охридски",
    "code": "KLO-01"
  },
  "session_authenticated": true,
  "session_expires_at": "2026-03-28T11:00:00.000Z"
}
```

Typical FE behavior:
- admins can log in without a school dropdown and choose or create a school after authentication
- if there is one school, auto-select it
- if there are multiple schools, let the user choose and send that choice as `X-School-Id`
- route by role after login or `me`

## Logout

`DELETE /api/v1/auth/logout`

Logout revokes the current server-side session and clears the auth cookie.
FE should:
- clear current user
- clear selected school

## Common errors

- `401 Unauthorized`
  - bad email/password
  - inactive user
  - missing/invalid/expired auth cookie on protected endpoints
- `403 Forbidden`
  - valid login credentials but invalid `school_id`
  - authenticated user lacks permission for the endpoint
- `404 Not Found`
  - resource is outside allowed scope or does not exist

## FE recommendation

- use `credentials: 'include'` on protected requests
- attach `X-School-Id` when the request is school-scoped
- on `401`, clear auth state and redirect to login

## Password reset

Use the public reset flow when the user forgot their password:
- `POST /api/v1/password_resets`
- `GET /api/v1/password_resets/:token`
- `POST /api/v1/password_resets/:token/confirm`

This flow is account-level and does not require `X-School-Id`.

Full guide:
- [password_reset.md](/home/andrejbugi/projects/be_education_ai/docs/password_reset.md)
