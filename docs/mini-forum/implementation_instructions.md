````md
# Scoped Discussions / Mini-Forum – Backend Implementation Guide
## With Frontend Notes + TODO addendum for next features

## Goal
Implement a **controlled discussion system** for the education platform so students and teachers can communicate around learning content in a structured, school-safe way.

This is **not** a direct messaging replacement and **not** a free social feed.

It should work as a **scoped discussion domain** that can support:
- assignments
- classrooms
- subjects
- school-wide spaces

This fits the platform well because the system already has:
- schools
- users and roles
- classrooms
- subjects
- assignments
- comments
- notifications
- dashboards

---

# 1. Main architectural recommendation

## Use a broader discussion domain
Instead of building only assignment discussions, create a reusable architecture:

- `discussion_spaces`
- `discussion_threads`
- `discussion_posts`
- optional later: `discussion_post_reactions`
- optional later: `discussion_post_reports`
- optional later: `discussion_space_memberships`

This is cleaner long-term than attaching everything directly to assignments or overloading generic comments.

## Why this is better
This gives one unified system for:
- assignment Q&A
- classroom boards
- subject boards
- school notice discussions later

It also keeps:
- messaging separate
- grading comments separate
- discussion logic reusable

## Keep existing comments for
- grading comments
- submission comments
- teacher feedback notes
- simple commentable objects already in use

Use the new discussion domain only for forum-style communication.

---

# 2. Product direction

The discussion system should feel like:

- **assignment Q&A**
- **classroom board**
- **subject board**
- **school discussion space** (limited and controlled)

It should always be:
- school-scoped
- role-aware
- moderated
- auditable
- safe by default

---

# 3. MVP scope

## Build first
### A. Assignment discussions
Use case:
- students ask about instructions
- teachers clarify tasks
- assignment-specific Q&A

### B. Classroom discussions
Use case:
- class-level reminders
- homework questions
- schedule clarifications

### C. Subject discussions
Use case:
- topic help
- revision threads
- subject-specific questions

## Optional later
### D. School-wide discussions
Keep this limited at first:
- teacher/admin authored
- maybe read-only for students at first
- maybe discussion on school activities later

---

# 4. Core domain design

## 4.1 `discussion_spaces`
Represents the main scoped container.

A space is the parent scope where threads live.

Examples:
- one assignment space
- one classroom space
- one subject space
- one school-wide space

### Suggested fields
- `id`
- `school_id`
- `space_type`
- `title`
- `description`
- `status`
- `visibility`
- `assignment_id` nullable
- `classroom_id` nullable
- `subject_id` nullable
- `created_by_id`
- `created_at`
- `updated_at`

### Suggested `space_type`
- `assignment`
- `classroom`
- `subject`
- `school`

### Suggested `status`
- `active`
- `archived`
- `hidden`

### Suggested `visibility`
- `teachers_only`
- `students_and_teachers`
- `read_only`

### Rules
- each space belongs to exactly one school
- `assignment` space must have `assignment_id`
- `classroom` space must have `classroom_id`
- `subject` space must have `subject_id`
- `school` space uses only `school_id`
- related assignment/classroom/subject must belong to the same school

### Important note
For MVP, you can enforce **one space per scope**:
- one assignment → one discussion space
- one classroom → one discussion space
- one subject → one discussion space within school context

That keeps FE simple.

---

## 4.2 `discussion_threads`
Represents a topic inside a space.

Examples:
- "Прашања за домашната"
- "Подготовка за тест"
- "Неделни прашања по математика"

### Suggested fields
- `id`
- `discussion_space_id`
- `creator_id`
- `title`
- `body`
- `uploads` multiple files
- `status`
- `pinned`
- `locked`
- `posts_count`
- `last_post_at`
- `created_at`
- `updated_at`

### Suggested `status`
- `active`
- `archived`
- `hidden`

### Notes
- spaces group the context
- threads are the actual topics
- `locked` blocks new replies
- `pinned` helps teacher-important topics
- thread creation supports multiple uploads
- a thread may be created with text, uploads, or both

---

## 4.3 `discussion_posts`
Represents posts and replies inside a thread.

### Suggested fields
- `id`
- `discussion_thread_id`
- `author_id`
- `parent_post_id` nullable
- `body`
- `uploads` multiple files
- `status`
- `edited_at` nullable
- `deleted_at` nullable
- `created_at`
- `updated_at`

### Suggested `status`
- `visible`
- `hidden`
- `reported`
- `deleted`

### Notes
- `parent_post_id` supports replies
- for MVP, one-level reply nesting is enough
- soft delete is preferred over hard delete
- post creation supports multiple uploads
- a post may be created with text, uploads, or both

---

## 4.4 Optional later: `discussion_post_reactions`
Only add later if really needed.

### Suggested fields
- `id`
- `discussion_post_id`
- `user_id`
- `reaction_type`
- `created_at`

### Suggested `reaction_type`
- `like`
- `helpful`
- `thanks`

---

## 4.5 Optional later: `discussion_post_reports`
Useful for moderation workflows later.

### Suggested fields
- `id`
- `discussion_post_id`
- `reporter_id`
- `reason`
- `status`
- `created_at`
- `updated_at`

### Suggested `status`
- `open`
- `reviewed`
- `dismissed`
- `action_taken`

---

## 4.6 Optional later: `discussion_space_memberships`
Do **not** build this in MVP unless truly needed.

Use only if later you want:
- muted spaces
- followed spaces
- per-user notification preferences
- membership overrides

For MVP, access can be derived from:
- school membership
- classroom membership
- subject assignment
- assignment visibility

---

# 5. Key associations

## `DiscussionSpace`
- belongs_to `school`
- belongs_to `created_by`, class_name: `User`
- belongs_to `assignment`, optional: true
- belongs_to `classroom`, optional: true
- belongs_to `subject`, optional: true
- has_many `discussion_threads`, dependent: :destroy

## `DiscussionThread`
- belongs_to `discussion_space`
- belongs_to `creator`, class_name: `User`
- has_many `discussion_posts`, dependent: :destroy

## `DiscussionPost`
- belongs_to `discussion_thread`
- belongs_to `author`, class_name: `User`
- belongs_to `parent_post`, class_name: `DiscussionPost`, optional: true
- has_many `replies`, class_name: `DiscussionPost`, foreign_key: `parent_post_id`

---

# 6. Authorization and safety rules

This is critical for school usage.

## Core rules
- all discussions are school-scoped
- users can only access spaces in their allowed school context
- students must never see discussion spaces outside their allowed school/class/subject/assignment scope
- teachers can create/moderate within their allowed spaces
- admins can moderate within selected school context

## Assignment space access
### Student can access if:
- assignment is visible to that student
- student belongs to the same school
- student is in the linked classroom or allowed assignment scope

### Teacher can access if:
- teacher teaches the linked classroom/subject
- or teacher created the assignment
- or teacher/admin has allowed access in the same school

## Classroom space access
### Student can access if:
- student is enrolled in that classroom

### Teacher can access if:
- teacher is linked to that classroom
- or is school admin

## Subject space access
### Student can access if:
- subject is in the student’s allowed path or classroom scope

### Teacher can access if:
- teacher teaches that subject in that school
- or is school admin

## School space access
### Student access
- optional
- probably read-only or disabled at first

### Teacher/admin access
- allowed based on school membership and role

## Moderation rules
Teachers/admins should be able to:
- lock thread
- unlock thread
- archive thread
- hide post
- soft-delete post
- pin thread

Students should be able to:
- create thread only where allowed
- reply only where allowed
- edit own post later if desired
- never moderate others

---

# 7. Validations

## `discussion_spaces`
- `school_id` required
- `space_type` required
- `created_by_id` required
- `title` required
- correct scoped relation must be present depending on `space_type`
- assignment/classroom/subject must belong to the same school
- prevent duplicate active spaces for same scope if using one-space-per-scope rule

## `discussion_threads`
- `discussion_space_id` required
- `creator_id` required
- `title` required
- `body` optional or required depending on product choice
- enforce lock/archive rules at service/policy layer

## `discussion_posts`
- `discussion_thread_id` required
- `author_id` required
- `body` required unless attachments are introduced later
- `parent_post_id` must belong to the same thread
- reject whitespace-only posts

---

# 8. Suggested indexes

## On `discussion_spaces`
- index on `school_id`
- index on `space_type`
- index on `assignment_id`
- index on `classroom_id`
- index on `subject_id`
- index on `[school_id, space_type]`

## On `discussion_threads`
- index on `discussion_space_id`
- index on `creator_id`
- index on `[discussion_space_id, pinned]`
- index on `[discussion_space_id, updated_at]`
- index on `[discussion_space_id, last_post_at]`

## On `discussion_posts`
- index on `discussion_thread_id`
- index on `author_id`
- index on `parent_post_id`
- index on `[discussion_thread_id, created_at]`
- index on `[discussion_thread_id, parent_post_id]`

---

# 9. Recommended API design

Base path: `/api/v1`

## Spaces
- `GET /discussion_spaces`
- `POST /discussion_spaces`
- `GET /discussion_spaces/:id`
- `PATCH /discussion_spaces/:id`

## Threads
- `GET /discussion_spaces/:discussion_space_id/threads`
- `POST /discussion_spaces/:discussion_space_id/threads`
- `GET /discussion_threads/:id`
- `PATCH /discussion_threads/:id`
- `POST /discussion_threads/:id/lock`
- `POST /discussion_threads/:id/unlock`
- `POST /discussion_threads/:id/archive`
- `POST /discussion_threads/:id/pin`
- `POST /discussion_threads/:id/unpin`

## Posts
- `GET /discussion_threads/:discussion_thread_id/posts`
- `POST /discussion_threads/:discussion_thread_id/posts`
- `PATCH /discussion_posts/:id`
- `DELETE /discussion_posts/:id`
- `POST /discussion_posts/:id/hide`
- `POST /discussion_posts/:id/unhide`

---

# 10. Suggested endpoint behavior

## `GET /discussion_spaces`
Supports filters:
- `space_type`
- `assignment_id`
- `classroom_id`
- `subject_id`
- `status`

Use cases:
- get assignment discussion space
- get classroom discussion space
- get subject discussion space

For MVP, FE will often fetch one relevant space for the current page context.

---

## `POST /discussion_spaces`
Create a discussion space if needed.

### Example payload
```json
{
  "space_type": "classroom",
  "title": "Дискусија за 7-A",
  "description": "Општи прашања и известувања за класот.",
  "classroom_id": 10,
  "subject_id": 4,
  "visibility": "students_and_teachers"
}
````

### Product note

You may choose to create some spaces automatically:

* when assignment is published
* when classroom is created
* when subject/classroom linkage is created

That is often better than letting FE manually create them.

---

## `GET /discussion_spaces/:id`

Return:

* space meta
* scope info
* visibility
* status
* maybe pinned threads preview

---

## `GET /discussion_spaces/:discussion_space_id/threads`

Return:

* threads in that space
* ordered by pinned first, then last activity

---

## `POST /discussion_spaces/:discussion_space_id/threads`

Create a thread inside a space.

Use `multipart/form-data` when uploading files and send files as `files[]`.

### Example payload

```json
{
  "title": "Прашања за домашната по математика",
  "body": "Овде поставувајте прашања за задачите од оваа недела.",
  "files": ["<binary file 1>", "<binary file 2>"]
}
```

---

## `GET /discussion_threads/:id`

Return:

* thread meta
* creator
* space info
* stats
* optionally first page of posts

---

## `POST /discussion_threads/:id/posts`

Create a new post or reply inside a thread.

Use `multipart/form-data` when uploading files and send files as `files[]`.

### Example top-level post payload

```json
{
  "body": "Дали треба да решиме и задача број 5?",
  "files": ["<binary file 1>"]
}
```

### Example reply payload

```json
{
  "body": "Да, решете ги сите 5 задачи.",
  "parent_post_id": 34
}
```

---

# 11. Suggested response shapes

## Discussion space response

```json
{
  "id": 7,
  "space_type": "assignment",
  "title": "Дискусија за задачата",
  "description": "Прашања и одговори поврзани со оваа задача.",
  "status": "active",
  "visibility": "students_and_teachers",
  "school": {
    "id": 2,
    "name": "ОУ Кочо Рацин"
  },
  "assignment": {
    "id": 11,
    "title": "Равенки"
  },
  "classroom": {
    "id": 10,
    "name": "7-A"
  },
  "subject": {
    "id": 4,
    "name": "Математика"
  }
}
```

## Thread response

```json
{
  "id": 12,
  "discussion_space_id": 7,
  "title": "Прашања за задачата",
  "body": "Поставувајте прашања поврзани со оваа задача.",
  "status": "active",
  "pinned": false,
  "locked": false,
  "posts_count": 8,
  "last_post_at": "2026-03-17T18:10:00Z",
  "attachments": [
    {
      "id": 201,
      "attachment_type": "pdf",
      "file_name": "homework-guide.pdf",
      "content_type": "application/pdf",
      "file_size": 12455,
      "file_url": "https://api.example.com/rails/active_storage/blobs/..."
    }
  ],
  "creator": {
    "id": 15,
    "full_name": "Ана Трајковска"
  }
}
```

## Post response

```json
{
  "id": 55,
  "discussion_thread_id": 12,
  "author": {
    "id": 45,
    "full_name": "Марија Стојанова",
    "role": "student"
  },
  "parent_post_id": null,
  "body": "Дали треба да решиме и задача број 5?",
  "status": "visible",
  "edited_at": null,
  "deleted_at": null,
  "created_at": "2026-03-17T18:12:00Z",
  "attachments": [
    {
      "id": 301,
      "attachment_type": "file",
      "file_name": "my-notes.txt",
      "content_type": "text/plain",
      "file_size": 512,
      "file_url": "https://api.example.com/rails/active_storage/blobs/..."
    }
  ],
  "replies_count": 1
}
```

---

# 12. Notification integration

This should connect to the existing notifications system.

## Trigger notifications for:

* new teacher reply in a thread
* new thread in classroom/subject/assignment scope
* teacher response to a student question
* locked thread if needed

## Suggested notification event types

* `discussion_space_created`
* `discussion_thread_created`
* `discussion_post_created`
* `discussion_reply_created`
* `discussion_thread_locked`

## MVP recommendation

* notify only relevant users in same classroom/assignment/subject scope
* avoid noisy broadcasts
* no complex per-user subscriptions yet

---

# 13. Frontend notes

This is backend-first, but API shape should be FE-friendly.

## Student side

* assignment page → tab: **Дискусија**
* classroom page → section: **Дискусии**
* subject page → section: **Прашања и дискусија**

## Teacher side

* thread moderation controls
* reply UI
* lock/archive/pin actions
* visible teacher identity badge

## Suggested Macedonian labels

* **Дискусија**
* **Прашања и одговори**
* **Нова тема**
* **Постави прашање**
* **Одговори**
* **Заклучи тема**
* **Отклучи тема**
* **Архивирај**
* **Прикачи на врв**
* **Сокриј објава**
* **Нема објави**
* **Биди прв што ќе постави прашање**

## FE behavior

* show space thread list by context
* show posts count and last activity
* allow replies
* disable input if thread is locked
* show teacher badge on teacher posts
* show empty states
* add pagination or load-more later

## FE MVP scope

* discussion tab/section in assignment
* thread list
* thread detail page
* reply input
* teacher moderation controls

Skip for now:

* reactions
* file attachments
* rich mentions
* advanced nested replies

---

# 14. Recommended implementation order

## Step 1

Create migrations and models:

* `discussion_spaces`
* `discussion_threads`
* `discussion_posts`

## Step 2

Add:

* associations
* validations
* policies
* query scopes

## Step 3

Implement read endpoints:

* space list
* space detail
* thread list
* thread detail
* post list

## Step 4

Implement write flows:

* create space if needed
* create thread
* create post
* create reply

## Step 5

Implement moderation:

* lock/unlock
* archive
* pin/unpin
* hide/unhide
* soft delete

## Step 6

Add notifications

## Step 7

Expose feature in:

* assignment page
* classroom page
* subject page

---

# 15. Service objects recommendation

Keep controllers thin.

Suggested services:

* `DiscussionSpaces::Create`
* `DiscussionSpaces::ResolveForScope`
* `DiscussionThreads::Create`
* `DiscussionThreads::Update`
* `DiscussionThreads::Lock`
* `DiscussionThreads::Unlock`
* `DiscussionThreads::Archive`
* `DiscussionThreads::Pin`
* `DiscussionPosts::Create`
* `DiscussionPosts::Update`
* `DiscussionPosts::Hide`
* `DiscussionPosts::SoftDelete`

---

# 16. Policy layer

Create:

* `DiscussionSpacePolicy`
* `DiscussionThreadPolicy`
* `DiscussionPostPolicy`

Policies should answer:

* can view space?
* can create space?
* can view thread?
* can create thread?
* can reply?
* can edit own post?
* can moderate?
* can archive?
* can hide/delete?

---

# 17. Product guardrails

Keep this feature controlled.

## Do not allow for now

* open student social feed
* anonymous posting
* public global boards
* free student-to-student chat outside learning scope
* profile/follower mechanics
* unrelated social features

## Always keep discussions scoped to

* assignment
* classroom
* subject
* school

That keeps the feature educational and safe.

---

# 18. Final MVP definition

Build this first as:

1. assignment discussion spaces
2. classroom discussion spaces
3. subject discussion spaces

with:

* one reusable discussion domain
* space + thread + post models
* teacher/admin moderation
* scoped visibility
* notification hooks
* FE-ready response shapes

This gives the platform a strong collaboration layer without turning it into a noisy social network.

---

# TODO – Next Features (Add to README)

## 1. Smart Study Mode

### Short description

Add a personalized AI-powered daily learning area.

Student should see:

* weak topics
* recommended practice
* short daily exercises
* resume-study suggestions

### Goal

Turn the platform into a daily learning companion, not only an assignment tracker.

### Future implementation notes

Use data such as:

* submissions
* grades
* performance snapshots
* AI sessions/messages

### Suggested Macedonian labels

* **Учиме денес**
* **Препорачани задачи**
* **Слаби теми**
* **Вежбај 5 минути**
* **Продолжи со учење**

---

## 2. Gamification + Progress System

### Short description

Add:

* XP / points
* streaks
* badges
* levels
* progress indicators

### Goal

Increase motivation, retention, and daily engagement.

### Future implementation notes

Start simple:

* points for completed assignments
* streak for active days
* badges for milestones
* dashboard progress card

### Suggested Macedonian labels

* **Поени**
* **Ниво**
* **Серија**
* **Значки**
* **Мој напредок**

---

## Instruction for code editor AI helper

Please add the two items above to the project TODO / README as future roadmap features.

Requirements:

* add short BE notes
* add short FE notes
* do not implement them yet
* list them after the new scoped discussion / mini-forum feature

```
```
