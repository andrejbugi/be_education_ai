# Backend Overview

## Stack
- Rails API (`/api/v1`)
- PostgreSQL
- Cookie-backed auth sessions
- Role-based access (`admin`, `teacher`, `student`)

## Main domains
- Auth
- Auth sessions
- Invitations
- Schools and profiles
- Classrooms and subjects
- Weekly schedules
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
2. Backend creates a server-side `auth_sessions` record and sets an encrypted `HttpOnly` auth cookie.
3. Protected endpoints authenticate from the auth cookie.
4. Frontend should send `X-School-Id` when user belongs to multiple schools.

## School context
- Backend resolves school from `X-School-Id` (or `school_id` param in some endpoints).
- Access is restricted to schools where the current user is a member.
- A `User` account is global by email, while school access is granted through school membership.

## Pagination
- List endpoints generally use shared `limit` / `offset` pagination.

## Role checks
- `student` endpoints for student dashboard and student assignment views.
- `teacher` endpoints for teacher dashboard and grading/assignment management.
- `admin` can access teacher/admin-level areas.

## Auth session capabilities
- logout now revokes the current server-side session instead of only relying on client token removal
- `GET /auth/me` can use the auth cookie and returns session metadata
- Action Cable authenticates from the auth cookie

## Admin capabilities
- school-scoped admin setup endpoints now exist under `/api/v1/admin`
- admins can manage schools, invite teachers and students, and configure classrooms and subjects
- admins can assign teachers to subjects/classrooms and students to classrooms before teachers begin daily work
- admins can configure a repeating weekly timetable per classroom (`паралелка`) with one subject/teacher per day and period
- invitation acceptance is handled through public token-based endpoints under `/api/v1/invitations/:token`
- inviting an existing email reuses the same account and adds school access only after that invitation is accepted
- teacher/student deactivation from admin endpoints removes access only for the selected school instead of disabling the whole account

## Weekly schedule capabilities
- classrooms and subjects can store optional default room fields
- teacher profiles can store optional default room fields
- weekly schedule slots can override the room per lesson
- schedule payloads compute a display room using this fallback order: slot override, subject default, teacher default, classroom default

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
