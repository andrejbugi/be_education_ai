# Quiz of the Day + Learning Games

## Goal
Add a new student feature area with two separate parts:
1. **Quiz of the Day**
2. **Learning Games**

This feature is meant to support learning in a light, engaging way, without mixing it with formal assignments.

It should be available **outside school hours** so it does not distract students during classes.

---

## Product direction

### 1. Quiz of the Day
- one question per day
- focused on **geography** and **history of Macedonia**
- student can answer only **once per day**
- reset happens at **00:00** in local school time
- if answered correctly, student gets **+1 XP**
- not graded
- not part of assignment submissions
- should feel like a short daily challenge
- quiz should be available during the whole day

### 2. Learning Games
- separate from the quiz
- mostly **frontend-based** in the first phase
- examples later:
  - simple geometry game
  - basic math tasks
  - logic mini-games
  - pattern/shape exercises
- no history tracking in v1
- no scoring persistence in v1 unless added later
- games are only visible/playable in the allowed time window

---

## Important architecture decision
This feature should be a **separate domain** from:
- assignments
- submissions
- grades
- AI sessions

Do not try to model Quiz of the Day as an assignment.
Do not reuse assignment step answer flows for this.

This should stay lightweight and isolated.

---

# Backend instructions

## 1. Main backend scope for v1
Backend should implement:
- daily quiz question management
- student daily answer handling
- once-per-day rule
- correctness check
- +1 XP reward on correct answer
- allowed time window checks
- game availability config

Backend does **not** need to implement the games themselves yet.
Backend only needs to support:
- whether games are available now
- which game cards are enabled to show on FE

---

## 2. Recommended data model

### `daily_quiz_questions`
Purpose: store one daily quiz question.

Suggested fields:
- `id`
- `school_id` nullable if later school-specific, or null for global content
- `quiz_date`
- `title`
- `body`
- `category` (`geography`, `history`)
- `difficulty` nullable
- `answer_type` (`single_choice`, `text`)
- `correct_answer`
- `answer_options` jsonb nullable
- `explanation` nullable
- `is_active`
- `created_by_id` nullable
- `created_at`
- `updated_at`

Notes:
- for MVP, use **single_choice** first if you want simpler FE and BE validation
- text answers can be supported later if needed
- ideally only one active question per date

### `daily_quiz_answers`
Purpose: store one student answer for one quiz date.

Suggested fields:
- `id`
- `school_id`
- `student_id`
- `daily_quiz_question_id`
- `quiz_date`
- `selected_answer` nullable
- `answer_text` nullable
- `is_correct`
- `answered_at`
- `xp_awarded` default `0`
- `created_at`
- `updated_at`

Recommended uniqueness:
- unique index on `student_id + quiz_date + school_id`

This ensures one answer per student per day.

### `student_rewards` or existing rewards table integration
If a rewards / awards / XP table already exists or will exist, connect the quiz reward there.

Minimal requirement for now:
- when correct, add `+1 XP`
- store enough reference metadata so it is clear XP came from `daily_quiz`

Suggested reward metadata:
- source type: `daily_quiz`
- source id: `daily_quiz_question_id`
- awarded_on date

### `learning_game_configs`
Purpose: allow FE to know which games to show.

Suggested fields:
- `id`
- `school_id` nullable
- `game_key`
- `title`
- `description`
- `icon_key` nullable
- `is_enabled`
- `position`
- `metadata` jsonb
- `created_at`
- `updated_at`

Example `game_key` values:
- `geometry_shapes`
- `basic_math_speed`
- `memory_pairs`
- `logic_patterns`

This table is only for availability/catalog in v1.

---

## 3. Time window / access rules
The system should support an allowed feature window for learning games.

Recommended default:
- `18:00` to `20:00`

But do **not** hardcode this permanently.
It should be configurable later per school.

Recommended backend behavior:
- quiz should remain available during the full local day
- if current local time is outside allowed window:
  - games availability endpoint returns `available_now: false`
- FE may still show the section, but actions should be locked

Important:
- backend must enforce the games window too
- not only frontend

Also add support for blocking during school hours by config.

---

## 4. Suggested API endpoints

### Student endpoints

#### `GET /api/v1/student/daily_quiz`
Returns today’s quiz state for the current student.

Suggested response shape:
```json
{
  "date": "2026-03-19",
  "available_now": true,
  "available_from": "18:00",
  "available_until": "20:00",
  "already_answered": false,
  "question": {
    "id": 12,
    "title": "Квиз на денот",
    "body": "Кој град е главен град на Македонија?",
    "category": "geography",
    "answer_type": "single_choice",
    "answer_options": ["Битола", "Скопје", "Охрид", "Тетово"]
  },
  "reward": {
    "correct_xp": 1
  }
}
```

If already answered, response should include answer result instead of allowing resubmit.

#### `POST /api/v1/student/daily_quiz/answer`
Create today’s answer.

Suggested request:
```json
{
  "daily_quiz_question_id": 12,
  "selected_answer": "Скопје"
}
```

Suggested response:
```json
{
  "correct": true,
  "xp_awarded": 1,
  "already_answered": true,
  "explanation": "Скопје е главен град на Македонија."
}
```

Rules:
- only one answer per student per current quiz date
- reject second submit for same day
- reject submit outside allowed window
- validate school scope

#### `GET /api/v1/student/learning_games`
Returns the games catalog and current availability.

Suggested response:
```json
{
  "available_now": true,
  "available_from": "18:00",
  "available_until": "20:00",
  "games": [
    {
      "game_key": "geometry_shapes",
      "title": "Геометрија",
      "description": "Препознај форми и агли.",
      "is_enabled": true,
      "position": 1
    },
    {
      "game_key": "basic_math_speed",
      "title": "Брза математика",
      "description": "Решавај кратки математички задачи.",
      "is_enabled": true,
      "position": 2
    }
  ]
}
```

In v1 this endpoint is only for FE structure and visibility.

---

## 5. Admin / teacher content management
For MVP, quiz content can be seeded manually or created from admin-only tooling later.

Recommended initial approach:
- seed several weeks of questions
- keep content curated and reviewed
- do not AI-generate the questions for students in v1

Later optional endpoints:
- `POST /api/v1/admin/daily_quiz_questions`
- `PATCH /api/v1/admin/daily_quiz_questions/:id`
- `GET /api/v1/admin/daily_quiz_questions`

Teacher editing is optional later.
Admin-only is enough for MVP.

---

## 6. Backend validation rules
Backend should validate:
- question exists for today
- question is active
- student belongs to school context
- answer is submitted only once per day
- answer is submitted only in allowed window
- XP is awarded only once
- duplicate requests do not create duplicate XP records

Important:
use an idempotent-safe approach so repeated submits do not grant extra XP.

---

## 7. Backend service suggestions
Recommended services:
- `DailyQuizAvailabilityService`
- `DailyQuizAnswerService`
- `DailyQuizRewardService`
- `LearningGamesAvailabilityService`

This keeps controller logic small and clean.

---

# Frontend instructions

## 1. Main frontend scope for now
Frontend should implement:
- where this feature appears
- how the quiz card is shown
- how the games section is shown
- locked/unlocked state by time window
- answer flow for the quiz
- placeholder cards/pages for games

Frontend does **not** need to build the real games yet.
That comes later.

---

## 2. Where students access this feature
Recommended place:
- student dashboard
- as a dedicated section/card
- and optionally also a dedicated page in navigation

### Recommended navigation labels in Macedonian
- `Почетна`
- `Домашни`
- `Календар`
- `Квиз на денот`
- `Игри за учење`
- `Профил`

If you want to keep navigation smaller for now, then:
- show one dashboard card block called `Квиз и игри`
- clicking it opens a dedicated page

Recommended route structure:
- `/student/daily-quiz`
- `/student/learning-games`

---

## 3. Dashboard placement recommendation
On the student dashboard, add a medium-priority card block below the main urgent academic items.

This should **not** replace homework, deadlines, or school tasks.
It should be secondary.

Suggested dashboard card:

### `Квиз и игри`
Show:
- whether feature is open now
- today’s quiz short teaser
- button to open quiz
- small row of game cards
- time note like `Достапно од 18:00 до 20:00`

Example Macedonian labels:
- `Квиз на денот`
- `Игри за учење`
- `Достапно вечерва`
- `Сега е затворено`
- `Отвори`
- `Види игри`

---

## 4. Quiz page structure
Recommended page title:
- `Квиз на денот`

Recommended page layout:
1. page header
2. availability info bar
3. main quiz card
4. result/explanation state
5. small rewards note

### Quiz card contents
- title
- category badge: `Географија` or `Историја`
- question text
- answer options
- submit button
- disabled state when already answered

### Result state after submit
Show one of these:
- `Точен одговор! +1 XP`
- `Неточен одговор`
- short explanation
- note that next quiz comes after midnight / next day

### Locked state outside time window
Show a locked card:
- `Квизот ќе биде достапен од 18:00 до 20:00`
- optional countdown later

Important FE rule:
- once answer is submitted, keep page in read-only result state
- do not allow second attempt

---

## 5. Games page structure
Recommended page title:
- `Игри за учење`

Recommended page layout:
1. page header
2. availability banner
3. responsive grid of game cards
4. optional “coming soon” note on games not yet implemented

Each game card can contain:
- icon
- title
- short description
- difficulty label optional
- status label:
  - `Достапно`
  - `Затворено`
  - `Наскоро`
- action button:
  - `Отвори`
  - `Наскоро`

For now, clicking a game can open:
- a placeholder detail page
- or a modal/card saying game implementation comes later

---

## 6. FE component suggestion

### Dashboard
- `QuizGamesCard`
- `DailyQuizPreviewCard`
- `LearningGamesPreviewRow`

### Daily quiz page
- `DailyQuizPage`
- `QuizAvailabilityBanner`
- `DailyQuizCard`
- `QuizAnswerOptions`
- `QuizResultCard`
- `QuizRewardNote`

### Learning games page
- `LearningGamesPage`
- `GamesAvailabilityBanner`
- `GameCard`
- `GamesGrid`
- `GamePlaceholderState`

---

## 7. FE state behavior
Frontend should rely on backend for source of truth.

Important FE states:
- loading
- available now
- locked by time window
- no quiz configured
- already answered
- answered correct
- answered incorrect

Do not calculate reward locally.
Use backend response for:
- `correct`
- `xp_awarded`
- `already_answered`

---

## 8. Visual/design direction
The quiz should feel similar in spirit to a daily puzzle / daily challenge card:
- one focused challenge
- visually important central card
- quiet dark/light friendly layout
- small reward callout
- no clutter

The games page should feel more playful than assignments, but still school-safe and clean.

Good direction:
- rounded cards
- stronger hero card for the daily quiz
- compact cards for 3–4 games
- clear locked state outside allowed hours

---

## 9. Macedonian UI labels
Use Macedonian labels for visible UI.

Suggested labels:
- `Квиз на денот`
- `Игри за учење`
- `Историја`
- `Географија`
- `Одговори`
- `Испрати`
- `Точен одговор`
- `Неточен одговор`
- `Освои +1 XP`
- `Веќе одговоривте денес`
- `Повторно достапно утре`
- `Достапно од 18:00 до 20:00`
- `Сега не е достапно`
- `Наскоро`

---

## 10. Recommended implementation order

### Phase A
Backend:
- daily quiz tables
- answer endpoint
- correctness check
- XP award integration
- games availability endpoint

### Phase B
Frontend:
- dashboard section/card
- daily quiz page
- learning games page
- locked/open states
- result state

### Phase C
Later:
- actual game implementations on FE
- richer admin content tooling
- configurable windows per school
- streaks / badges / leaderboards only if wanted later

---

## 11. MVP boundaries
For now, do **not** add:
- leaderboard
- public ranking
- detailed game history
- detailed analytics
- grading
- teacher review
- assignment linkage

Keep the feature light and safe.

---

## 12. Final recommendation
Build this as a small evening student engagement feature:
- short daily quiz with one attempt
- +1 XP for correct answer
- simple game catalog visible in a safe time window
- games implemented later
- clean dashboard access and dedicated pages

This keeps the system aligned with the school platform without turning it into a distraction during school hours.
