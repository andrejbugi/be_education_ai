# Phase 2 Data Model

Frontend-oriented summary of the Phase 2 backend additions.

Base path: `/api/v1`

## Phase 2 domains
- `homeroom_assignments`
- `announcements`
- `attendance_records`
- `student_performance_snapshots`
- `ai_sessions`
- `ai_messages`

## School context
- All Phase 2 data is school-scoped.
- Frontend should keep sending `X-School-Id` with authenticated requests.
- Visibility is role-sensitive:
  - `student` sees own attendance, own performance, own AI sessions, visible announcements
  - `teacher` sees own homerooms, classroom attendance, classroom performance, authored announcements
  - `admin` can access cross-school management within selected school context

## 1. Homeroom assignments
Purpose: identify the main class teacher for a classroom.

Main fields:
- `id`
- `school_id`
- `classroom`
- `teacher`
- `active`
- `starts_on`
- `ends_on`

Typical response shape:
```json
{
  "id": 1,
  "school_id": 2,
  "classroom": {
    "id": 10,
    "name": "7-A"
  },
  "teacher": {
    "id": 15,
    "full_name": "Ана Трајковска"
  },
  "active": true,
  "starts_on": "2026-03-14",
  "ends_on": null
}
```

Main endpoints:
- `GET /teacher/homerooms`
- `POST /classrooms/:classroom_id/homeroom_assignment`
- `PATCH /homeroom_assignments/:id`

Frontend uses:
- show homeroom teacher on classroom cards
- show “my homerooms” in teacher dashboard
- support classroom ownership / communication flows

## 2. Announcements
Purpose: school communication feed for teachers and students.

Main fields:
- `id`
- `school_id`
- `title`
- `body`
- `status`: `draft | published | archived`
- `priority`: `normal | important | urgent`
- `audience_type`: `school | classroom | subject | teachers | students`
- `published_at`
- `starts_at`
- `ends_at`
- `author`
- `classroom` nullable
- `subject` nullable
- `file_url` nullable
- `uploaded_file` nullable

Typical response shape:
```json
{
  "id": 7,
  "school_id": 2,
  "title": "Важно известување",
  "body": "Утре донесете тетратки.",
  "status": "published",
  "priority": "important",
  "audience_type": "classroom",
  "published_at": "2026-03-14T08:30:00Z",
  "starts_at": "2026-03-14T08:30:00Z",
  "ends_at": "2026-03-21T08:30:00Z",
  "author": {
    "id": 15,
    "full_name": "Ана Трајковска"
  },
  "classroom": {
    "id": 10,
    "name": "7-A"
  },
  "subject": null,
  "file_url": "http://localhost:3000/rails/active_storage/blobs/redirect/...",
  "uploaded_file": {
    "filename": "notice.pdf",
    "byte_size": 102400,
    "content_type": "application/pdf",
    "url": "http://localhost:3000/rails/active_storage/blobs/redirect/..."
  }
}
```

Main endpoints:
- `GET /announcements`
- `POST /announcements`
- `GET /announcements/:id`
- `PATCH /announcements/:id`
- `POST /announcements/:id/publish`
- `POST /announcements/:id/archive`

Frontend uses:
- student dashboard announcements feed
- teacher authored-announcement list
- priority badges and publish/archive actions
- attachment preview / download for uploaded announcement files

Notes:
- Students only see announcements visible to them.
- Publishing creates notifications for recipients.
- `POST /announcements` and `PATCH /announcements/:id` now accept multipart `file`.
- `PATCH /announcements/:id` also accepts `remove_file=true` to clear the uploaded attachment.

## 3. Attendance records
Purpose: track presence, absence, lateness, and excused attendance.

Main fields:
- `id`
- `school_id`
- `classroom`
- `subject` nullable
- `student`
- `teacher`
- `attendance_date`
- `status`: `present | absent | late | excused`
- `note`

Typical response shape:
```json
{
  "id": 18,
  "school_id": 2,
  "classroom": {
    "id": 10,
    "name": "7-A"
  },
  "subject": {
    "id": 4,
    "name": "Математика"
  },
  "student": {
    "id": 45,
    "full_name": "Марија Стојанова"
  },
  "teacher": {
    "id": 15,
    "full_name": "Ана Трајковска"
  },
  "attendance_date": "2026-03-14",
  "status": "late",
  "note": "Доцнеше 10 минути"
}
```

Main endpoints:
- `GET /attendance_records`
- `POST /attendance_records`
- `PATCH /attendance_records/:id`
- `GET /classrooms/:classroom_id/attendance`
- `GET /students/:id/attendance`

`POST /attendance_records` expects bulk payload:
```json
{
  "classroom_id": 10,
  "subject_id": 4,
  "attendance_date": "2026-03-14",
  "records": [
    {
      "student_id": 45,
      "status": "present",
      "note": null
    },
    {
      "student_id": 46,
      "status": "late",
      "note": "Доцнеше 10 минути"
    }
  ]
}
```

Frontend uses:
- teacher attendance entry sheet
- student attendance history
- classroom attendance timeline

## 4. Student performance snapshots
Purpose: precomputed metrics for dashboards and reporting.

Main fields:
- `id`
- `period_type`: `weekly | monthly | term | custom`
- `period_start`
- `period_end`
- `average_grade`
- `completed_assignments_count`
- `in_progress_assignments_count`
- `overdue_assignments_count`
- `missed_assignments_count`
- `attendance_rate`
- `engagement_score`
- `snapshot_data`
- `generated_at`

Typical response shape:
```json
{
  "id": 3,
  "period_type": "monthly",
  "period_start": "2026-03-01",
  "period_end": "2026-03-31",
  "average_grade": "92.50",
  "completed_assignments_count": 5,
  "in_progress_assignments_count": 1,
  "overdue_assignments_count": 0,
  "missed_assignments_count": 0,
  "attendance_rate": "100.0",
  "engagement_score": "60.0",
  "snapshot_data": {
    "grades_count": 4,
    "attendance_breakdown": {
      "present": 8,
      "late": 1
    },
    "assignment_ids": [11, 12, 13]
  },
  "generated_at": "2026-03-14T09:12:00Z"
}
```

Main endpoints:
- `GET /student/performance`
- `GET /students/:id/performance_snapshots`
- `GET /classrooms/:id/performance_overview`

`GET /classrooms/:id/performance_overview` returns classroom aggregate plus per-student summary:
```json
{
  "classroom_id": 10,
  "classroom_name": "7-A",
  "period_type": "monthly",
  "generated_at": "2026-03-14T09:12:00Z",
  "student_count": 15,
  "average_grade": "87.40",
  "average_attendance_rate": "96.20",
  "average_engagement_score": "58.10",
  "students": [
    {
      "student_id": 45,
      "student_name": "Марија Стојанова",
      "average_grade": "92.50",
      "attendance_rate": "100.0",
      "engagement_score": "60.0",
      "completed_assignments_count": 5,
      "overdue_assignments_count": 0
    }
  ]
}
```

Frontend uses:
- student performance card
- classroom report table
- future charts for attendance/engagement trends

## 5. AI sessions
Purpose: persist a student AI workspace and make it resumable.

Main fields:
- `id`
- `school_id`
- `title`
- `session_type`: `assignment_help | practice | revision | freeform`
- `status`: `active | paused | completed | archived`
- `started_at`
- `last_activity_at`
- `ended_at`
- `context_data`
- `assignment_id` nullable
- `submission_id` nullable
- `subject_id` nullable

Typical response shape:
```json
{
  "id": 9,
  "school_id": 2,
  "title": "AI помош - Математика",
  "session_type": "assignment_help",
  "status": "active",
  "started_at": "2026-03-14T07:00:00Z",
  "last_activity_at": "2026-03-14T08:15:00Z",
  "ended_at": null,
  "context_data": {
    "focus": "Математика",
    "language": "mk"
  },
  "assignment_id": 11,
  "submission_id": 3,
  "subject_id": 4
}
```

Main endpoints:
- `GET /ai_sessions`
- `POST /ai_sessions`
- `GET /ai_sessions/:id`
- `PATCH /ai_sessions/:id`
- `POST /ai_sessions/:id/close`

Frontend uses:
- “resume previous AI session” card
- assignment-linked AI workspace
- tab/list of recent AI conversations

## 6. AI messages
Purpose: ordered message history inside an AI session.

Main fields:
- `id`
- `role`: `user | assistant | system`
- `message_type`: `question | hint | feedback | step | summary | error`
- `content`
- `sequence_number`
- `metadata`
- `created_at`

Typical response shape:
```json
{
  "id": 21,
  "role": "assistant",
  "message_type": "hint",
  "content": "Ајде прво да ги повториме клучните поими.",
  "sequence_number": 2,
  "metadata": {
    "tone": "supportive"
  },
  "created_at": "2026-03-14T08:16:00Z"
}
```

Main endpoints:
- `GET /ai_sessions/:ai_session_id/messages`
- `POST /ai_sessions/:ai_session_id/messages`

Example create payload:
```json
{
  "role": "user",
  "message_type": "question",
  "content": "Како се собираат дробки?",
  "metadata": {}
}
```

Notes:
- Backend assigns `sequence_number`.
- `GET /ai_sessions/:id` already includes `messages`, so FE can often skip the separate messages request on first load.

## Dashboard additions

### Student dashboard
`GET /student/dashboard` now includes:
- `announcements`
- `performance_snapshot`
- `progress`
- `ai_resume`
- `recent_activity`

### Teacher dashboard
`GET /teacher/dashboard` now includes:
- `homerooms`
- `announcement_feed`

## Seed support
`db/seeds.rb` now also creates sample Phase 2 data:
- homeroom assignments
- published announcements
- attendance records
- performance snapshots
- AI sessions and AI messages

This gives FE enough data to build:
- announcement feed UI
- attendance history/list views
- teacher homeroom cards
- performance summary cards/tables
- AI session resume and message list UI

## Quick FE checklist
1. Keep sending `Authorization: Bearer <token>`.
2. Keep sending `X-School-Id`.
3. Treat decimal metrics like `average_grade` and `attendance_rate` as strings that may need numeric formatting in UI.
4. Expect nullable associations in announcements, attendance, and AI sessions.
5. Use role-based conditional rendering for teacher/student/admin actions.
