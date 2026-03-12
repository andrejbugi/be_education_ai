# Core Backend Flows

## 1. Login and route by role
1. `POST /api/v1/auth/login`
2. Save token + user + school from response.
3. Call `GET /api/v1/auth/me` on app refresh.
4. Route UI by `user.roles`:
- `student` -> student dashboard
- `teacher` -> teacher dashboard
- `admin` -> admin/teacher area

## 2. Teacher creates and publishes assignment
1. `POST /api/v1/assignments` with `classroom_id`, `subject_id`, and optional `steps`.
2. Assignment starts as `draft` unless status is set.
3. `POST /api/v1/assignments/:id/publish` to publish and notify students.

## 3. Student submission flow
1. `POST /api/v1/assignments/:assignment_id/submissions` starts submission.
2. `PATCH /api/v1/submissions/:id` saves step answers.
3. `POST /api/v1/submissions/:id/submit` finalizes submission.
4. Status becomes `submitted` or `late`.

## 4. Teacher grading flow
1. `POST /api/v1/submissions/:submission_id/grades` with score/feedback.
2. Submission status moves to `reviewed`.
3. Student receives a grade notification.

## 5. Notifications flow
1. Frontend polls `GET /api/v1/notifications`.
2. Frontend marks items read with `POST /api/v1/notifications/:id/mark_as_read`.
3. Use `unread_count` to render badge counters.

## 6. Calendar flow
1. Teacher/admin creates events via `POST /api/v1/calendar/events`.
2. Frontend reads school events via `GET /api/v1/calendar/events`.
3. Updates happen with `PATCH /api/v1/calendar/events/:id`.
