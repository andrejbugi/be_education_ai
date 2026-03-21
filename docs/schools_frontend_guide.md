# Schools Frontend Guide

This doc explains how frontend should load and use school data with the current backend.

## Endpoints used for schools

## 1) `GET /api/v1/auth/me`
Use this after login (or refresh) to get current user and available schools.

Headers:
- auth cookie is sent automatically when FE uses `credentials: 'include'`

Response:
```json
{
  "user": {
    "id": 7,
    "email": "email122@email.com",
    "first_name": "Ана",
    "last_name": "Трајковска",
    "full_name": "Ана Трајковска",
    "roles": ["teacher"]
  },
  "schools": [
    { "id": 1, "name": "ОУ Браќа Миладиновци", "code": "OU-BM" },
    { "id": 2, "name": "ОУ Кочо Рацин", "code": "OU-KO" }
  ]
}
```

## 2) `GET /api/v1/schools`
Public endpoint for login. Returns active schools only.

Headers:
- none

Response:
```json
[
  {
    "id": 1,
    "name": "ОУ Браќа Миладиновци",
    "code": "OU-BM",
    "city": "Скопје",
    "active": true
  }
]
```

## 3) `GET /api/v1/schools/:id`
Returns one school with nested classrooms and subjects, including reusable subject topics.

Headers:
- auth cookie is sent automatically when FE uses `credentials: 'include'`

Response:
```json
{
  "id": 1,
  "name": "ОУ Браќа Миладиновци",
  "code": "OU-BM",
  "city": "Скопје",
  "active": true,
  "classrooms": [
    { "id": 10, "name": "7-A", "grade_level": "7", "academic_year": "2025/2026" }
  ],
  "subjects": [
    {
      "id": 4,
      "name": "Математика",
      "code": "MAT-7",
      "topics": [
        { "id": 12, "name": "Дробки" }
      ],
      "subject_topics": [
        { "id": 12, "name": "Дробки" }
      ]
    }
  ]
}
```

## Login + school selector flow

1. Call `POST /api/v1/auth/login`.
2. Save `user` and initial `school` from login response.
3. Call `GET /api/v1/auth/me` to load full `schools` list.
4. If `schools.length > 1`, show school dropdown.
5. Save selected school id in auth/app state.
6. Send selected school in header for school-scoped requests:
- `X-School-Id: <selected_school_id>`

Note:
- `X-School-Id` is optional for `/schools` endpoints.
- It is important for dashboards and other scoped pages.
- FE should use `credentials: 'include'` for all protected requests.

## Frontend data types (suggested)

```ts
export type SchoolSummary = {
  id: number;
  name: string;
  code: string | null;
};

export type SchoolListItem = SchoolSummary & {
  city: string | null;
  active: boolean;
};

export type SchoolDetails = SchoolListItem & {
  classrooms: {
    id: number;
    name: string;
    grade_level: string | null;
    academic_year: string | null;
  }[];
  subjects: {
    id: number;
    name: string;
    code: string | null;
    topics: {
      id: number;
      name: string;
    }[];
    subject_topics: {
      id: number;
      name: string;
    }[];
  }[];
};
```

## Topic loading notes

- For teacher assignment creation, FE should usually use `GET /api/v1/teacher/subjects` because it returns teacher-visible subjects together with reusable `topics`.
- `GET /api/v1/schools/:id` also returns subject topics, so it can be used as a fallback or for broader school-scoped setup pages.
- To create a new reusable topic under one subject, use `POST /api/v1/teacher/subjects/:subject_id/topics` with `{ "name": "..." }`.

## Error handling

- `401 Unauthorized`
- Missing or invalid token (for protected endpoints like `/auth/me` and `/schools/:id`).

- `404 Not found`
- School id does not exist or user is not a member of that school.

- `403 Forbidden`
- Commonly for invalid school context during login (`school_id` not linked to user).

## Current backend limitations (important for FE)

Currently implemented for schools:
- `GET /schools`
- `GET /schools/:id`

Not implemented yet:
- `POST /schools`
- `PATCH /schools/:id`
- school membership management endpoints

For now, FE should treat schools as read-only data from backend.

## Seeded demo accounts

- Teacher: `email122@email.com` / `password123`
- Student: `student1@edu.mk` / `password123`
- Admin: `admin@edu.mk` / `password123`
