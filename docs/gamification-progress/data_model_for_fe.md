# Gamification And Rewards Data Model For FE

Base path: `/api/v1`

This doc describes the current frontend-facing payloads for the gamification and rewards system.

Important:
- there is no standalone gamification endpoint yet
- FE receives progress data through existing student endpoints
- rewards currently include badges plus server-tracked XP events such as `daily_quiz`
- there is no redeemable store, inventory, or claim action yet
- backend values should be treated as the source of truth

## Endpoints that include progress

## 1) `GET /api/v1/student/dashboard`

Headers:
- `Authorization: Bearer <jwt>`
- `X-School-Id: <selected_school_id>`

Includes a compact `progress` object for dashboard cards.

Example:

```json
{
  "student": {
    "id": 7,
    "full_name": "Марија Стојанова"
  },
  "next_task": null,
  "homework": [],
  "deadlines": [],
  "announcements": [],
  "performance_snapshot": {
    "average_grade": "94.50",
    "attendance_rate": "100.0",
    "engagement_score": "39.0",
    "completed_assignments_count": 3
  },
  "progress": {
    "total_xp": 155,
    "current_level": 2,
    "current_streak": 5,
    "longest_streak": 5,
    "current_level_start_xp": 100,
    "next_level_xp": 200,
    "xp_to_next_level": 45,
    "level_progress_percent": 55.0,
    "completed_assignments_count": 3,
    "graded_assignments_count": 3,
    "badges_count": 5,
    "average_grade": "96.0",
    "attendance_rate": "100.0",
    "last_active_on": "2026-03-17",
    "last_synced_at": "2026-03-17T10:20:30.000Z",
    "breakdown": {
      "completed_assignments": 90,
      "in_progress_assignments": 0,
      "grade_bonus": 60,
      "attendance": 15,
      "ai_learning": 10,
      "rewards": 1,
      "daily_quiz": 1
    },
    "badges": [
      {
        "id": 12,
        "code": "ai_explorer",
        "name": "AI истражувач",
        "description": "Започната е AI сесија за учење.",
        "awarded_at": "2026-03-17T10:20:30.000Z",
        "metadata": {
          "total_xp": 155,
          "current_level": 2
        }
      }
    ]
  },
  "ai_resume": null,
  "notifications_unread": 0,
  "recent_activity": []
}
```

Notes:
- dashboard currently returns up to 3 recent badges
- if no school is resolved, `progress` may be `null`

## 2) `GET /api/v1/student/performance`

Headers:
- `Authorization: Bearer <jwt>`
- `X-School-Id: <selected_school_id>`

Includes the normal performance snapshot plus nested `progress`.

Example:

```json
{
  "id": 4,
  "period_type": "monthly",
  "period_start": "2026-03-01",
  "period_end": "2026-03-31",
  "average_grade": "94.50",
  "completed_assignments_count": 3,
  "in_progress_assignments_count": 1,
  "overdue_assignments_count": 0,
  "missed_assignments_count": 0,
  "attendance_rate": "100.0",
  "engagement_score": "39.0",
  "snapshot_data": {
    "grades_count": 3,
    "attendance_breakdown": {
      "present": 5
    },
    "assignment_ids": [10, 11, 12]
  },
  "generated_at": "2026-03-17T10:20:30.000Z",
  "progress": {
    "total_xp": 155,
    "current_level": 2,
    "current_streak": 5,
    "longest_streak": 5,
    "current_level_start_xp": 100,
    "next_level_xp": 200,
    "xp_to_next_level": 45,
    "level_progress_percent": 55.0,
    "completed_assignments_count": 3,
    "graded_assignments_count": 3,
    "badges_count": 5,
    "average_grade": "96.0",
    "attendance_rate": "100.0",
    "last_active_on": "2026-03-17",
    "last_synced_at": "2026-03-17T10:20:30.000Z",
    "breakdown": {
      "completed_assignments": 90,
      "in_progress_assignments": 0,
      "grade_bonus": 60,
      "attendance": 15,
      "ai_learning": 10,
      "rewards": 1,
      "daily_quiz": 1
    },
    "badges": [
      {
        "id": 12,
        "code": "ai_explorer",
        "name": "AI истражувач",
        "description": "Започната е AI сесија за учење.",
        "awarded_at": "2026-03-17T10:20:30.000Z",
        "metadata": {
          "total_xp": 155,
          "current_level": 2
        }
      },
      {
        "id": 11,
        "code": "attendance_star",
        "name": "Редовен ученик",
        "description": "Посетеност 95% со најмалку 5 евиденции.",
        "awarded_at": "2026-03-17T10:20:30.000Z",
        "metadata": {
          "total_xp": 155,
          "current_level": 2
        }
      }
    ]
  }
}
```

Notes:
- performance currently returns up to 5 recent badges
- `progress` is recalculated server-side when this endpoint is loaded

## Core progress object

The same progress shape is reused in both endpoints.

Fields:
- `total_xp`
- `current_level`
- `current_streak`
- `longest_streak`
- `current_level_start_xp`
- `next_level_xp`
- `xp_to_next_level`
- `level_progress_percent`
- `completed_assignments_count`
- `graded_assignments_count`
- `badges_count`
- `average_grade`
- `attendance_rate`
- `last_active_on`
- `last_synced_at`
- `breakdown`
- `badges`

## XP breakdown object

Nested under `progress.breakdown`.

Fields:
- `completed_assignments`
- `in_progress_assignments`
- `grade_bonus`
- `attendance`
- `ai_learning`
- `rewards`
- `daily_quiz`

Important:
- these values are informational totals
- FE should not try to recompute them locally
- `rewards` is the total XP coming from reward events
- `daily_quiz` is the currently tracked reward-event subtype exposed in v1

## Badge object

Nested under `progress.badges`.

Fields:
- `id`
- `code`
- `name`
- `description`
- `awarded_at`
- `metadata`

Current badge codes:
- `first_completion`
- `streak_3`
- `high_achiever`
- `attendance_star`
- `ai_explorer`

Badge metadata currently includes:
- `total_xp`
- `current_level`

## Suggested TypeScript types

```ts
export type StudentBadgeCode =
  | "first_completion"
  | "streak_3"
  | "high_achiever"
  | "attendance_star"
  | "ai_explorer";

export type StudentBadge = {
  id: number;
  code: StudentBadgeCode | string;
  name: string;
  description: string | null;
  awarded_at: string;
  metadata: {
    total_xp?: number;
    current_level?: number;
    [key: string]: unknown;
  };
};

export type StudentProgressBreakdown = {
  completed_assignments: number;
  in_progress_assignments: number;
  grade_bonus: number;
  attendance: number;
  ai_learning: number;
};

export type StudentProgress = {
  total_xp: number;
  current_level: number;
  current_streak: number;
  longest_streak: number;
  current_level_start_xp: number;
  next_level_xp: number;
  xp_to_next_level: number;
  level_progress_percent: number;
  completed_assignments_count: number;
  graded_assignments_count: number;
  badges_count: number;
  average_grade: string | null;
  attendance_rate: string | null;
  last_active_on: string | null;
  last_synced_at: string | null;
  breakdown: StudentProgressBreakdown;
  badges: StudentBadge[];
};
```

## FE handling notes

- use `total_xp`, `current_level`, and `xp_to_next_level` for the main progress card
- use `level_progress_percent` for progress bars
- use `current_streak` for the active streak badge or chip
- use `badges_count` for compact counters
- render `badges` as newest first
- do not assume all badges are returned in the dashboard response
- keep badge rendering resilient to unknown future badge codes

## Current limitations

Not available yet:
- claim reward action
- redeem points action
- progress history chart endpoint
- per-badge detail endpoint
- leaderboard endpoint
- teacher-facing progress endpoint

For now, FE should treat this as:
- read-only student progress state
- badge/reward display only
