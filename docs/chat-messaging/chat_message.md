# Chat / Messages Feature – Backend Instructions

## Goal

Implement a simple messaging feature in the Rails API backend.

Main support:

- message body
- reactions on messages
- file uploads / attachments
- active status / presence
- delivered / read tracking
- timestamps

This is a **BE instruction doc**.

---

# Very short shape

## conversations table
- `school_id`
- `conversation_type` (`direct`, maybe later `group`)
- timestamps

## conversation_participants table
Stores which users are in the thread.

## messages table
- `conversation_id`
- `sender_id`
- `body`
- maybe `attachments`, `read_at`, `deleted_at` later

## Rules

- **teacher-teacher**: allow same-school teachers to start direct conversations
- **teacher-student**: allow only if they share a classroom / assignment / school relationship you approve
- **student-student**: keep disabled unless explicitly enabled later

## API likely
- `GET /api/v1/conversations`
- `POST /api/v1/conversations`
- `GET /api/v1/conversations/:id/messages`
- `POST /api/v1/conversations/:id/messages`

---

# Recommended MVP tables

Use these tables:

- `conversations`
- `conversation_participants`
- `messages`
- `message_reactions`
- `message_attachments`
- `user_presence_statuses`
- `message_deliveries`
- `message_reads`

If you want a smaller first MVP, you can start with:

- `conversations`
- `conversation_participants`
- `messages`

and add the others after.

---

# 1. conversations

Purpose:
Store one chat thread.

Recommended fields:

- `id`
- `school_id`
- `conversation_type`
- `created_by_id`
- `active`
- `last_message_id`
- `last_message_at`
- `created_at`
- `updated_at`

Suggested `conversation_type` values:

- `direct`
- `group`

Notes:
- for now, mostly use `direct`
- `group` can stay prepared for later
- `last_message_at` helps ordering inbox lists

---

# 2. conversation_participants

Purpose:
Store which users belong to a conversation.

Recommended fields:

- `id`
- `conversation_id`
- `user_id`
- `joined_at`
- `left_at`
- `last_read_message_id`
- `last_read_at`
- `active`
- `created_at`
- `updated_at`

Important rule:
- unique row per `conversation_id + user_id`

Notes:
- `last_read_message_id` helps unread counts
- `active` allows soft leave/remove later

---

# 3. messages

Purpose:
Store each message.

Recommended fields:

- `id`
- `conversation_id`
- `sender_id`
- `body`
- `message_type`
- `status`
- `reply_to_message_id`
- `edited_at`
- `deleted_at`
- `created_at`
- `updated_at`

Later / optional:
- `delivered_at`
- `read_at`

Suggested `message_type` values:

- `text`
- `file`
- `image`
- `system`

Suggested `status` values:

- `sent`
- `delivered`
- `read`
- `edited`
- `deleted`

Notes:
- `body` is the main text content
- soft delete should use `deleted_at`
- edits should update `updated_at` and `edited_at`

---

# 4. message_reactions

Purpose:
Store reactions on a message body.

Recommended fields:

- `id`
- `message_id`
- `user_id`
- `reaction`
- `created_at`
- `updated_at`

Examples:
- `like`
- `heart`
- `laugh`
- `check`

Rule:
- one unique reaction per `message_id + user_id + reaction`

---

# 5. message_attachments

Purpose:
Store uploaded files linked to a message.

Recommended fields:

- `id`
- `message_id`
- `attachment_type`
- `file_name`
- `content_type`
- `file_size`
- `storage_key`
- `file_url`
- `created_at`
- `updated_at`

Suggested `attachment_type` values:

- `file`
- `image`
- `pdf`

Notes:
- use Active Storage or S3-compatible storage
- store metadata in SQL, not file binary

---

# 6. user_presence_statuses

Purpose:
Track active status.

Recommended fields:

- `id`
- `user_id`
- `status`
- `last_seen_at`
- `created_at`
- `updated_at`

Suggested `status` values:

- `online`
- `offline`
- `away`
- `busy`

Rule:
- one row per user

---

# 7. message_deliveries

Purpose:
Track delivered state per user.

Recommended fields:

- `id`
- `message_id`
- `user_id`
- `delivered_at`
- `created_at`
- `updated_at`

Rule:
- unique per `message_id + user_id`

---

# 8. message_reads

Purpose:
Track read state per user.

Recommended fields:

- `id`
- `message_id`
- `user_id`
- `read_at`
- `created_at`
- `updated_at`

Rule:
- unique per `message_id + user_id`

---

# Relationship / permission rules

## teacher-teacher
Allow direct conversations if:
- both users are teachers
- both belong to the same school

## teacher-student
Allow only if backend-approved relationship exists, for example:
- same school and same classroom
- teacher teaches student in a subject
- teacher assigned the student an assignment
- another explicit approved school relation

This should be validated in backend service logic.

## student-student
Disable for now.

Do not allow student-student direct chat unless you explicitly enable it later.

---

# Recommended backend checks

When creating a conversation:

1. current user must belong to the selected `school_id`
2. target user must belong to the same school
3. validate allowed role combination
4. prevent duplicate direct conversation between same two users in same school when possible

For direct conversation uniqueness, strongly consider:
- only one active direct conversation for same two users per school

---

# Suggested associations

## Conversation
- `belongs_to :school`
- `belongs_to :created_by, class_name: 'User'`
- `has_many :conversation_participants`
- `has_many :participants, through: :conversation_participants, source: :user`
- `has_many :messages`

## ConversationParticipant
- `belongs_to :conversation`
- `belongs_to :user`

## Message
- `belongs_to :conversation`
- `belongs_to :sender, class_name: 'User'`
- `belongs_to :reply_to_message, class_name: 'Message', optional: true`
- `has_many :message_reactions`
- `has_many :message_attachments`

## MessageReaction
- `belongs_to :message`
- `belongs_to :user`

## MessageAttachment
- `belongs_to :message`

## UserPresenceStatus
- `belongs_to :user`

## MessageDelivery
- `belongs_to :message`
- `belongs_to :user`

## MessageRead
- `belongs_to :message`
- `belongs_to :user`

---

# Core backend behavior

## Create conversation
- validate relationship rules
- create `conversation`
- create `conversation_participants`

## List conversations
- return only conversations where current user is a participant
- order by `last_message_at desc`

## List messages
- return messages for a conversation only if current user is a participant
- exclude or mask soft-deleted messages depending on product decision

## Send message
- validate current user is participant
- create `message`
- optionally attach uploaded files
- update:
  - `conversations.last_message_id`
  - `conversations.last_message_at`

## Add reaction
- create or remove `message_reaction`

## Mark delivered
- create/update `message_deliveries`

## Mark read
- create/update `message_reads`
- update participant:
  - `last_read_message_id`
  - `last_read_at`

## Update presence
- update `user_presence_statuses.status`
- refresh `last_seen_at`

---

# Recommended indexes

## conversations
- index on `school_id`
- index on `conversation_type`
- index on `last_message_at`

## conversation_participants
- unique index on `conversation_id, user_id`
- index on `user_id`

## messages
- index on `conversation_id, created_at`
- index on `sender_id`
- index on `reply_to_message_id`
- index on `deleted_at`

## message_reactions
- unique index on `message_id, user_id, reaction`
- index on `message_id`

## message_attachments
- index on `message_id`

## user_presence_statuses
- unique index on `user_id`

## message_deliveries
- unique index on `message_id, user_id`

## message_reads
- unique index on `message_id, user_id`

---

# Recommended API

## Conversations
- `GET /api/v1/conversations`
- `POST /api/v1/conversations`

## Messages
- `GET /api/v1/conversations/:id/messages`
- `POST /api/v1/conversations/:id/messages`

Good later additions:
- `PATCH /api/v1/messages/:id`
- `DELETE /api/v1/messages/:id`
- `POST /api/v1/messages/:id/reactions`
- `DELETE /api/v1/messages/:id/reactions`
- `POST /api/v1/messages/:id/read`
- `POST /api/v1/messages/:id/deliver`
- `POST /api/v1/presence/update`

---

# Example creation flow

## Create direct conversation
Payload example:

```json
{
  "school_id": 1,
  "conversation_type": "direct",
  "participant_ids": [12]
}

---

Backend:

current user is inferred from JWT
backend validates current user ↔ target user relationship
backend creates conversation + both participants

Send message
Payload example:

{
  "body": "Здраво, ја прегледав задачата.",
  "message_type": "text"
}

Optional multipart later:
body
files[]

Final recommendation

For this project, the best practical backend structure is:

conversations
conversation_participants
messages
message_reactions
message_attachments
user_presence_statuses
message_deliveries
message_reads

This gives you:
message body
reactions on messages
file uploads
active status
timestamps
delivered/read tracking
safe future expansion

For the very first MVP, you can start with:
conversations
conversation_participants
messages

and then add:
reactions
attachmets
read/delivered tracking
presence