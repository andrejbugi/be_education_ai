# Assignment Model Data

Short FE handoff for the richer assignment payload.

## What changed
Assignments now support:
- assignment-level resources
- richer assignment body blocks through `content_json`
- teacher-only guidance through `teacher_notes`
- richer step fields:
  - `prompt`
  - `resource_url`
  - `example_answer`
  - `content_json`

## Main assignment fields
Returned on assignment details endpoints:
- `id`
- `title`
- `description`
- `teacher_notes`
- `content_json`
- `assignment_type`
- `status`
- `due_at`
- `published_at`
- `max_points`
- `subject`
- `teacher`
- `classroom`
- `resources`
- `steps`
- `submission` for student view

## `resources`
Assignment-level materials for the whole task.

Each resource includes:
- `id`
- `title`
- `resource_type`
- `file_url`
- `external_url`
- `embed_url`
- `description`
- `position`
- `is_required`
- `metadata`

Supported `resource_type` values:
- `pdf`
- `file`
- `image`
- `video`
- `link`
- `text`
- `embed`

## `content_json`
Structured blocks for richer rendering.

Current expected shape:
```json
[
  { "type": "heading", "text": "Наслов" },
  { "type": "paragraph", "text": "Објаснување" },
  { "type": "instruction", "text": "Следи ги чекорите" }
]
```

FE should treat this as ordered content blocks and render by `type`.

## Step fields
Each step now includes:
- `id`
- `position`
- `title`
- `content`
- `prompt`
- `resource_url`
- `example_answer`
- `step_type`
- `required`
- `metadata`
- `content_json`

Example step:
```json
{
  "id": 17,
  "position": 1,
  "title": "Прочитај лекција",
  "content": "Прегледај ја лекцијата и издвој ги клучните поими.",
  "prompt": "Издвои 3 клучни поими од лекцијата.",
  "resource_url": "https://example.com/lesson",
  "example_answer": "Пример: поим 1, поим 2, поим 3",
  "step_type": "reading",
  "required": true,
  "metadata": { "estimated_minutes": 10 },
  "content_json": [
    { "type": "text", "text": "Запиши ги поимите со кратко објаснување." }
  ]
}
```

## Endpoints FE should use
- `GET /api/v1/student/assignments/:id`
- `GET /api/v1/assignments/:id`
- `POST /api/v1/assignments`
- `PATCH /api/v1/assignments/:id`
- `POST /api/v1/assignments/:assignment_id/steps`
- `PATCH /api/v1/assignments/:assignment_id/steps/:id`

## Create/update payload notes
Teacher create/update can now send:
- `teacher_notes`
- `content_json`
- `resources`
- richer `steps` with `prompt`, `resource_url`, `example_answer`, `content_json`

Example top-level create/update fields:
```json
{
  "title": "Македонски јазик - Домашна задача",
  "description": "Општи инструкции",
  "teacher_notes": "Прво прочитај ги материјалите.",
  "content_json": [
    { "type": "heading", "text": "Упатство" },
    { "type": "paragraph", "text": "Решавај по редослед." }
  ],
  "resources": [
    {
      "title": "PDF упатство",
      "resource_type": "pdf",
      "file_url": "https://example.com/task.pdf",
      "description": "Главен материјал",
      "position": 1,
      "is_required": true
    }
  ]
}
```

## FE rendering suggestion
- show `description` as plain summary
- render `content_json` as the main rich assignment body
- render `resources` as downloadable/openable materials
- render each step with:
  - `title`
  - `content`
  - `prompt`
  - optional `resource_url`
  - optional `example_answer`
  - optional step `content_json`
