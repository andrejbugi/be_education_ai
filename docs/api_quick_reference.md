# API Quick Reference

Base path: `/api/v1`

## Pagination
- list/index endpoints use `limit` and `offset`
- default `limit` is `25`
- maximum `limit` is `100`
- `offset` is zero-based
- example first page: `?limit=25&offset=0`
- example second page: `?limit=25&offset=25`
- if `limit` is too large, backend clamps it down to `100`

## Auth
- `POST /auth/login`
- `DELETE /auth/logout`
- `GET /auth/me`

Auth notes:
- `POST /auth/login` sets an encrypted `HttpOnly` auth session cookie
- `DELETE /auth/logout` revokes the current cookie-backed server session when present
- `GET /auth/me` works with the auth cookie and includes `current_school`, `session_authenticated`, and `session_expires_at`
- admins may log in without selecting a school first; teacher and student flows still resolve school context

## Schools and profile
- `GET /schools`
- `GET /schools/:id`
- `GET /invitations/:token`
- `POST /invitations/:token/accept`
- `GET /profile`
- `PATCH /profile`

Invitation notes:
- user email is global, but school access is school-scoped
- inviting an existing email reuses the same account instead of creating a duplicate user
- existing active users only gain access to the invited school after they accept that invitation
- for existing active users, invitation acceptance ignores password fields and keeps the current password unchanged

## Teacher area
- `GET /teacher/dashboard`
- `GET /teacher/classrooms`
- `GET /teacher/classrooms/:id`
- `GET /teacher/subjects`
- `POST /teacher/subjects/:subject_id/topics`
- `GET /teacher/students/:id`
- `GET /teacher/submissions/:id`

Teacher submission detail notes:
- use `GET /teacher/submissions/:id` when a teacher opens one specific student submission for grading
- it returns the submission, the student, assignment context, assignment `steps` with `answer_keys`, the student's `step_answers`, and the latest grade if one exists

## Assignments
- `GET /assignments`
- `POST /assignments`
- `GET /assignments/:id`
- `PATCH /assignments/:id`
- `POST /assignments/:id/publish`
- `POST /assignments/:assignment_id/steps`
- `PATCH /assignments/:assignment_id/steps/:id`
- `POST /assignments/:assignment_id/resources`
- `PATCH /assignments/:assignment_id/resources/:id`
- `DELETE /assignments/:assignment_id/resources/:id`

## Submissions and grades
- `POST /assignments/:assignment_id/submissions`
- `PATCH /submissions/:id`
- `POST /submissions/:id/submit`
- `POST /submissions/:submission_id/grades`

## Assignment checking notes
- assignments can now optionally reference a reusable subject topic through `subject_topic_id`
- assignment payloads may include both `subject_topic_id` and nested `subject_topic`
- steps support `evaluation_mode`: `manual | normalized_text | numeric | regex`
- teacher/admin assignment step payloads can include `answer_keys`
- student assignment payloads do not include `answer_keys`
- `GET /student/assignments/:id` includes `submission.step_answers` when the student has already started work
- submission step answers may return `answered`, `correct`, or `incorrect`

## Subject topics
- use `GET /teacher/subjects` to load teacher-visible subjects together with reusable `topics`
- use `POST /teacher/subjects/:subject_id/topics` to create a new reusable topic for a subject
- `GET /schools/:id` also returns school subjects with `topics` and `subject_topics`

## Comments
- `POST /comments`
- `GET /comments?commentable_type=Submission&commentable_id=123`

## Admin area
- `GET /admin/schools`
- `POST /admin/schools`
- `GET /admin/schools/:id`
- `PATCH /admin/schools/:id`
- `POST /admin/schools/:id/deactivate`
- `POST /admin/schools/:id/reactivate`
- `GET /admin/teachers`
- `POST /admin/teachers`
- `GET /admin/teachers/:id`
- `PATCH /admin/teachers/:id`
- `POST /admin/teachers/:id/resend_invitation`
- `POST /admin/teachers/:id/deactivate`
- `PUT /admin/teachers/:id/subjects`
- `PUT /admin/teachers/:id/classrooms`
- `GET /admin/students`
- `POST /admin/students`
- `GET /admin/students/:id`
- `PATCH /admin/students/:id`
- `POST /admin/students/:id/resend_invitation`
- `POST /admin/students/:id/deactivate`
- `PUT /admin/students/:id/classrooms`
- `GET /admin/classrooms`
- `POST /admin/classrooms`
- `GET /admin/classrooms/:id`
- `PATCH /admin/classrooms/:id`
- `DELETE /admin/classrooms/:id`
- `GET /admin/classrooms/:classroom_id/schedule`
- `PUT /admin/classrooms/:classroom_id/schedule`
- `GET /admin/subjects`
- `POST /admin/subjects`
- `GET /admin/subjects/:id`
- `PATCH /admin/subjects/:id`
- `DELETE /admin/subjects/:id`

Admin membership notes:
- admin teacher/student lists include both current school members and pending invited users for that school
- `POST /admin/teachers/:id/deactivate` and `POST /admin/students/:id/deactivate` remove access for the selected school only
- school `name` must be unique
- school `code` must be unique when present

Admin schedule notes:
- `Classroom` is the student group (`паралелка`), not a physical room
- classroom, subject, and teacher profile payloads can include optional `room_name` and `room_label`
- classroom schedule payloads return weekly `slots` with `day_of_week`, `period_number`, `subject_id`, `teacher_id`, optional per-slot room overrides, and computed `display_room_name`, `display_room_label`, and `display_room_source`
- schedule replacement is whole-timetable based in v1: send the complete `slots` array for the classroom

## Calendar
- `GET /calendar/events`
- `POST /calendar/events`
- `PATCH /calendar/events/:id`

## Notifications
- `GET /notifications`
- `POST /notifications/:id/mark_as_read`

## Student area
- `GET /student/dashboard`
- `GET /student/performance`
- `GET /student/assignments`
- `GET /student/assignments/:id`
- `GET /student/daily_quiz`
- `POST /student/daily_quiz/answer`
- `GET /student/learning_games`

Student area headers:
- encrypted auth cookie
- `X-School-Id: <selected_school_id>`

## Daily quiz

### `GET /student/daily_quiz`
Returns today's quiz state for the current student in the selected school.

Example response before answering:

```json
{
  "date": "2026-03-19",
  "available_now": true,
  "available_from": "00:00",
  "available_until": "23:59",
  "already_answered": false,
  "question": {
    "id": 12,
    "title": "Квиз на денот",
    "body": "Кој град е главен град на Македонија?",
    "category": "geography",
    "difficulty": null,
    "answer_type": "single_choice",
    "answer_options": ["Битола", "Скопје", "Охрид"]
  },
  "answer": null,
  "reward": {
    "correct_xp": 1
  }
}
```

Example response after answering:

```json
{
  "date": "2026-03-19",
  "available_now": true,
  "available_from": "00:00",
  "available_until": "23:59",
  "already_answered": true,
  "question": {
    "id": 12,
    "title": "Квиз на денот",
    "body": "Кој град е главен град на Македонија?",
    "category": "geography",
    "difficulty": null,
    "answer_type": "single_choice",
    "answer_options": ["Битола", "Скопје", "Охрид"]
  },
  "answer": {
    "selected_answer": "Скопје",
    "answer_text": null,
    "correct": true,
    "xp_awarded": 1,
    "explanation": "Скопје е главен град на Македонија.",
    "answered_at": "2026-03-19T18:31:00.000Z"
  },
  "reward": {
    "correct_xp": 1
  }
}
```

Notes:
- daily quiz is available throughout the whole local school day
- backend returns school-scoped or global quiz content for the current day
- if no active question exists for today, `question` is `null`
- once answered, FE should keep the screen read-only

### `POST /student/daily_quiz/answer`
Creates the student's answer for today's quiz.

Example request:

```json
{
  "daily_quiz_question_id": 12,
  "selected_answer": "Скопје"
}
```

Example success response:

```json
{
  "correct": true,
  "xp_awarded": 1,
  "already_answered": true,
  "explanation": "Скопје е главен град на Македонија.",
  "answered_at": "2026-03-19T18:31:00.000Z"
}
```

Behavior notes:
- first successful submit returns `201 Created`
- duplicate submit for the same day returns the existing result with `200 OK`
- repeated requests do not create duplicate XP rewards
- if there is no active quiz for today the endpoint returns `404`
- validation problems return `422` with `{ "errors": [...] }`

## Learning games

### `GET /student/learning_games`
Returns the current game catalog plus whether the feature is open now.

Example response:

```json
{
  "available_now": true,
  "available_from": "18:00",
  "available_until": "20:00",
  "games": [
    {
      "game_key": "geometry_shapes",
      "title": "Геометрија",
      "description": "Препознај форми и агли.",
      "icon_key": null,
      "is_enabled": true,
      "position": 1,
      "metadata": {}
    },
    {
      "game_key": "basic_math_speed",
      "title": "Брза математика",
      "description": "Решавај кратки математички задачи.",
      "icon_key": null,
      "is_enabled": true,
      "position": 2,
      "metadata": {}
    }
  ]
}
```

Notes:
- this endpoint is catalog/config only in v1
- learning games use the configured time window and may return `available_now: false` outside it
- school-specific config overrides global config by `game_key`
- disabled games are not returned
