# Assignment Model Data

Short FE handoff for the richer assignment payload.

## What changed
Assignments now support:
- reusable subject topics through `subject_topic_id`
- assignment-level resources
- uploaded assignment files through Active Storage
- richer assignment body blocks through `content_json`
- teacher-only guidance through `teacher_notes`
- richer step fields:
  - `prompt`
  - `resource_url`
  - `example_answer`
  - `content_json`
  - `evaluation_mode`
  - teacher-only `answer_keys`

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
- `subject_topic_id`
- `subject_topic`
- `teacher`
- `classroom`
- `resources`
- `steps`
- `submission` for student view, including saved `step_answers` when a submission exists

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
- `uploaded_file`

`file_url` now works in two ways:
- for uploaded files, it is the backend-generated download URL
- for legacy/external file resources, it remains the stored URL

`uploaded_file` is present only when a real file was uploaded and includes:
- `filename`
- `byte_size`
- `content_type`
- `url`

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
- `evaluation_mode`

Teacher/admin assignment detail responses also include:
- `answer_keys`

Student assignment detail responses do not include `answer_keys`.
Student assignment detail responses now include `submission.step_answers` so FE can repopulate previously saved answers.

Assignments may include an optional reusable topic:
- `subject_topic_id`
- `subject_topic: { id, name }`

Supported `evaluation_mode` values:
- `manual`
- `normalized_text`
- `numeric`
- `regex`

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
  "evaluation_mode": "manual",
  "content_json": [
    { "type": "text", "text": "Запиши ги поимите со кратко објаснување." }
  ]
}
```

Teacher step example with answer keys:
```json
{
  "id": 18,
  "position": 2,
  "title": "Реши равенка",
  "content": "Изолирај x",
  "evaluation_mode": "normalized_text",
  "answer_keys": [
    {
      "id": 3,
      "value": "x=5",
      "position": 1,
      "tolerance": null,
      "case_sensitive": false,
      "metadata": {}
    }
  ]
}
```

Student submission excerpt inside `GET /api/v1/student/assignments/:id`:
```json
{
  "submission": {
    "id": 44,
    "status": "in_progress",
    "started_at": "2026-03-15T01:00:00.000Z",
    "submitted_at": null,
    "total_score": null,
    "late": false,
    "step_answers": [
      {
        "id": 101,
        "assignment_step_id": 18,
        "answer_text": "x = 5",
        "answer_data": {},
        "status": "correct",
        "answered_at": "2026-03-15T01:05:00.000Z"
      }
    ]
  }
}
```

## Endpoints FE should use
- `GET /api/v1/teacher/subjects`
- `POST /api/v1/teacher/subjects/:subject_id/topics`
- `GET /api/v1/student/assignments/:id`
- `GET /api/v1/assignments/:id`
- `POST /api/v1/assignments`
- `PATCH /api/v1/assignments/:id`
- `POST /api/v1/assignments/:assignment_id/steps`
- `PATCH /api/v1/assignments/:assignment_id/steps/:id`
- `POST /api/v1/assignments/:assignment_id/resources`
- `PATCH /api/v1/assignments/:assignment_id/resources/:id`
- `DELETE /api/v1/assignments/:assignment_id/resources/:id`

## Create/update payload notes
Teacher create/update can now send:
- `subject_topic_id`
- `teacher_notes`
- `content_json`
- `resources`
- richer `steps` with `prompt`, `resource_url`, `example_answer`, `content_json`
- per-step `evaluation_mode`
- per-step `answer_keys`

For actual file uploads, use multipart form data against `POST /api/v1/assignments/:assignment_id/resources` with:
- `title`
- `resource_type`
- optional `description`
- optional `position`
- optional `is_required`
- `file`

Development storage uses local Active Storage disk storage.

Example top-level create/update fields:
```json
{
  "classroom_id": 4,
  "subject_id": 3,
  "subject_topic_id": 12,
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
  ],
  "steps": [
    {
      "title": "Реши равенка",
      "content": "2x + 3 = 13",
      "evaluation_mode": "normalized_text",
      "answer_keys": [
        { "value": "x=5" }
      ]
    }
  ]
}
```

Example reusable subject topics response from `GET /api/v1/teacher/subjects`:
```json
[
  {
    "id": 3,
    "name": "Математика",
    "code": "MAT-7",
    "school_id": 1,
    "school": {
      "id": 1,
      "name": "ОУ Браќа Миладиновци"
    },
    "topics": [
      {
        "id": 12,
        "name": "Дробки"
      }
    ]
  }
]
```

Example multipart upload response:
```json
{
  "id": 9,
  "title": "PDF упатство",
  "resource_type": "pdf",
  "file_url": "http://localhost:3000/rails/active_storage/blobs/redirect/...",
  "external_url": null,
  "embed_url": null,
  "description": "Главен материјал",
  "position": 1,
  "is_required": true,
  "metadata": {},
  "uploaded_file": {
    "filename": "task.pdf",
    "byte_size": 48213,
    "content_type": "application/pdf",
    "url": "http://localhost:3000/rails/active_storage/blobs/redirect/..."
  }
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
  - optional `evaluation_mode` badge or helper text for teacher/admin UI

## Submission checking notes
- `manual` steps stay in `answered` until reviewed by a teacher or admin
- `normalized_text`, `numeric`, and `regex` steps are auto-checked when students save answers
- `normalized_text` ignores spacing around operators, so values like `x = 5` and `x=5` match
- submission step answer statuses can now naturally move between `answered`, `correct`, and `incorrect`
