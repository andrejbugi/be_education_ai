# Phase 1 Data Model

## Identity and access
- `users`
- `roles`
- `user_roles`
- `schools`
- `school_users`
- `teacher_profiles`
- `student_profiles`

## School structure
- `classrooms`
- `classroom_users`
- `teacher_classrooms`
- `subjects`
- `teacher_subjects`

## Learning workflow
- `assignments`
- `assignment_steps`
- `submissions`
- `submission_step_answers`
- `grades`
- `comments`

## Calendar and communication
- `calendar_events`
- `event_participants`
- `notifications`
- `activity_logs`

## Important constraints
- Unique email on `users.email`
- Unique join pairs on mapping tables (example: `user_roles`, `school_users`, `classroom_users`)
- One submission per student per assignment (`assignment_id + student_id`)
- Polymorphic comments (`commentable_type + commentable_id`)

## Status lifecycles
- Assignment: `draft`, `published`, `scheduled`, `closed`, `archived`
- Submission: `not_started`, `in_progress`, `submitted`, `reviewed`, `returned`, `late`
- Notification unread/read by `read_at`
