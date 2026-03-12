# Backend Blueprint – AI Education Platform

## Stack
- **Backend:** Rails API
- **Database:** PostgreSQL
- **Frontend consumer:** React app
- **Language for UI fields and labels:** Macedonian

---

## 1. Goal
Build a Rails API backend for a Macedonian school platform where:
- schools onboard their staff and students
- teachers manage classes, subjects, assignments, deadlines, and feedback
- students log in, see dashboards, open tasks, work in a focused workspace, and submit answers
- the platform supports comments, notifications, calendar events, progress tracking, and an AI-assisted workspace later

This blueprint is based on the current project direction: login flow, school selection, student dashboard, teacher dashboard, workspace/task progression, calendar, notifications, and the SQL/data-model discussions already prepared in the project files.

---

## 2. Product flow the backend must support

### School setup
1. Platform admin creates a school
2. School admin adds teachers
3. Teachers are linked to classrooms and subjects
4. Students are linked to classrooms

### Login / entry flow
1. User logs in with email and password
2. Role determines what they can access
3. Teacher may need school context selected/applied
4. Student lands on student dashboard
5. Teacher lands on teacher dashboard

### Student flow
1. Open dashboard
2. See next task, homework, deadlines, notifications, progress
3. Open assignment details
4. Enter workspace
5. Solve step-by-step or complete task
6. Submit work
7. See result / updated status / next task
8. Review calendar, grades, comments, notifications

### Teacher flow
1. Open dashboard
2. Manage classes and students
3. Create and assign homework / quizzes / projects
4. View submissions
5. Grade and comment
6. Track student/class progress
7. Publish announcements and deadlines

---

## 3. Backend architecture recommendation

### Rails app structure
Use standard Rails API-only structure with these main domains:
- `Auth`
- `Schools`
- `Users`
- `Classrooms`
- `Subjects`
- `Assignments`
- `Submissions`
- `Grades`
- `Comments`
- `Calendar`
- `Notifications`
- `Dashboards`
- `AI Workspace`

### Suggested API versioning
- `/api/v1/...`

### Suggested auth direction
For MVP in Rails API:
- email/password auth
- token-based auth for React client
- role-aware authorization

A practical Rails path:
- Devise or custom auth
- JWT for API sessions
- Pundit for authorization

---

## 4. Recommended domain model

## Core identity and access
- `users`
- `roles`
- `user_roles`
- `schools`
- `school_users`
- `teacher_profiles`
- `student_profiles`

### Why
This supports:
- admin / teacher / student separation
- one user having one or more roles
- school membership
- student/teacher-specific profile data

---

## School structure
- `classrooms`
- `classroom_users`
- `teacher_classrooms`
- `subjects`
- `teacher_subjects`
- `homeroom_assignments`

### Why
This supports:
- students assigned to classes
- teachers assigned to classes
- teachers assigned to subjects
- homeroom/main-teacher mapping

---

## Learning content
- `assignments`
- `assignment_steps`
- `announcements`
- `attendance_records`

### Why
This supports:
- homework
- quizzes
- projects
- exercises
- multi-step tasks for AI/workspace flow
- school/class announcements

---

## Student work and review
- `submissions`
- `submission_step_answers`
- `grades`
- `comments`

### Why
This supports:
- a student opening and working on an assignment
- saving answers per step
- full submission lifecycle
- teacher grading and comments
- reusable comments across the system

`comments` should stay polymorphic so they can attach to submissions, assignments, grades, announcements, and calendar events.

---

## Calendar and communication
- `calendar_events`
- `event_participants`
- `notifications`
- `activity_logs`

### Why
This supports:
- deadlines
- tests/quizzes
- school events
- reminders
- dashboard activity feed
- unread notifications counters

---

## Progress and AI support
- `student_performance_snapshots`
- `ai_sessions`
- `ai_messages`

### Why
This supports:
- dashboard analytics and progress visuals
- cached/reporting-friendly student summaries
- future AI tutor conversations and step-by-step learning records

---

## 5. Recommended MVP scope for backend first phase

Do **Phase 1** smaller than the full table list.

### Phase 1 tables
- `users`
- `roles`
- `user_roles`
- `schools`
- `school_users`
- `teacher_profiles`
- `student_profiles`
- `classrooms`
- `classroom_users`
- `teacher_classrooms`
- `subjects`
- `teacher_subjects`
- `assignments`
- `assignment_steps`
- `submissions`
- `submission_step_answers`
- `grades`
- `comments`
- `calendar_events`
- `event_participants`
- `notifications`
- `activity_logs`

### Phase 2 tables
- `homeroom_assignments`
- `announcements`
- `attendance_records`
- `student_performance_snapshots`
- `ai_sessions`
- `ai_messages`

This keeps the first release focused on:
- auth
- school/class setup
- teacher/student split
- assignments
- submissions
- grading/comments
- calendar/deadlines
- notifications

---

## 6. Core relationships to get right early

### Identity
- `User has_many :user_roles`
- `User has_many :roles, through: :user_roles`
- `School has_many :school_users`
- `School has_many :users, through: :school_users`

### Profiles
- `User has_one :teacher_profile`
- `User has_one :student_profile`

### Classes
- `School has_many :classrooms`
- `Classroom has_many :classroom_users`
- `Classroom has_many :students, through: :classroom_users`
- `Classroom has_many :teacher_classrooms`
- `Classroom has_many :teachers, through: :teacher_classrooms`

### Subjects
- `School has_many :subjects`
- `Subject has_many :teacher_subjects`
- `Subject has_many :teachers, through: :teacher_subjects`

### Assignments
- `Subject has_many :assignments`
- `Assignment belongs_to :subject`
- `Assignment belongs_to :classroom`
- `Assignment belongs_to :teacher, class_name: 'User'`
- `Assignment has_many :assignment_steps`

### Student work
- `Assignment has_many :submissions`
- `Submission belongs_to :assignment`
- `Submission belongs_to :student, class_name: 'User'`
- `Submission has_many :submission_step_answers`
- `Submission has_many :grades`

### Comments
- `Comment belongs_to :commentable, polymorphic: true`
- `Comment belongs_to :author, class_name: 'User'`

### Calendar
- `CalendarEvent belongs_to :school`
- `CalendarEvent has_many :event_participants`

### Notifications
- `Notification belongs_to :user`

### Activity
- `ActivityLog belongs_to :user`
- `ActivityLog belongs_to :trackable, polymorphic: true`

---

## 7. Practical table intent by screen/feature

## Login / onboarding
Needs:
- `users`
- `roles`
- `user_roles`
- `schools`
- `school_users`

Supports:
- email login
- role split (`student`, `teacher`, `admin`)
- school membership / filtering

---

## Student dashboard
Needs:
- `assignments`
- `submissions`
- `grades`
- `notifications`
- `calendar_events`
- `activity_logs`
- `student_performance_snapshots` later

Supports cards such as:
- `Следно за тебе`
- `Домашни задачи`
- `Денес`
- `Рокови`
- `Мој напредок`
- `Известувања`

---

## Student workspace
Needs:
- `assignments`
- `assignment_steps`
- `submissions`
- `submission_step_answers`
- later `ai_sessions` and `ai_messages`

Supports:
- step progression
- saving current work
- correct/wrong/skipped step states
- completion state
- returning to in-progress work

---

## Teacher dashboard
Needs:
- `classrooms`
- `teacher_classrooms`
- `classroom_users`
- `subjects`
- `teacher_subjects`
- `assignments`
- `submissions`
- `grades`
- `comments`

Supports:
- class overview
- students per class
- assignments per subject/class
- review queue
- teacher comments
- progress monitoring

---

## Calendar
Needs:
- `calendar_events`
- `event_participants`
- optional links to `assignments`

Supports:
- deadlines
- quizzes/tests
- project due dates
- school events

---

## Notifications
Needs:
- `notifications`
- `activity_logs`

Supports:
- new homework assigned
- teacher comment
- grade posted
- reminder for deadline

---

## 8. Important backend decisions

### A. Roles
Use normalized roles, not only booleans.
Recommended base roles:
- `admin`
- `teacher`
- `student`
- optional later: `school_admin`, `parent`

### B. Assignment targeting
Assignments should be flexible enough to target:
- an entire classroom
- a subject/class combination
- selected students later

For MVP, target by:
- `classroom_id`
- `subject_id`
- `teacher_id`

### C. Submission status lifecycle
Recommended statuses:
- `not_started`
- `in_progress`
- `submitted`
- `reviewed`
- `returned`
- `late`

### D. Assignment status lifecycle
Recommended statuses:
- `draft`
- `published`
- `scheduled`
- `closed`
- `archived`

### E. Notification status lifecycle
Recommended statuses/fields:
- `read_at`
- `notification_type`
- `payload/jsonb`

### F. Comment model
Keep comments reusable with:
- polymorphic target
- `author_id`
- optional visibility rules

### G. Performance snapshots
Do not overcompute dashboard metrics from raw data on every request.
Later, use `student_performance_snapshots` for:
- average grades
- completion rates
- weekly performance summary
- overdue counts

---

## 9. Suggested PostgreSQL choices

### Use PostgreSQL features for flexibility
- `jsonb` for notification payloads, AI metadata, dynamic assignment config
- partial indexes for common filtered states
- enums or constrained strings for stable statuses
- foreign keys everywhere
- unique indexes for join-table integrity

### Examples of places where `jsonb` helps
- notification payload
- AI session metadata
- assignment settings
- frontend display metadata if needed

### Important indexes to add early
- users: unique email
- user_roles: unique `[user_id, role_id]`
- school_users: unique `[school_id, user_id]`
- classroom_users: unique `[classroom_id, user_id]`
- teacher_classrooms: unique `[classroom_id, user_id]`
- teacher_subjects: unique `[teacher_id, subject_id]`
- assignments: `[classroom_id, subject_id, due_at]`
- submissions: unique `[assignment_id, student_id]`
- notifications: `[user_id, read_at]`
- calendar_events: `[school_id, starts_at]`
- comments: polymorphic index on `[commentable_type, commentable_id]`
- activity_logs: polymorphic index on `[trackable_type, trackable_id]`

---

## 10. Suggested API resource map

## Auth
- `POST /api/v1/auth/login`
- `DELETE /api/v1/auth/logout`
- `GET /api/v1/auth/me`

## Schools
- `GET /api/v1/schools`
- `GET /api/v1/schools/:id`

## Users / profiles
- `GET /api/v1/profile`
- `PATCH /api/v1/profile`

## Teacher area
- `GET /api/v1/teacher/dashboard`
- `GET /api/v1/teacher/classrooms`
- `GET /api/v1/teacher/classrooms/:id`
- `GET /api/v1/teacher/subjects`
- `GET /api/v1/teacher/students/:id`

## Assignments
- `GET /api/v1/assignments`
- `POST /api/v1/assignments`
- `GET /api/v1/assignments/:id`
- `PATCH /api/v1/assignments/:id`
- `POST /api/v1/assignments/:id/publish`

## Assignment steps
- `POST /api/v1/assignments/:assignment_id/steps`
- `PATCH /api/v1/assignments/:assignment_id/steps/:id`

## Student work
- `GET /api/v1/student/dashboard`
- `GET /api/v1/student/assignments`
- `GET /api/v1/student/assignments/:id`
- `POST /api/v1/assignments/:assignment_id/submissions`
- `PATCH /api/v1/submissions/:id`
- `POST /api/v1/submissions/:id/submit`

## Grades and comments
- `POST /api/v1/submissions/:id/grades`
- `POST /api/v1/comments`
- `GET /api/v1/comments?commentable_type=Submission&commentable_id=...`

## Calendar
- `GET /api/v1/calendar/events`
- `POST /api/v1/calendar/events`
- `PATCH /api/v1/calendar/events/:id`

## Notifications
- `GET /api/v1/notifications`
- `POST /api/v1/notifications/:id/mark_as_read`

---

## 11. Suggested serializer / response approach

For React friendliness:
- keep JSON responses flat and predictable
- include small nested summaries, not huge deeply nested payloads
- paginate lists
- separate list endpoints from details endpoints

Example:
- dashboard endpoint returns ready-to-render cards
- assignment details endpoint returns assignment + steps + current submission state
- teacher classroom endpoint returns classroom summary + students + active assignments

---

## 12. Recommended service objects / business logic areas

Use service objects early for:
- `Assignments::Create`
- `Assignments::Publish`
- `Submissions::Start`
- `Submissions::SaveStepAnswer`
- `Submissions::Submit`
- `Grades::Create`
- `Notifications::Dispatch`
- `Dashboards::BuildStudentDashboard`
- `Dashboards::BuildTeacherDashboard`

This will keep controllers thin and help a lot when AI and workflow rules grow.

---

## 13. Suggested first migration order

1. `users`
2. `roles`
3. `user_roles`
4. `schools`
5. `school_users`
6. `teacher_profiles`
7. `student_profiles`
8. `classrooms`
9. `classroom_users`
10. `teacher_classrooms`
11. `subjects`
12. `teacher_subjects`
13. `assignments`
14. `assignment_steps`
15. `submissions`
16. `submission_step_answers`
17. `grades`
18. `comments`
19. `calendar_events`
20. `event_participants`
21. `notifications`
22. `activity_logs`
23. later: `student_performance_snapshots`
24. later: `announcements`
25. later: `attendance_records`
26. later: `ai_sessions`
27. later: `ai_messages`

---

## 14. Backend recommendation for your next concrete step

Best next implementation order in Rails API:

### Step 1
Set up auth + roles + school membership

### Step 2
Set up classrooms + teacher/student linking

### Step 3
Set up subjects + assignments + assignment_steps

### Step 4
Set up submissions + step answers + submit flow

### Step 5
Set up grades + polymorphic comments

### Step 6
Set up calendar events + notifications

### Step 7
Create ready-to-use dashboard endpoints for student and teacher

### Step 8
Add AI session models after the core learning workflow is stable

---

## 15. Final recommendation
Do **not** start with everything.

For this project, the best backend MVP is:
- strong auth and roles
- school/classroom structure
- teacher-to-subject/class relations
- assignment creation
- student submission flow
- grading/comments
- calendar/deadlines
- notifications

That will support the current frontend direction well and keep the system clean enough to extend with:
- AI tutoring
- performance analytics
- attendance
- announcements
- parent access

---

## Source basis used for this blueprint
- `ai_education_er_diagram_and_data_model.md`
- `student_dashboard_instructions.md`
- `student_dashboard_improvements.md`
- `student_ai_ui_improvements.md`
- `react_ai_student_ui_prompt.md`
- `next_steps_initial.md`