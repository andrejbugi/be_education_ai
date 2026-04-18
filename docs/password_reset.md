# Password Reset

Base path: `/api/v1`

Password reset is account-level, not school-scoped.

Important:
- password reset does not require `X-School-Id`
- reset requests always return the same generic success response to avoid exposing whether an email exists
- reset links are single-use
- reset links expire after `30 minutes`
- successful password reset revokes all existing auth sessions for that user

## Endpoints

- `POST /password_resets`
- `GET /password_resets/:token`
- `POST /password_resets/:token/confirm`

## 1) Request reset link

`POST /password_resets`

Example request:

```json
{
  "email": "teacher@example.com"
}
```

Success response:
- `204 No Content`

Behavior:
- if the email belongs to an active user, backend creates or rotates the reset token and sends an email
- if the email does not exist, backend still returns `204 No Content`
- if the user is inactive, backend still returns `204 No Content`

## 2) Validate reset token

`GET /password_resets/:token`

Example success response:

```json
{
  "email": "teacher@example.com",
  "status": "pending",
  "confirm_allowed": true,
  "expires_at": "2026-04-18T13:30:00.000Z",
  "used_at": null
}
```

Status values:
- `pending`
- `used`
- `expired`

Notes:
- invalid or unknown token returns `404 Not Found`
- expired or used token still returns a payload when the token exists, so FE can show a clear state

## 3) Confirm new password

`POST /password_resets/:token/confirm`

Example request:

```json
{
  "password": "new-password-123",
  "password_confirmation": "new-password-123"
}
```

Example success response:

```json
{
  "password_reset": {
    "email": "teacher@example.com",
    "status": "used",
    "confirm_allowed": false,
    "expires_at": "2026-04-18T13:30:00.000Z",
    "used_at": "2026-04-18T13:10:00.000Z"
  },
  "user": {
    "id": 7,
    "email": "teacher@example.com",
    "first_name": "Ana",
    "last_name": "Trajkovska",
    "active": true
  }
}
```

Failure cases:
- `404 Not Found` when the token does not exist
- `422 Unprocessable Entity` when the token is expired or already used
- `422 Unprocessable Entity` when password validation fails

## Local testing

Development email delivery is written to files under:

`tmp/mails`

Suggested local flow:
1. Start Rails in development.
2. Create or use an existing active user.
3. Call `POST /api/v1/password_resets` with that user's email.
4. Open the newest file in `tmp/mails` and copy the reset token from the reset link.
5. Call `GET /api/v1/password_resets/:token` to verify the token.
6. Call `POST /api/v1/password_resets/:token/confirm` with the new password.
7. Verify the old password no longer works and the new password does.

Example curl requests:

```bash
curl -i -X POST http://localhost:3000/api/v1/password_resets \
  -H 'Content-Type: application/json' \
  -d '{"email":"teacher@example.com"}'

curl http://localhost:3000/api/v1/password_resets/TOKEN_HERE

curl -i -X POST http://localhost:3000/api/v1/password_resets/TOKEN_HERE/confirm \
  -H 'Content-Type: application/json' \
  -d '{"password":"new-password-123","password_confirmation":"new-password-123"}'
```
