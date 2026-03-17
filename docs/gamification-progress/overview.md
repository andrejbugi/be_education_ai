# Gamification And Rewards Overview

This doc describes the current backend implementation for the student gamification and rewards system.

Current scope:
- student progress profile per `school + student`
- XP
- levels
- streaks
- milestone badges

Important:
- "rewards" currently means earned badges and progress milestones
- there is no redeemable points store yet
- there is no teacher/admin badge management UI yet
- there is no standalone gamification endpoint yet
- progress is currently exposed through existing student endpoints

## Main backend objects

## 1) `student_progress_profiles`

One persistent profile per student per school.

Purpose:
- store latest computed XP and level state
- store streak counters
- store summary metrics used by the dashboard
- store cached metadata like XP breakdown

Main fields:
- `school_id`
- `student_id`
- `total_xp`
- `current_level`
- `current_streak`
- `longest_streak`
- `completed_assignments_count`
- `graded_assignments_count`
- `badges_count`
- `average_grade`
- `attendance_rate`
- `last_active_on`
- `last_synced_at`
- `metadata`

Uniqueness:
- unique index on `school_id + student_id`

## 2) `student_badges`

Persistent earned badge rows for the student.

Purpose:
- keep a durable history of milestone rewards
- avoid re-awarding the same badge code for the same student and school

Main fields:
- `school_id`
- `student_id`
- `student_progress_profile_id`
- `code`
- `name`
- `description`
- `awarded_at`
- `metadata`

Uniqueness:
- unique index on `school_id + student_id + code`

## Current refresh behavior

Progress is refreshed server-side through `Gamification::RefreshStudentProgress`.

Right now it is called from:
- student dashboard builder
- student performance endpoint

That means:
- FE does not need to calculate XP or levels locally
- FE should treat backend values as the source of truth
- profile rows are updated automatically when these endpoints are loaded

## XP rules

Current XP scoring:

- completed assignment submission: `+30`
- in-progress assignment submission: `+10`
- grade bonus:
  - `95%+` => `+20`
  - `85% to <95%` => `+15`
  - `70% to <85%` => `+10`
  - `60% to <70%` => `+5`
  - `<60%` => `+2`
- attendance:
  - `present` => `+3`
  - `late` => `+2`
  - `excused` => `+1`
  - `absent` => `+0`
- AI sessions:
  - any AI session => `+5` each
  - completed AI session => additional `+5` each

Notes:
- the system derives XP from existing academic/activity records
- XP is recalculated, not incrementally appended in a separate event ledger

## Level rules

Current level step:
- `100 XP` per level

Formula:
- `current_level = floor(total_xp / 100) + 1`

Examples:
- `0 XP` => level `1`
- `99 XP` => level `1`
- `100 XP` => level `2`
- `245 XP` => level `3`

Derived values exposed to FE:
- `current_level_start_xp`
- `next_level_xp`
- `xp_to_next_level`
- `level_progress_percent`

## Streak rules

Streaks are based on active calendar dates collected from:
- submission `started_at`
- submission `submitted_at`
- submission `created_at`
- attendance record `attendance_date`
- AI session `started_at`
- AI session `last_activity_at`

Definitions:
- `longest_streak`: longest continuous run of active days
- `current_streak`: trailing streak ending today or yesterday

Important:
- if the student has not been active today or yesterday, `current_streak` becomes `0`

## Badge rules

Current implemented badges:

## 1) `first_completion`
- Name: `Прва победа`
- Condition: at least 1 completed assignment

## 2) `streak_3`
- Name: `Во серија`
- Condition: longest streak is at least 3 days

## 3) `high_achiever`
- Name: `Одличен резултат`
- Condition: average grade `>= 90` and at least 3 graded assignments

## 4) `attendance_star`
- Name: `Редовен ученик`
- Condition: attendance rate `>= 95` and at least 5 attendance records

## 5) `ai_explorer`
- Name: `AI истражувач`
- Condition: at least 1 AI session

Badge behavior:
- a badge is awarded only once per `school + student + code`
- badges are stored permanently
- badge ordering in payloads is newest first by `awarded_at`, then `id`

## Current API exposure

There is no dedicated `/gamification` endpoint yet.

Current student-facing API surfaces:

## 1) `GET /api/v1/student/dashboard`
Returns:
- compact `progress` object
- up to 3 most recent badges

## 2) `GET /api/v1/student/performance`
Returns:
- full performance snapshot
- nested `progress` object
- up to 5 most recent badges

## Current limitations

Not implemented yet:
- redeemable rewards
- reward catalog
- XP history ledger
- badge expiration
- manual teacher-awarded badges
- school-configurable XP weights
- notifications for newly earned badges
- separate leaderboard endpoints
- teacher/admin progress overview endpoints

## Suggested next expansions later

Good next steps:
- dedicated `GET /api/v1/student/progress`
- teacher view for classroom progress summaries
- notifications when a new badge is earned
- configurable badge definitions in DB
- leaderboard or classroom ranking if product wants it
