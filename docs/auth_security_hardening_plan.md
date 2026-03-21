# Auth Security Hardening Plan

## Goal

Move authentication away from browser-readable JWTs in `localStorage` to secure cookie-based auth, and add real server-side revocation so stolen tokens/sessions can be invalidated.

This document also includes CSP and browser-hardening recommendations.

## Current risks

- Access token is stored in `localStorage`
  - any XSS or malicious browser extension can read it
- Logout is stateless
  - a stolen JWT can remain usable until expiry
- WebSocket auth currently uses token-in-URL
  - query-string tokens can leak into logs and infrastructure
- No visible CSP or strong browser hardening layer

## Recommended target design

### 1. Use secure cookies instead of `localStorage`

Recommended model:

- short-lived access token in `HttpOnly`, `Secure`, `SameSite=Lax` cookie
- optional refresh token in separate `HttpOnly`, `Secure`, `SameSite=Strict` or `Lax` cookie
- frontend never reads the token directly
- frontend sends requests with `credentials: 'include'`

Why:

- `HttpOnly` blocks token theft from frontend JavaScript
- cookies are the standard browser session mechanism
- easier to combine with rotation and revocation

### 2. Add real server-side revocation

Recommended model:

- create a server-side session record or refresh-token record in DB
- each session gets:
  - `id`
  - `user_id`
  - `school_id` if needed
  - `jti` or session identifier
  - `expires_at`
  - `revoked_at`
  - device/IP/user-agent metadata if desired

Backend should:

- reject revoked sessions/tokens
- revoke current session on logout
- support revoking all sessions for a user when needed
- rotate refresh tokens on refresh

Best practical choice:

- session table + refresh-token rotation

This is stronger and easier to manage than “JWT only + blacklist forever”.

## Proposed backend changes

### Login

Instead of returning a bearer token for FE storage:

- authenticate user
- create session record
- set secure cookies
- return only user/profile/school data needed for bootstrapping

### Auth checks

- read cookie on each protected request
- resolve current session from signed token or opaque session id
- ensure:
  - session exists
  - not revoked
  - not expired
  - school context is allowed

### Logout

- revoke current session in DB
- clear auth cookies

### Refresh

- if refresh tokens are used:
  - validate refresh token against session record
  - rotate it
  - revoke old token immediately

### WebSocket auth

Do not send token in query string.

Preferred options:

- use the same authenticated cookie for Action Cable / WebSocket handshake
- or use a short-lived signed channel token generated server-side and never stored in JS long term

## Proposed frontend changes

- remove token persistence from `localStorage`
- stop attaching `Authorization: Bearer ...` manually
- call `fetch(..., { credentials: 'include' })`
- keep only non-sensitive UI state in storage:
  - theme
  - last selected school if safe
  - role hint if needed, but not as a trust source
- bootstrap session with `GET /auth/me`
- on `401`:
  - clear frontend state
  - redirect to login

### Frontend files likely affected

- `src/services/apiClient.js`
- `src/pages/StudentJourneyApp.jsx`
- chat/WebSocket auth flow in `src/components/ChatMessagesPanel.jsx`

## CSRF protection

If auth moves to cookies, CSRF protection becomes required.

Recommended:

- keep auth cookies `SameSite=Lax` or stricter where possible
- for state-changing requests, use CSRF token validation
- expose CSRF token via safe endpoint or meta tag
- send it in `X-CSRF-Token`

Do not rely on `SameSite` alone for high-value actions.

## CSP recommendation

Set CSP as an HTTP response header, not only via `<meta>`.

Recommended starting policy:

```http
Content-Security-Policy:
  default-src 'self';
  base-uri 'self';
  object-src 'none';
  frame-ancestors 'none';
  form-action 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: blob: https:;
  font-src 'self' data:;
  connect-src 'self' https: wss:;
  frame-src 'self' https:;
  media-src 'self' blob: https:;
  worker-src 'self' blob:;
  upgrade-insecure-requests;
  block-all-mixed-content;
```

Notes:

- `style-src 'unsafe-inline'` may be temporarily needed depending on current styling/tooling
- `connect-src` must include API and WebSocket origins actually used
- `img-src` / `media-src` may need exact storage or CDN domains
- `frame-src` should be narrowed further if embeds are not needed

Recommended rollout:

1. start with `Content-Security-Policy-Report-Only`
2. collect violations
3. narrow domains
4. enforce full CSP

## Other recommended security headers

At the reverse proxy / backend:

- `Strict-Transport-Security`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` with only needed features
- `X-Frame-Options: DENY` if not already covered by CSP

## Migration plan

### Phase 1

- add cookie-based session support on backend
- keep existing JWT flow temporarily behind feature flag if needed

### Phase 2

- switch frontend to `credentials: 'include'`
- stop reading/storing auth token in `localStorage`

### Phase 3

- add session revocation and refresh rotation
- migrate WebSocket auth away from query string token

### Phase 4

- enable CSRF protection
- deploy CSP in report-only mode
- then enforce CSP

## Estimated effort

- backend cookie/session implementation: 1 to 3 days
- frontend migration: 0.5 to 1 day
- revocation, refresh rotation, CSRF, testing, rollout: 1 to 2 days

Rough total:

- 2 to 5 days for a solid implementation

## Recommended priority order

1. Stop storing auth token in `localStorage`
2. Add server-side revocation
3. Remove token from WebSocket query string
4. Add CSRF protection
5. Roll out CSP and security headers

## Final recommendation

The best-practice direction for this app is:

- cookie-based auth with `HttpOnly` secure cookies
- server-side session or refresh-token records with revocation
- no token exposure to frontend JavaScript
- CSRF protection for cookie-authenticated writes
- CSP enforced through HTTP headers

This is the safest practical upgrade path without overcomplicating the architecture.
