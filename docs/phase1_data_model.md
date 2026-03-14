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
- `assignment_step_answer_keys`
- `assignment_resources`
- `submissions`
- `submission_step_answers`
- `grades`
- `comments`
- `active_storage_blobs`
- `active_storage_attachments`
- `active_storage_variant_records`

## Calendar and communication
- `calendar_events`
- `event_participants`
- `notifications`
- `activity_logs`

## Important constraints
- Unique email on `users.email`
- Unique join pairs on mapping tables (example: `user_roles`, `school_users`, `classroom_users`)
- One submission per student per assignment (`assignment_id + student_id`)
- One assignment step answer key position per step (`assignment_step_id + position`)
- One assignment resource position per assignment (`assignment_id + position`)
- Polymorphic comments (`commentable_type + commentable_id`)

## Status lifecycles
- Assignment: `draft`, `published`, `scheduled`, `closed`, `archived`
- Assignment step evaluation modes: `manual`, `normalized_text`, `numeric`, `regex`
- Submission: `not_started`, `in_progress`, `submitted`, `reviewed`, `returned`, `late`
- Submission step answer: `unanswered`, `answered`, `skipped`, `correct`, `incorrect`
- Notification unread/read by `read_at`

## Assignment notes
- Assignment resources support uploaded files through Active Storage plus external links/embeds.
- Assignment steps can define `evaluation_mode` and related `assignment_step_answer_keys` for auto-checking.
- Student-facing assignment detail payloads must not include answer keys.
