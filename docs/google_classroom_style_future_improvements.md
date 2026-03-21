# Google Classroom Style Future Improvements Guide

This document is a product and UI guide for future improvements inspired by Google Classroom-like flows, while staying aligned with the current AI education platform architecture.

The platform should remain simple, calm, school-safe, and easy to use for Macedonian schools.
Frontend is React.
Backend is Rails API.
All visible labels, buttons, tabs, and user-facing texts should be in Macedonian.

---

## 1. General design direction

Use a cleaner classroom-style layout with:
- light interface
- soft gray backgrounds
- white cards
- subtle borders instead of heavy shadows
- one clear accent color per area
- large readable typography
- generous spacing
- clear tabs and segmented sections

The UI should feel:
- focused
- calm
- school-safe
- not gamified too aggressively
- easy for teachers and students to scan quickly

Recommended visual style:
- top app bar
- page tabs under header where needed
- left side lists for people / assignment review areas
- wide content panel on the right
- card-based metrics and summaries
- simple icons
- rounded corners, but not overly playful

---

## 2. Core product rule

We are not cloning Google Classroom exactly.
We are borrowing the structure and clarity of the experience.
The system must still match our current backend domains:
- schools
- users
- teachers
- students
- classrooms
- subjects
- assignments
- assignment steps
- submissions
- grades
- notifications
- calendar
- student performance snapshots

This stays aligned with the current project model and flows. See the current data model and backend overview for the existing structure around classrooms, assignments, submissions, grades, calendar, dashboards, and performance snapshots. fileciteturn1file1L1-L52 fileciteturn1file5L1-L30

---

## 3. Student design improvements

## 3.1 Student dashboard

The student dashboard should move closer to a classroom workspace feel.

Recommended sections:
- **Следно за тебе**
- **Домашни задачи**
- **Рокови**
- **Мој напредок**
- **Известувања**
- **Календар**

The layout should be more structured and less homepage-like.
Use:
- top header
- small summary row
- assignment cards with status
- deadlines in a side card
- progress summary card
- recent grades or feedback card later

This matches the existing student dashboard direction and should remain based on compact cards, calm layout, and clear statuses such as `Не е започнато`, `Во тек`, `Предадено`, and `Задоцнето`. fileciteturn1file7L1-L40

## 3.2 Assignment/task details page

Each assignment should have a clearer entry page before solving.

Recommended content:
- title
- subject
- teacher
- due date
- short instructions
- attached materials
- number of steps/questions
- status badge
- button: **Започни** or **Продолжи**

This fits the earlier recommended flow:
**Контролна табла → Детали за задача → Работен простор → Предавање**. fileciteturn1file6L24-L40

## 3.3 Workspace / solving screen

The assignment solving screen should feel more like the first screenshot:
- clean question area
- visible current step indicator
- strong input focus
- obvious **Провери** action
- next / previous navigation when relevant
- progress strip above or below the header

Recommended student actions:
- **Провери**
- **Следно**
- **Назад**
- **Предај**

For step-based assignments, do not overload the screen.
Show one step clearly at a time when appropriate.

This is consistent with the current workflow where student submissions start, save step answers, receive returned answer statuses, and are finally submitted. fileciteturn1file3L14-L21 fileciteturn1file11L27-L76

---

## 4. Multiple choice and answer UX improvements

The student answering experience should support more polished question rendering.

## 4.1 Multiple choice questions

For multiple-option questions, the UI should look simple and classroom-like:
- question text at the top
- optional image/video/resource above the question
- radio options in a vertical list
- strong selected state
- disabled state after checking if needed
- small positive/neutral feedback state

Recommended Macedonian labels:
- **Избери точен одговор**
- **Провери**
- **Следно прашање**
- **Точен одговор**
- **Обиди се повторно**

## 4.2 Support mixed assignment types

Assignments should support:
- short text answer
- paragraph answer
- multiple choice
- file upload
- resource-based answering
- auto-checked steps
- teacher-reviewed steps

This remains aligned with the current assignment architecture, where steps can use `evaluation_mode`, answer keys, step prompts, example answers, and assignment or step resources. fileciteturn1file9L1-L18 fileciteturn1file13L47-L103

## 4.3 Immediate feedback design

When a question is auto-checkable, use simple feedback:
- green success state for correct
- red or muted warning state for incorrect
- neutral state for needs review

Do not expose answer keys to students.
Student-safe assignment payloads should stay clean and secure. fileciteturn1file11L13-L25

---

## 5. Assignments improvements for teachers

Backend note:
- reusable subject-level assignment topics are now supported, so teachers can create a topic under a subject and attach assignments to it through `subject_topic_id`

## 5.1 Export assignment to multiple classes

Teachers should be able to reuse and distribute one assignment to multiple classes from a modal-like flow.

Recommended action:
- button in teacher assignment area: **Додели во повеќе паралелки**

Recommended modal content:
- assignment title at top
- searchable classroom list
- checkbox list of classes
- option to create new class stays out of MVP if not needed
- confirm button: **Додели**

This should be implemented as a safe teacher workflow, not by duplicating UI hacks.
The concept should map to existing assignment/classroom relations in the backend.

## 5.2 Assignment list design

Teacher assignment lists should be cleaner and closer to classroom management tools.
Each row/card can show:
- title
- subject
- classroom
- due date
- submission count
- status
- menu with more actions

More actions can include:
- **Измени**
- **Прегледај предавања**
- **Додели во повеќе паралелки**
- **Дуплирај**
- **Архивирај**

---

## 6. Grades page redesign

The grades section should look more like a structured gradebook.

Recommended teacher page:
- top tabs: **Стрим**, **Задачи**, **Луѓе**, **Оценки** or equivalent in our navigation
- classroom filter
- subject / assignment columns
- student rows
- class average row on top
- clear score values
- simple scrolling table

Recommended Macedonian naming:
- **Оценки**
- **Просек на паралелка**
- **Вкупно бодови**
- **Предадено**
- **Недостасува**
- **Прегледај**

The page should support:
- viewing scores by class
- viewing assignment columns
- basic sorting
- opening a student submission from the table

This fits the current backend flow where teachers grade submissions and students receive grade notifications. fileciteturn1file3L22-L25

---

## 7. Classroom analytics

A teacher-facing analytics page should be added for each classroom.

Purpose:
- give a quick teaching overview
- help teachers spot missing work and weak performance
- keep metrics simple and actionable

Recommended metric cards:
- **Завршеност на задачи**
- **Просечна оценка**
- **Активни ученици**
- **Зададоцнети предавања**

Recommended simple charts:
- assignment completion trend
- average score trend
- active students trend
- optionally overdue count trend

Recommended filters:
- **Последни 7 дена**
- **Последни 30 дена**
- **Ова полугодие**

This aligns well with the planned `student_performance_snapshots` and classroom summary direction already identified in the backend plan. fileciteturn1file4L31-L39 fileciteturn1file8L31-L40

Important note:
Keep analytics easy to read.
Do not build a heavy BI dashboard.
The goal is classroom insight, not enterprise reporting.

---

## 8. People tab improvements

In our case, the People area can be simpler than Google Classroom.

Recommended teacher classroom page tabs:
- **Задачи**
- **Ученици**
- maybe later **Објави** or **Календар** if needed

## 8.1 Students tab

The students tab should be simple.
Show:
- name + surname only
- search field
- total student count near the title
- plus icon/button to add new student
- row menu with three dots

Recommended top bar:
- **Ученици**
- **+ Додај ученик**

Recommended per-student row actions inside the three dots:
- **Погледни профил**
- **Погледни задачи**
- **Погледни оценки**
- **Премести во друга паралелка**
- **Отстрани од паралелка**

Do not overload the row itself.
Just show a clean list.

This matches the school/classroom structure already defined through classrooms, classroom membership, and teacher-classroom relations. fileciteturn1file1L12-L20

---

## 9. Visit a class / teacher profile relation

We should add a page where a teacher can be opened to see what they teach.

Purpose:
- admin can inspect teacher assignment to classes
- teacher profile can show teaching load
- easier school management

Recommended page title:
- **Паралелки на наставник**
or
- **Што предава наставникот**

Recommended content:
- teacher avatar placeholder
- full name
- list of classrooms / subjects taught
- role per class if needed
- school context

Each row can show:
- class name
- subject
- teacher role if needed

This fits the current model where teachers connect to classrooms and subjects through dedicated relations. fileciteturn1file1L12-L20

---

## 10. Video + question learning flow

The screenshot with video and question below is a strong pattern for future interactive learning.

Recommended structure:
- learning resource at the top
- questions below in steps
- visible step circles/progress
- answer state per question
- final submit action

This can later be used for:
- video-based quizzes
- reading comprehension
- science explanation + questions
- guided lessons

It should still reuse the same assignment/submission architecture rather than becoming a separate isolated feature.

---

## 11. Navigation recommendations

For teachers, use a clearer classroom-like navigation.

Recommended top-level teacher navigation:
- **Контролна табла**
- **Паралелки**
- **Задачи**
- **Оценки**
- **Календар**
- **Аналитика**

Inside one class:
- **Задачи**
- **Оценки**
- **Ученици**
- **Аналитика**

For students:
- **Почетна**
- **Задачи**
- **Календар**
- **Оценки**
- **Напредок**

Keep the number of main navigation items controlled.

---

## 12. UI language recommendations

Because this is for Macedonian schools, user-facing labels should be in Macedonian.

Examples:
- **Задачи**
- **Оценки**
- **Ученици**
- **Наставници**
- **Паралелки**
- **Напредок**
- **Извештаи**
- **Аналитика**
- **Додај ученик**
- **Предај**
- **Провери**
- **Следно**
- **Назад**
- **Рок**
- **Просек**

Keep wording simple and school-appropriate.

---

## 13. Frontend implementation notes

Frontend should be prepared in a reusable way.

Recommended React page/component direction:
- `StudentDashboardPage`
- `StudentAssignmentDetailsPage`
- `StudentAssignmentWorkspacePage`
- `TeacherClassPage`
- `TeacherAssignmentsPage`
- `TeacherGradesPage`
- `TeacherAnalyticsPage`
- `TeacherStudentsTab`
- `TeacherProfileTeachingPage`
- `AssignToMultipleClassesModal`

Recommended reusable components:
- `PageHeader`
- `TabsNav`
- `MetricCard`
- `DataTable`
- `StudentList`
- `AssignmentStatusBadge`
- `ProgressStrip`
- `QuestionCard`
- `OptionList`
- `AnalyticsChartCard`
- `EmptyState`
- `ConfirmModal`

Use mock data first where needed, but keep props shaped close to the backend contracts.

---

## 14. Backend alignment notes

When implementing these UI changes, keep alignment with the existing backend expectations:
- role-based routing by `student`, `teacher`, `admin` remains unchanged. fileciteturn1file3L3-L6
- assignment details, steps, resources, and checking should reuse current assignment models and submission flow. fileciteturn1file3L8-L25 fileciteturn1file11L27-L76
- file attachments and rich resources should reuse the assignment resource architecture already described. fileciteturn1file9L19-L55
- classroom analytics should build on snapshot/reporting tables instead of ad hoc frontend-only calculations later. fileciteturn1file4L31-L39

---

## 15. Priority order for future improvements

Recommended order:

### Phase A – student assignment UX
1. improve assignment details page
2. improve workspace/step UI
3. improve multiple choice answering UI
4. improve result/submit states

### Phase B – teacher classroom UX
1. People tab / Students tab
2. assignment export to multiple classes
3. better assignment management screens
4. grades table redesign

### Phase C – insights and school management
1. classroom analytics page
2. visit a class / teacher teaching page
3. deeper class-level reporting

---

## 16. Final product direction

The goal is to make the platform feel:
- more classroom-native
- more structured
- more trustworthy for teachers
- easier for students to complete work
- visually closer to modern education tools

But it should still remain:
- simple
- safe
- aligned with our Rails API architecture
- aligned with current assignment/submission/grade flows
- appropriate for Macedonian schools
