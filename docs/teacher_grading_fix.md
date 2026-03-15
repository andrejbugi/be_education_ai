# Teacher Grading Fix – Backend/Frontend Contract for Viewing Student Answers

## Goal
Fix the current grading blocker where teachers cannot reliably view a student’s saved `step_answers` for an assignment during review.

This issue exists because the current teacher flow falls back to a **student-only endpoint**, while the documented API only guarantees saved answers for the student reopen flow, not for teacher review. The current docs clearly separate:
- `GET /student/assignments/:id` for the student’s own assignment view
- `GET /assignments/:id` for teacher/admin assignment details and answer keys
- teacher area endpoints like `GET /teacher/students/:id`, but with no documented submission-detail contract for grading :contentReference[oaicite:0]{index=0} :contentReference[oaicite:1]{index=1} :contentReference[oaicite:2]{index=2}

---

## Problem Summary

## What is wrong now
The teacher grading screen is currently using a student endpoint as fallback:
- teacher UI needs the reviewed student’s saved answers
- but `GET /student/assignments/:id` is documented as the **student-safe** reopen endpoint
- it is not the correct teacher review source

This is misaligned with the docs and creates unstable behavior:
- student can see their saved answers
- teacher may still see “no answer”
- teacher review depends on an unsupported contract

---

## Why this happens
The backend docs currently support:
- student saved answers via `GET /student/assignments/:id`
- teacher/admin assignment editing/details via `GET /assignments/:id`

But the docs do **not** currently define a teacher-safe endpoint that returns:
- a selected student submission
- that submission’s `step_answers`
- enough detail for grading/review

This gap is visible in the current quick reference and assignment docs, where teacher endpoints stop at `GET /teacher/students/:id`, and no teacher submission-detail endpoint is documented :contentReference[oaicite:3]{index=3}.

---

## Current documented behavior

### Student-side assignment detail
`GET /student/assignments/:id`
- returns student-safe assignment data
- includes the student’s submission context
- does **not** expose teacher-only `answer_keys` :contentReference[oaicite:4]{index=4} :contentReference[oaicite:5]{index=5}

### Teacher/admin assignment detail
`GET /assignments/:id`
- returns assignment structure
- includes `answer_keys`
- useful for editing/review setup
- but not documented as the source for a specific student’s saved `step_answers` :contentReference[oaicite:6]{index=6} :contentReference[oaicite:7]{index=7}

### Teacher area
`GET /teacher/students/:id`
- exists in the API reference
- but no documented guarantee that it includes:
  - submissions
  - recent_submissions
  - nested `step_answers`
  - selected-assignment review payload :contentReference[oaicite:8]{index=8}

---

## Recommended Fix
Do **not** keep relying on the student endpoint for teacher grading.

The clean fix is to define and implement a **teacher-safe submission detail endpoint**.

## Recommended official endpoint
### `GET /api/v1/teacher/submissions/:id`

Status: implemented.

This should become the official source for teacher grading/review.

Why this is the best option:
- it is explicit
- it matches the grading domain
- it avoids overloading student endpoints
- it avoids bloating `GET /teacher/students/:id`
- it is easy for FE to call from a selected submission row
- it is consistent with `POST /submissions/:submission_id/grades` already being the grading action endpoint :contentReference[oaicite:9]{index=9} :contentReference[oaicite:10]{index=10}

---

## Alternative acceptable option
If needed, this can also work:

### `GET /api/v1/teacher/assignments/:assignment_id/submissions/:student_id`

This is also valid, but it is a bit more specific and less reusable than a direct teacher submission detail endpoint.

---

## Not recommended as the main solution
### Extending `GET /teacher/students/:id`
This could work, but it is weaker because:
- the endpoint becomes too broad
- teacher student detail can become heavy
- submission review becomes less explicit
- FE has to search for the right submission inside larger student payloads

Use this only if the backend already heavily depends on that structure.

---

## Final API recommendation

## New endpoint
### `GET /api/v1/teacher/submissions/:id`

### Purpose
Return a teacher-safe, school-scoped, submission-detail payload for grading.

### FE usage
Use this endpoint when the teacher selects one submission from:
- the review queue
- a student detail page
- an assignment submissions list

FE should treat this as the main grading source of truth because it returns everything needed in one response:
- assignment metadata
- assignment steps
- teacher-only `answer_keys`
- the reviewed student's `step_answers`
- the latest grade, if already graded

### Access rules
Only allow if:
- current user has `teacher` or `admin` role
- current user belongs to the current school context
- submission belongs to a student in the same school context
- teacher is allowed to review that assignment/classroom/subject

This must stay aligned with the existing school-scoped auth model using JWT plus `X-School-Id` :contentReference[oaicite:11]{index=11} :contentReference[oaicite:12]{index=12}.

---

## Response shape recommendation

```json
{
  "id": 44,
  "status": "submitted",
  "submitted_at": "2026-03-15T10:30:00Z",
  "reviewed_at": null,
  "student": {
    "id": 45,
    "full_name": "Марија Стојанова"
  },
  "assignment": {
    "id": 11,
    "title": "Равенки",
    "assignment_type": "homework",
    "due_at": "2026-03-16T20:00:00Z",
    "subject": {
      "id": 4,
      "name": "Математика"
    },
    "classroom": {
      "id": 10,
      "name": "7-A"
    },
    "teacher": {
      "id": 15,
      "full_name": "Ана Трајковска"
    }
  },
  "steps": [
    {
      "id": 21,
      "position": 1,
      "title": "Реши равенка",
      "content": "2x + 3 = 13",
      "prompt": "Изолирај x",
      "example_answer": null,
      "evaluation_mode": "normalized_text",
      "answer_keys": [
        {
          "id": 7,
          "value": "x=5",
          "position": 1,
          "tolerance": null,
          "case_sensitive": false,
          "metadata": {}
        }
      ]
    }
  ],
  "step_answers": [
    {
      "id": 81,
      "assignment_step_id": 21,
      "answer_text": "x = 5",
      "status": "correct",
      "created_at": "2026-03-15T10:15:00Z",
      "updated_at": "2026-03-15T10:16:00Z"
    }
  ],
  "grade": {
    "id": 9,
    "score": "95.0",
    "feedback": "Одлично",
    "graded_at": null
  }
}
