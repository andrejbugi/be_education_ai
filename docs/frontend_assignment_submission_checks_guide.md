# Frontend Guide: Assignments, Submissions, and Answer Checking

Base path: `/api/v1`

This guide explains how FE should use assignment steps, answer checking, and submissions.

## 1. Core idea
- Assignments contain ordered `steps`
- each step can be review-based or auto-checked
- students submit answers per step
- the backend stores step answer status as `answered`, `correct`, or `incorrect`

Use `evaluation_mode` on each step to decide how FE should present the task.

Supported values:
- `manual`
- `normalized_text`
- `numeric`
- `regex`

## 2. What teachers/admins can send
Teacher/admin create and update flows can define checking rules on steps.

### On assignment create
`POST /assignments`

Example:
```json
{
  "classroom_id": 4,
  "subject_id": 3,
  "title": "Равенки",
  "description": "Реши ги чекорите",
  "steps": [
    {
      "position": 1,
      "title": "Реши равенка",
      "content": "2x + 3 = 13",
      "evaluation_mode": "normalized_text",
      "answer_keys": [
        { "value": "x=5" }
      ]
    },
    {
      "position": 2,
      "title": "Објасни ја постапката",
      "content": "Опиши ги чекорите",
      "evaluation_mode": "manual"
    }
  ]
}
```

### On step create/update
- `POST /assignments/:assignment_id/steps`
- `PATCH /assignments/:assignment_id/steps/:id`

The same `evaluation_mode` and `answer_keys` shape applies there.

## 3. Teacher/admin assignment responses
Teacher/admin assignment detail responses include answer keys so the editing UI can load them back.

Endpoint:
- `GET /assignments/:id`

Step example:
```json
{
  "id": 21,
  "position": 1,
  "title": "Реши равенка",
  "content": "2x + 3 = 13",
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
```

## 4. Student assignment responses
Student assignment detail responses do not include `answer_keys`.
Student assignment detail responses do include the student's own `submission.step_answers` when a submission already exists.

Endpoint:
- `GET /student/assignments/:id`

Student-safe step example:
```json
{
  "id": 21,
  "position": 1,
  "title": "Реши равенка",
  "content": "2x + 3 = 13",
  "evaluation_mode": "normalized_text"
}
```

This is intentional so FE never exposes the correct answers to students.

Student assignment detail excerpt:
```json
{
  "submission": {
    "id": 44,
    "status": "in_progress",
    "step_answers": [
      {
        "assignment_step_id": 21,
        "answer_text": "x = 5",
        "status": "correct"
      }
    ]
  }
}
```

## 5. Submission save flow
1. `POST /assignments/:assignment_id/submissions`
2. `PATCH /submissions/:id` with one or more `step_answers`
3. read returned `step_answers[*].status`
4. on reopen, use `GET /student/assignments/:id` and read `submission.step_answers`
5. `POST /submissions/:id/submit` when done

Example save payload:
```json
{
  "step_answers": [
    {
      "assignment_step_id": 21,
      "answer_text": "x = 5"
    }
  ]
}
```

Example response excerpt:
```json
{
  "id": 44,
  "status": "in_progress",
  "step_answers": [
    {
      "assignment_step_id": 21,
      "answer_text": "x = 5",
      "status": "correct"
    }
  ]
}
```

## 6. How checking works
### `manual`
- backend leaves the answer as `answered`
- teacher/admin review is still needed

### `normalized_text`
- good for short exact answers with flexible spacing
- backend ignores spacing around operators
- `x = 5`, `x= 5`, `x =5`, and `x=5` all match the same key

### `numeric`
- good for plain numeric answers
- optional `tolerance` allows near matches
- example: expected `3.14`, tolerance `0.01`

### `regex`
- good for formatted text patterns
- answer key `value` is treated as a regex pattern

## 7. FE recommendations
- show an “Auto-checked” hint when `evaluation_mode` is not `manual`
- show a “Needs review” hint when `evaluation_mode` is `manual`
- after every save, refresh UI from returned submission payload instead of assuming the result locally
- use returned step answer `status` to show green/red/neutral states
- do not expect `answer_keys` in student assignment endpoints
- do expect `answer_keys` in teacher/admin assignment editing views

## 8. Files and checks together
Assignments can use both:
- file resources at assignment level
- checked answers at step level

That means FE can build mixed assignments such as:
- uploaded worksheet + manual essay step
- uploaded PDF + auto-checked short-answer step
- rich instructions + numeric answer step
