# Login Docs

This project uses JWT bearer authentication plus optional school context.

## Main flow

1. FE can load schools for the login dropdown with `GET /api/v1/schools`.
2. FE logs in with `POST /api/v1/auth/login`.
3. Backend returns:
   - `token`
   - `user`
   - selected `school` if one is resolved
4. FE stores the token and sends it on protected requests.
5. FE can restore session state with `GET /api/v1/auth/me`.

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
- if `school_id` is omitted and the user belongs to schools, backend picks the first school ordered by name

## Login success response

```json
{
  "token": "<jwt>",
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
  }
}
```

## JWT behavior

The backend signs a JWT containing:
- `user_id`
- `school_id`
- `role_names`
- `exp`

Current expiry is 7 days.

Protected endpoints expect:

```http
Authorization: Bearer <jwt>
```

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
  ]
}
```

Typical FE behavior:
- if there is one school, auto-select it
- if there are multiple schools, let the user choose and send that choice as `X-School-Id`
- route by role after login or `me`

## Logout

`DELETE /api/v1/auth/logout`

Logout is stateless right now.
Backend does not revoke the JWT server-side.
FE should:
- remove the token
- clear current user
- clear selected school

## Common errors

- `401 Unauthorized`
  - bad email/password
  - inactive user
  - missing/invalid/expired token on protected endpoints
- `403 Forbidden`
  - valid login credentials but invalid `school_id`
  - authenticated user lacks permission for the endpoint
- `404 Not Found`
  - resource is outside allowed scope or does not exist

## FE recommendation

- keep the token in memory if possible
- attach `Authorization` on every protected request
- attach `X-School-Id` when the request is school-scoped
- on `401`, clear auth state and redirect to login
