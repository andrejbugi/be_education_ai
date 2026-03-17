# Backend Phase 2 Blueprint – AI Education Platform

## Stack
- **Backend:** Rails API
- **Database:** PostgreSQL
- **Frontend consumer:** React app
- **UI language:** Macedonian

---

## 1. Goal of Phase 2
Phase 2 extends the finished Phase 1 backend with features that make the platform feel more complete for real school usage.

Phase 1 already covered the core workflow:
- authentication and roles
- schools, classrooms, teachers, students
- subjects
- assignments and assignment steps
- submissions
- grading
- comments
- calendar basics
- notifications
- activity logs

Phase 2 should now focus on:
- **homeroom / class teacher structure**
- **announcements**
- **attendance tracking**
- **student performance snapshots / reporting**
- **AI session persistence**
- **AI message history**
- optional refinement of scheduling, dashboards, and communication flow

---

## 2. Main Phase 2 tables
These are the main Phase 2 additions:

- `homeroom_assignments`
- `announcements`
- `attendance_records`
- `student_performance_snapshots`
- `ai_sessions`
- `ai_messages`

These are consistent with the original project data model and were already identified as second-phase tables in the earlier backend plan.

---

## 3. What Phase 2 adds to the product

### 3.1 Homeroom / class teacher logic
This supports the real school structure where a classroom may have one main teacher or homeroom teacher.

Use cases:
- show who is responsible for a classroom
- allow special homeroom notices
- support classroom-specific communication and reporting
- support parent/admin reporting later

### 3.2 Announcements
This adds a structured communication layer.

Use cases:
- school-wide announcements
- classroom announcements
- subject-specific announcements
- reminders from teachers
- visibility in student and teacher dashboards
- downloadable files attached to announcements

### 3.3 Attendance
This adds school operation support beyond learning content.

Use cases:
- track present / absent / late
- simple teacher attendance entry
- dashboard attendance summaries later
- reporting per classroom and student

### 3.4 Performance snapshots
This makes the dashboard faster and more useful.

Use cases:
- average grade
- completion rate
- overdue tasks count
- weekly / monthly summary
- positive progress cards on student dashboard

### 3.5 AI session persistence
This adds the foundation for a real AI learning workspace.

Use cases:
- save AI-assisted problem-solving sessions
- save session history per student
- allow “continue where you stopped”
- analyze learning behavior later

### 3.6 AI messages
This stores step-by-step interaction inside an AI session.

Use cases:
- user messages
- assistant responses
- hints
- structured tutor steps
- feedback history

---

## 4. Recommended Phase 2 model details

## 4.1 `homeroom_assignments`
Purpose:
Connect a teacher to a classroom as the main / homeroom teacher.

Recommended fields:
- `school_id`
- `classroom_id`
- `teacher_id`
- `active`
- `starts_on`
- `ends_on`
- timestamps

Recommended rules:
- only one active homeroom teacher per classroom for MVP
- keep dates to allow historical tracking later

Recommended indexes:
- unique partial index for active classroom homeroom assignment
- index on `[classroom_id]`
- index on `[teacher_id]`
- index on `[school_id]`

Recommended associations:
- `HomeroomAssignment belongs_to :school`
- `HomeroomAssignment belongs_to :classroom`
- `HomeroomAssignment belongs_to :teacher, class_name: 'User'`

---

## 4.2 `announcements`
Purpose:
Central message/notice model for school communication.

Recommended scope support:
- school-wide
- classroom-specific
- subject-specific
- teacher-authored

Recommended fields:
- `school_id`
- `author_id`
- `classroom_id` nullable
- `subject_id` nullable
- `title`
- `body`
- attachment via Active Storage (`file`)
- `status`
- `published_at`
- `starts_at` nullable
- `ends_at` nullable
- `priority`
- `audience_type` or simple targeting fields
- timestamps

Recommended statuses:
- `draft`
- `published`
- `archived`

Recommended priorities:
- `normal`
- `important`
- `urgent`

Recommended indexes:
- `[school_id, published_at]`
- `[classroom_id, published_at]`
- `[subject_id, published_at]`
- `[author_id]`
- `[status]`

Recommended associations:
- `Announcement belongs_to :school`
- `Announcement belongs_to :author, class_name: 'User'`
- `Announcement belongs_to :classroom, optional: true`
- `Announcement belongs_to :subject, optional: true`
- `Announcement has_many :comments, as: :commentable`

Recommended behavior:
- teacher creates draft
- teacher publishes announcement
- students see it in dashboard / notifications
- comments can optionally attach later if needed

---

## 4.3 `attendance_records`
Purpose:
Store attendance per student for classroom/subject/date.

Recommended fields:
- `school_id`
- `classroom_id`
- `subject_id` nullable
- `student_id`
- `teacher_id`
- `attendance_date`
- `status`
- `note` nullable
- timestamps

Recommended statuses:
- `present`
- `absent`
- `late`
- `excused`

Recommended indexes:
- unique index on `[student_id, classroom_id, subject_id, attendance_date]` with care if subject is nullable
- or split logic at application level if nullable complexity is not wanted
- index on `[classroom_id, attendance_date]`
- index on `[student_id, attendance_date]`
- index on `[teacher_id]`
- index on `[school_id]`

Recommended associations:
- `AttendanceRecord belongs_to :school`
- `AttendanceRecord belongs_to :classroom`
- `AttendanceRecord belongs_to :subject, optional: true`
- `AttendanceRecord belongs_to :student, class_name: 'User'`
- `AttendanceRecord belongs_to :teacher, class_name: 'User'`

Recommended MVP behavior:
- teacher marks attendance per class/day
- dashboard can later count absences and lateness

---

## 4.4 `student_performance_snapshots`
Purpose:
Store precomputed student metrics for dashboards and reports.

Recommended fields:
- `school_id`
- `student_id`
- `classroom_id` nullable
- `period_type`
- `period_start`
- `period_end`
- `average_grade`
- `completed_assignments_count`
- `in_progress_assignments_count`
- `overdue_assignments_count`
- `missed_assignments_count`
- `attendance_rate` nullable
- `engagement_score` nullable
- `snapshot_data` jsonb
- `generated_at`
- timestamps

Recommended period types:
- `weekly`
- `monthly`
- `term`
- `custom`

Recommended indexes:
- `[student_id, period_type, period_start]`
- `[school_id, period_type, period_start]`
- `[classroom_id, period_type, period_start]`
- GIN index on `snapshot_data` only if later needed

Recommended associations:
- `StudentPerformanceSnapshot belongs_to :school`
- `StudentPerformanceSnapshot belongs_to :student, class_name: 'User'`
- `StudentPerformanceSnapshot belongs_to :classroom, optional: true`

Recommended behavior:
- generated by background/service logic later
- read-heavy model for dashboard cards
- should not be updated on every request

---

## 4.5 `ai_sessions`
Purpose:
Store one AI workspace session for a user.

Recommended fields:
- `school_id`
- `user_id`
- `assignment_id` nullable
- `submission_id` nullable
- `subject_id` nullable
- `title` nullable
- `session_type`
- `status`
- `started_at`
- `last_activity_at`
- `ended_at` nullable
- `context_data` jsonb
- timestamps

Recommended session types:
- `assignment_help`
- `practice`
- `revision`
- `freeform`

Recommended statuses:
- `active`
- `paused`
- `completed`
- `archived`

Recommended indexes:
- `[user_id, status, last_activity_at]`
- `[assignment_id]`
- `[submission_id]`
- `[school_id]`
- `[subject_id]`

Recommended associations:
- `AiSession belongs_to :school`
- `AiSession belongs_to :user`
- `AiSession belongs_to :assignment, optional: true`
- `AiSession belongs_to :submission, optional: true`
- `AiSession belongs_to :subject, optional: true`
- `AiSession has_many :ai_messages, dependent: :destroy`

Recommended behavior:
- student opens workspace
- session starts
- messages are appended
- session can continue later

---

## 4.6 `ai_messages`
Purpose:
Store the message history inside an AI session.

Recommended fields:
- `ai_session_id`
- `role`
- `message_type`
- `content`
- `sequence_number`
- `metadata` jsonb
- `created_at`

Recommended roles:
- `user`
- `assistant`
- `system`

Recommended message types:
- `question`
- `hint`
- `feedback`
- `step`
- `summary`
- `error`

Recommended indexes:
- `[ai_session_id, sequence_number]` unique
- `[ai_session_id, created_at]`
- optional GIN on `metadata` if needed later

Recommended associations:
- `AiMessage belongs_to :ai_session`

Recommended behavior:
- preserve strict ordering
- keep content safe and auditable
- support later analytics on hints / retries / completions

---

## 5. Phase 2 relationships to add

### Homeroom
- `Classroom has_one :active_homeroom_assignment`
- `Classroom has_many :homeroom_assignments`
- `User has_many :homeroom_assignments, foreign_key: :teacher_id`

### Announcements
- `School has_many :announcements`
- `User has_many :authored_announcements, foreign_key: :author_id`
- `Classroom has_many :announcements`
- `Subject has_many :announcements`

### Attendance
- `Student/User has_many :attendance_records, foreign_key: :student_id`
- `Teacher/User has_many :recorded_attendance_records, foreign_key: :teacher_id`
- `Classroom has_many :attendance_records`
- `Subject has_many :attendance_records`

### Performance snapshots
- `User has_many :student_performance_snapshots, foreign_key: :student_id`
- `School has_many :student_performance_snapshots`

### AI workspace
- `User has_many :ai_sessions`
- `AiSession has_many :ai_messages`
- `Assignment has_many :ai_sessions`
- `Submission has_many :ai_sessions`

---

## 6. Recommended APIs for Phase 2

## Homeroom
- `GET /api/v1/teacher/homerooms`
- `POST /api/v1/classrooms/:classroom_id/homeroom_assignment`
- `PATCH /api/v1/homeroom_assignments/:id`

## Announcements
- `GET /api/v1/announcements`
- `POST /api/v1/announcements`
- `GET /api/v1/announcements/:id`
- `PATCH /api/v1/announcements/:id`
- `POST /api/v1/announcements/:id/publish`
- `POST /api/v1/announcements/:id/archive`

## Attendance
- `GET /api/v1/attendance_records`
- `POST /api/v1/attendance_records`
- `PATCH /api/v1/attendance_records/:id`
- `GET /api/v1/classrooms/:id/attendance`
- `GET /api/v1/students/:id/attendance`

## Performance snapshots
- `GET /api/v1/student/performance`
- `GET /api/v1/students/:id/performance_snapshots`
- `GET /api/v1/classrooms/:id/performance_overview`

## AI sessions
- `GET /api/v1/ai_sessions`
- `POST /api/v1/ai_sessions`
- `GET /api/v1/ai_sessions/:id`
- `PATCH /api/v1/ai_sessions/:id`
- `POST /api/v1/ai_sessions/:id/close`

## AI messages
- `GET /api/v1/ai_sessions/:ai_session_id/messages`
- `POST /api/v1/ai_sessions/:ai_session_id/messages`

---

## 7. Recommended service objects for Phase 2
Use service objects again to keep controllers thin.

Suggested services:
- `HomeroomAssignments::AssignTeacher`
- `Announcements::Create`
- `Announcements::Publish`
- `Attendance::BulkMark`
- `PerformanceSnapshots::GenerateForStudent`
- `PerformanceSnapshots::GenerateForClassroom`
- `AiSessions::Start`
- `AiSessions::Resume`
- `AiMessages::Append`
- `AiSessions::Complete`

---

## 8. Recommended implementation order for Phase 2

### Step 1 – Announcements
Best first addition because it is useful, visible, and not too risky.

Add:
- `announcements`
- dashboard feed integration
- optional notification creation when published

### Step 2 – Homeroom assignments
Important for real school structure.

Add:
- `homeroom_assignments`
- teacher/classroom responsibility logic

### Step 3 – Attendance
Useful school feature and good expansion of teacher workflows.

Add:
- `attendance_records`
- classroom attendance entry endpoints

### Step 4 – Performance snapshots
Best after attendance and more usage data exist.

Add:
- precomputed metrics
- student dashboard summary endpoints
- teacher classroom summaries

### Step 5 – AI sessions and messages
Add this after the core assignment flow is stable enough.

Add:
- `ai_sessions`
- `ai_messages`
- session resume logic
- later connect to real AI workflows

---

## 9. Recommended migration order for Phase 2
1. `homeroom_assignments`
2. `announcements`
3. `attendance_records`
4. `student_performance_snapshots`
5. `ai_sessions`
6. `ai_messages`

This order is safe because:
- it builds on already existing Phase 1 models
- AI models depend on users and likely assignments/submissions already existing
- reporting comes after operational data exists

---

## 10. PostgreSQL recommendations for Phase 2

### Use `jsonb` in these places
Recommended:
- `student_performance_snapshots.snapshot_data`
- `ai_sessions.context_data`
- `ai_messages.metadata`

### Use careful uniqueness rules
Examples:
- one active homeroom teacher per classroom
- one ordered sequence number per AI session message

### Avoid over-normalizing too early
For Phase 2, keep it practical:
- announcement targeting can stay simple at first
- attendance can avoid too many special cases initially
- AI metadata can stay flexible inside `jsonb`

---

## 11. Dashboard impact of Phase 2

### Student dashboard gains
- announcements feed
- better progress summaries
- attendance summaries later
- AI session resume card

### Teacher dashboard gains
- homeroom classroom ownership
- announcement management
- attendance entry/review
- better classroom performance insights

### Future admin dashboard gains
- school attendance overview
- school performance overview
- communication oversight

---

## 12. Safety and product notes for AI features
Because this is for Macedonian schools and student use, Phase 2 AI should stay controlled.

Recommended approach:
- store AI session history for auditability
- keep assistant role instructional, not open-ended by default
- link sessions to assignment or subject where possible
- avoid fully freeform unsafe assistant behavior for student accounts
- preserve message history for teacher/admin review later if needed

Good controlled use cases:
- step hint
- explanation of solution
- guided practice
- revision questions
- structured help inside assignment workspace

---

## 13. Final Phase 2 recommendation
The best practical Phase 2 scope is:

1. **Announcements**
2. **Homeroom assignments**
3. **Attendance records**
4. **Performance snapshots**
5. **AI sessions + AI messages**

This order keeps the project realistic:
- first expand school workflow
- then improve reporting
- then add persistent AI learning support

---

## 14. Source basis used for this Phase 2 blueprint
- `ai_education_er_diagram_and_data_model.md`
- `student_dashboard_instructions.md`
- `student_dashboard_improvements.md`
- `student_ai_ui_improvements.md`
- `react_ai_student_ui_prompt.md`
- `next_steps_initial.md`
