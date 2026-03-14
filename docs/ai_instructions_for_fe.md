# AI Instructions For FE

Use the existing AI endpoints under `/api/v1`.

## Recommended flow

1. Load the assignment with `GET /api/v1/student/assignments/:id`.
2. Ensure a submission exists for the student.
3. Start or reuse an AI session with `POST /api/v1/ai_sessions`.
4. Send each student question to `POST /api/v1/ai_sessions/:id/messages`.

## Start session payload

Send:

```json
{
  "assignment_id": 123,
  "submission_id": 456,
  "subject_id": 12,
  "session_type": "assignment_help",
  "title": "AI help"
}
```

`submission_id` is strongly recommended because the tutor uses the student progress when building hints.

## Message payload

For each student question, send:

```json
{
  "role": "user",
  "message_type": "question",
  "content": "How do I start?",
  "metadata": {
    "assignment_step_id": 789
  }
}
```

`metadata.assignment_step_id` is strongly recommended.
Without it, the backend falls back to the first unresolved assignment step, which may be less accurate.

## Message response shape

The create-message endpoint now returns both stored messages:

```json
{
  "user_message": {
    "id": 1,
    "role": "user",
    "message_type": "question",
    "content": "How do I start?",
    "sequence_number": 1,
    "metadata": {
      "assignment_step_id": 789
    }
  },
  "assistant_message": {
    "id": 2,
    "role": "assistant",
    "message_type": "hint",
    "content": "Tutor response...",
    "sequence_number": 2,
    "metadata": {
      "assignment_step_id": 789,
      "generated_for_message_id": 1,
      "provider": "mock"
    }
  }
}
```

## Notes

- `assistant_message` is generated only for student question messages.
- `GET /api/v1/ai_sessions/:id` still returns the full ordered message history.
- The backend currently uses a mock tutor provider by default.
- If `assignment_step_id` is missing, the backend tries to infer the active step from the submission state.
