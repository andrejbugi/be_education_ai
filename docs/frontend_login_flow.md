# Frontend Login Flow (React)

This backend uses JWT bearer auth and optional school context per request.

## 0. Load schools for login dropdown
`GET /api/v1/schools`

No auth required. Returns active schools for the school selector on the login form.

## 1. Login request
`POST /api/v1/auth/login`

Request body:
```json
{
  "email": "teacher@example.com",
  "password": "password123",
  "school_id": 12
}
```

Notes:
1. `school_id` is optional.
2. If omitted and user belongs to schools, backend picks the first school by name.
3. If `school_id` is provided but user is not in that school, backend returns `403` with `{"error":"School context is invalid"}`.

Success response (`200`):
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

## 2. Store auth state on frontend
After login:
1. Save `token` (in-memory preferred; if persistent storage is used, handle XSS hardening).
2. Save `user` and `roles`.
3. Save selected `school.id` as current school context.

## 3. Attach headers to all protected requests
Always send:
1. `Authorization: Bearer <jwt>`
2. `X-School-Id: <current_school_id>` when working in a specific school context

Example:
```http
Authorization: Bearer eyJhbGciOi...
X-School-Id: 12
```

## 4. Fetch current user after page refresh
`GET /api/v1/auth/me`

Header:
1. `Authorization: Bearer <jwt>`

Response (`200`):
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
    { "id": 12, "name": "ООУ Климент Охридски", "code": "KLO-01" },
    { "id": 14, "name": "СОУ Орце Николов", "code": "ON-02" }
  ]
}
```

Frontend behavior:
1. If only one school exists, auto-select it.
2. If multiple schools exist, show school switcher and set `X-School-Id` from selected school.
3. Route by role:
`student` -> student dashboard, `teacher` -> teacher dashboard, `admin` -> admin/teacher area.

## 5. Logout
`DELETE /api/v1/auth/logout`

Current implementation is stateless JWT logout.
Frontend should:
1. Remove local token.
2. Clear current user and school context.
3. Redirect to login.

## 6. Error handling contract
1. `401 Unauthorized`: missing/invalid/expired token, or bad credentials on login.
2. `403 Forbidden`: user authenticated but lacks role/access, or invalid school context on login.
3. `404 Not found`: resource does not exist in allowed scope.
4. `422 Unprocessable Entity`: validation/business rule errors.

## 7. Minimal Axios interceptor example
```ts
import axios from "axios";

const api = axios.create({ baseURL: "/api/v1" });

api.interceptors.request.use((config) => {
  const token = authStore.token;
  const schoolId = authStore.schoolId;

  if (token) config.headers.Authorization = `Bearer ${token}`;
  if (schoolId) config.headers["X-School-Id"] = String(schoolId);

  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      authStore.logoutLocal();
      window.location.href = "/login";
    }
    return Promise.reject(error);
  }
);

export default api;
```
