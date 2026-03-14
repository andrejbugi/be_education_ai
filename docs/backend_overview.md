# Backend Overview

## Stack
- Rails API (`/api/v1`)
- PostgreSQL
- JWT auth
- Role-based access (`admin`, `teacher`, `student`)

## Main domains
- Auth
- Schools and profiles
- Classrooms and subjects
- Assignments and steps
- Submissions and grades
- Assignment resources and file uploads
- Step answer checking
- Comments
- Calendar
- Notifications
- Dashboards

## Auth model
1. Frontend calls `POST /api/v1/auth/login` with email/password.
2. Backend returns JWT token + user + school context.
3. Frontend sends `Authorization: Bearer <token>` on protected endpoints.
4. Frontend should send `X-School-Id` when user belongs to multiple schools.

## School context
- Backend resolves school from `X-School-Id` (or `school_id` param in some endpoints).
- Access is restricted to schools where the current user is a member.

## Role checks
- `student` endpoints for student dashboard and student assignment views.
- `teacher` endpoints for teacher dashboard and grading/assignment management.
- `admin` can access teacher/admin-level areas.

## Assignment capabilities
- assignments support rich `content_json`, teacher notes, and assignment-level resources
- assignment resources support uploaded files via Active Storage and link/embed resources
- steps support `evaluation_mode` and related answer keys for auto-checking
- student assignment reads do not expose answer keys
- step answer saves can now return `answered`, `correct`, or `incorrect`

## Code layout
- Controllers: `app/controllers/api/v1/...`
- Models: `app/models/...`
- Services: `app/services/...`
- Migrations: `db/migrate/...`
