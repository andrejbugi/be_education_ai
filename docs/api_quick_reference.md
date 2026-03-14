# API Quick Reference

Base path: `/api/v1`

## Auth
- `POST /auth/login`
- `DELETE /auth/logout`
- `GET /auth/me`

## Schools and profile
- `GET /schools`
- `GET /schools/:id`
- `GET /profile`
- `PATCH /profile`

## Teacher area
- `GET /teacher/dashboard`
- `GET /teacher/classrooms`
- `GET /teacher/classrooms/:id`
- `GET /teacher/subjects`
- `GET /teacher/students/:id`

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
- steps support `evaluation_mode`: `manual | normalized_text | numeric | regex`
- teacher/admin assignment step payloads can include `answer_keys`
- student assignment payloads do not include `answer_keys`
- submission step answers may return `answered`, `correct`, or `incorrect`

## Comments
- `POST /comments`
- `GET /comments?commentable_type=Submission&commentable_id=123`

## Calendar
- `GET /calendar/events`
- `POST /calendar/events`
- `PATCH /calendar/events/:id`

## Notifications
- `GET /notifications`
- `POST /notifications/:id/mark_as_read`

## Student area
- `GET /student/dashboard`
- `GET /student/assignments`
- `GET /student/assignments/:id`
