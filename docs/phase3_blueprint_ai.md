# AI Backend Implementation – Education Platform

## Goal

Implement a controlled AI system inside the Rails backend.

AI will support one use case for now:

1. **Student AI assistance during assignment solving**

The AI is **not a chatbot**.  
It acts as a **structured learning assistant**.

The system must:

- guide students step-by-step
- never give full answers immediately
- store all interactions
- be auditable later if needed

AI interaction history is stored using:

- `ai_sessions`
- `ai_messages`

---

# 1 AI Architecture

## Core components

```

Student Workspace
↓
AI Session
↓
AI Service Layer
↓
LLM Provider (OpenAI later)

```

Main models:

```

AiSession
AiMessage

```

---

# 2 AI Session Purpose

Each student interaction with AI happens inside a **session**.

Example:

```

Student opens assignment
→ opens AI help
→ session starts
→ messages stored

```

Sessions allow:

- resume later
- track learning behavior
- audit AI responses later if needed

Important fields:

```

user_id
assignment_id
submission_id
subject_id
session_type
status
context_data

```

Session types:

```

assignment_help
practice
revision
freeform

```

---

# 3 AI Message Model

Each AI interaction is saved as a message.

Structure:

```

ai_messages

* ai_session_id
* role
* message_type
* content
* sequence_number
* metadata

```

Roles:

```

user
assistant
system

```

Message types:

```

question
hint
feedback
step
summary
error

```

---

# 4 Student AI Workflow

## 4.1 Student opens assignment workspace

Frontend loads:

```

GET /api/v1/student/assignments/:id

```

Assignment contains:

```

steps
prompt
evaluation_mode
resources

```

Assignment step evaluation modes:

```

manual
normalized_text
numeric
regex

```

---

## 4.2 Student opens AI help

Frontend request:

```

POST /api/v1/ai_sessions

```

Payload:

```

{
assignment_id,
submission_id,
subject_id,
session_type: "assignment_help"
}

```

Backend service:

```

AiSessions::Start

```

Creates session:

```

status = active
started_at = now

```

---

## 4.3 Student sends question

Frontend:

```

POST /api/v1/ai_sessions/:id/messages

```

Payload:

```

{
role: "user",
message_type: "question",
content: "How do I start solving this equation?",
metadata: {
  assignment_step_id: 1
}
}

```

Backend:

```

AiMessages::Append

```

Stores message.

---

## 4.4 AI generates response

Backend service:

```

AiTutor::GenerateResponse

```

Steps:

1. load assignment
2. load assignment step if `metadata.assignment_step_id` is present
3. load submission state
4. build safe prompt
5. call AI provider (later)

For now use:

```

mock_response_generator

```

Example response:

```

"Ајде прво да ги поедноставиме страните на равенката.
Што треба да направиме со +5?"

```

Stored as:

```

role: assistant
message_type: hint

```

---

# 5 AI Guidance Rules

AI must follow strict rules.

## Allowed

AI can:

- explain concepts
- suggest strategies
- give hints
- ask guiding questions
- explain mistakes

Example:

```

Think about isolating x.
What operation removes +5?

```

## Not allowed

AI must NOT:

- reveal final answers immediately
- solve assignments automatically
- complete homework for the student

Bad example:

```

x = 5

```

Good example:

```

What happens if you subtract 5 from both sides?

```

---

# 6 AI Prompt Structure

Example system prompt:

```

You are a patient school tutor helping students learn step-by-step.

Rules:

* never give full solution immediately
* guide the student with hints
* encourage thinking
* respond in Macedonian

Assignment:
Solve the equation:
3x + 5 = 20

Student question:
How do I start?

Student progress:
Step 1 not solved yet

```

---

# 7 Using Submission Data

AI should use:

```

submissions
submission_step_answers
message metadata.assignment_step_id

```

To understand student progress.

Example:

```

Step 1 expected: 3x = 15
Student answer: 3x = 20

```

AI response:

```

Almost correct.
Remember to subtract 5 from both sides.

```

This integrates AI with the submission checking system.

---

# 8 AI Services Structure (Rails)

Suggested folder:

```

app/services/ai/

```

Services:

```

AiSessions::Start
AiSessions::Complete

AiMessages::Append

AiTutor::GenerateResponse
AiTutor::BuildPrompt

```

---

# 9 AI Provider Interface

Create provider abstraction.

Structure:

```

AiProviders::BaseClient
AiProviders::OpenAIClient
AiProviders::MockClient

```

For now use:

```

MockClient

```

Later replace with OpenAI.

---

# 10 Future OpenAI Configuration

Use cheapest model:

```

gpt-4o-mini

```

Future endpoint:

```

POST [https://api.openai.com/v1/chat/completions](https://api.openai.com/v1/chat/completions)

```

Do **not implement API keys yet**.

Only prepare the client structure.

---

# 11 Safety Controls

Important because students use the system.

Rules:

AI must:

- stay educational
- avoid unsafe advice
- avoid inappropriate responses
- stay within subject context

All conversations must be stored:

```

ai_sessions
ai_messages

```

Admin may review AI sessions later if needed.

---

# 12 Dashboard Integration

Student dashboard should show:

```

Resume AI session

```

Example:

```

Continue solving:
Math assignment – Linear Equations

```

Endpoint:

```

GET /api/v1/ai_sessions

```

---

# 13 Logging and Analytics

Future metrics from AI sessions:

```

average hints per assignment
retry count
completion rate
learning difficulty indicators

```

All metrics derived from stored AI messages.

---

# 14 Implementation Order

Recommended order:

1. AI session endpoints
2. AI message persistence
3. Mock tutor response generator
4. Assignment-aware AI hints
5. Replace mock client with OpenAI
