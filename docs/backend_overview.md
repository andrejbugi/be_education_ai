# Backend Overview

## Stack
- Rails API (`/api/v1`)
- PostgreSQL
- JWT auth
- Role-based access (`admin`, `teacher`, `student`)

## Main domains
- Auth
- Invitations
- Schools and profiles
- Classrooms and subjects
- Subject topics
- Assignments and steps
- Submissions and grades
- Quiz of the Day and Learning Games
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

## Pagination
- List endpoints generally use shared `limit` / `offset` pagination.

## Role checks
- `student` endpoints for student dashboard and student assignment views.
- `teacher` endpoints for teacher dashboard and grading/assignment management.
- `admin` can access teacher/admin-level areas.

## Admin capabilities
- school-scoped admin setup endpoints now exist under `/api/v1/admin`
- admins can manage schools, invite teachers and students, and configure classrooms and subjects
- admins can assign teachers to subjects/classrooms and students to classrooms before teachers begin daily work
- invitation acceptance is handled through public token-based endpoints under `/api/v1/invitations/:token`

## Assignment capabilities
- assignments support rich `content_json`, teacher notes, and assignment-level resources
- assignments can optionally reference reusable subject-level topics through `subject_topic_id`
- assignment resources support uploaded files via Active Storage and link/embed resources
- steps support `evaluation_mode` and related answer keys for auto-checking
- student assignment reads do not expose answer keys
- step answer saves can now return `answered`, `correct`, or `incorrect`

## Subject/topic capabilities
- teachers can load their available subjects together with reusable `topics`
- teachers can create new reusable topics under a subject
- school detail payloads also include subject topics for school-scoped setup screens

## Quiz and learning games capabilities
- daily quiz is a separate lightweight domain and is not modeled as an assignment
- backend supports one active quiz question per day and school scope, with global fallback content
- student answers are limited to once per day per school
- daily quiz is available throughout the whole local school day
- correct quiz answers award `+1 XP` through `student_reward_events`
- learning games availability is enforced by a configurable school feature window in `schools.settings["quiz_games"]`
- learning games v1 only exposes availability and enabled game cards, not game play persistence

## Code layout
- Controllers: `app/controllers/api/v1/...`
- Models: `app/models/...`
- Services: `app/services/...`
- Migrations: `db/migrate/...`
