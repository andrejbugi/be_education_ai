# Admin Access and School Setup Workflows

## Summary

This plan introduces a dedicated school-scoped admin API under `/api/v1/admin` so admins can prepare a school operationally before teachers begin assignment and classroom work.

The first release covers:
- school management
- teacher onboarding by invitation
- student onboarding by invitation
- classroom CRUD
- subject CRUD
- teacher to subject assignment
- teacher to classroom assignment
- student to classroom assignment

Admin remains school-scoped in v1. School-bound admin endpoints require `X-School-Id` and only operate inside schools where the admin is a member.

## Main API Surface

### Admin schools
- `GET /api/v1/admin/schools`
- `POST /api/v1/admin/schools`
- `GET /api/v1/admin/schools/:id`
- `PATCH /api/v1/admin/schools/:id`
- `POST /api/v1/admin/schools/:id/deactivate`
- `POST /api/v1/admin/schools/:id/reactivate`

### Admin teachers
- `GET /api/v1/admin/teachers`
- `POST /api/v1/admin/teachers`
- `GET /api/v1/admin/teachers/:id`
- `PATCH /api/v1/admin/teachers/:id`
- `POST /api/v1/admin/teachers/:id/resend_invitation`
- `POST /api/v1/admin/teachers/:id/deactivate`
- `PUT /api/v1/admin/teachers/:id/subjects`
- `PUT /api/v1/admin/teachers/:id/classrooms`

### Admin students
- `GET /api/v1/admin/students`
- `POST /api/v1/admin/students`
- `GET /api/v1/admin/students/:id`
- `PATCH /api/v1/admin/students/:id`
- `POST /api/v1/admin/students/:id/resend_invitation`
- `POST /api/v1/admin/students/:id/deactivate`
- `PUT /api/v1/admin/students/:id/classrooms`

### Admin classrooms
- `GET /api/v1/admin/classrooms`
- `POST /api/v1/admin/classrooms`
- `GET /api/v1/admin/classrooms/:id`
- `PATCH /api/v1/admin/classrooms/:id`
- `DELETE /api/v1/admin/classrooms/:id`

### Admin subjects
- `GET /api/v1/admin/subjects`
- `POST /api/v1/admin/subjects`
- `GET /api/v1/admin/subjects/:id`
- `PATCH /api/v1/admin/subjects/:id`
- `DELETE /api/v1/admin/subjects/:id`

### Public invitations
- `GET /api/v1/invitations/:token`
- `POST /api/v1/invitations/:token/accept`

## Invitation Rules

- teacher and student accounts are created inactive
- backend creates a `user_invitations` record with a secure token digest
- invitation email contains the invite link and accept endpoint
- invitation expiry is `7 days`
- a user email is global across the platform, while school access is school-scoped
- inviting an existing email reuses the same `users` row instead of creating a duplicate
- existing active users do not gain access to the new school until that school invitation is accepted
- accepting an invitation for a new or inactive account activates the user and sets the password
- accepting an invitation for an already active account grants the school membership and ignores password fields
- invitation resend rotates the token and expiry

## CRUD and Delete Rules

- schools use soft lifecycle through `active`
- teacher and student deactivation is school-scoped and removes access only for the selected school
- classrooms and subjects may be hard deleted only when safe
- delete is blocked when operational data exists, with blocker counts returned in the response

## Admin Payload Expectations

Teacher and student payloads include:
- base user fields
- profile data
- invitation status
- invitation timestamps
- school-scoped `active` flag for the selected school membership
- assigned classroom ids
- assigned subject ids for teachers

Classroom and subject payloads include:
- base fields
- membership ids
- assignment counts

## Implementation Notes

Shared service objects are used for:
- school create/update/activation
- user invite/update/deactivation
- invitation accept/resend
- membership replacement sync
- safe subject/classroom delete checks

This keeps admin controllers small and avoids overloading teacher endpoints.
