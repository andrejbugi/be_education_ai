# Seeded School Data Summary

`db/seeds.rb` now populates school structure data for frontend testing.

## Included seed domains
- `schools`
- `users` with roles (`teacher`, `student`, `admin`)
- `school_users` (user membership per school)
- `teacher_profiles`
- `student_profiles`
- `classrooms`
- `classroom_users` (student enrollment per classroom)
- `teacher_classrooms` (teacher to classroom mapping)
- `subjects`
- `teacher_subjects` (teacher to subject mapping)

## `school_teachers` note
There is no physical `school_teachers` table.
For now, `school_teachers` is derived as:
- rows in `school_users`
- where linked user has role `teacher`

## What frontend can use immediately
1. Login with seeded users.
2. Load schools via `GET /api/v1/auth/me` and `GET /api/v1/schools`.
3. Load school details (`classrooms`, `subjects`) via `GET /api/v1/schools/:id`.
4. Build teacher/student selectors from school membership and role data.

## Demo credentials
- Teacher: `email122@email.com` / `password123`
- Student: `student1@edu.mk` / `password123`
- Admin: `admin@edu.mk` / `password123`
