# Chat Messaging Data Model For FE

Base path: `/api/v1`

This doc describes the current backend payloads for the chat messaging feature so frontend can model state correctly.

Important:
- all protected chat endpoints require `Authorization: Bearer <jwt>`
- school-scoped requests should include `X-School-Id: <selected_school_id>`
- direct conversations are implemented now
- group conversations are not enabled yet
- student-student direct chat is blocked

## Core entities

## 1) Conversation

Returned by:
- `GET /api/v1/conversations`
- `POST /api/v1/conversations`

Shape:

```json
{
  "id": 11,
  "school_id": 3,
  "conversation_type": "direct",
  "active": true,
  "last_message_at": "2026-03-15T19:55:12.000Z",
  "created_at": "2026-03-15T19:40:00.000Z",
  "updated_at": "2026-03-15T19:55:12.000Z",
  "participants": [
    {
      "id": 7,
      "email": "teacher.one@example.com",
      "first_name": "Ana",
      "last_name": "Teacher",
      "full_name": "Ana Teacher",
      "roles": ["teacher"],
      "joined_at": "2026-03-15T19:40:00.000Z",
      "last_read_message_id": 99,
      "last_read_at": "2026-03-15T19:56:10.000Z",
      "presence_status": "online",
      "last_seen_at": "2026-03-15T19:56:10.000Z"
    }
  ],
  "current_user_state": {
    "joined_at": "2026-03-15T19:40:00.000Z",
    "last_read_message_id": 99,
    "last_read_at": "2026-03-15T19:56:10.000Z",
    "active": true
  },
  "unread_count": 2,
  "last_message": {
    "id": 99,
    "conversation_id": 11,
    "sender_id": 8,
    "sender_name": "Boris Teacher",
    "body": "Please review this file.",
    "message_type": "file",
    "status": "delivered",
    "reply_to_message_id": null,
    "edited_at": null,
    "deleted_at": null,
    "created_at": "2026-03-15T19:55:12.000Z",
    "updated_at": "2026-03-15T19:55:12.000Z",
    "attachments": [],
    "reactions": [],
    "delivered_user_ids": [8],
    "read_user_ids": [8]
  }
}
```

Notes:
- `participants` always includes all active users in the conversation
- `current_user_state.last_read_message_id` is the easiest backend-provided marker for unread calculations
- `unread_count` is already computed by backend for the current user
- `last_message` may be `null` for a newly created empty conversation

## 2) Participant inside conversation

This is not a standalone endpoint right now. It is nested inside `conversation.participants`.

Fields:
- `id`
- `email`
- `first_name`
- `last_name`
- `full_name`
- `roles`
- `joined_at`
- `last_read_message_id`
- `last_read_at`
- `presence_status`
- `last_seen_at`

Presence status values:
- `online`
- `offline`
- `away`
- `busy`

## 3) Message

Returned by:
- `GET /api/v1/conversations/:conversation_id/messages`
- `POST /api/v1/conversations/:conversation_id/messages`
- `POST /api/v1/messages/:id/reactions`
- `DELETE /api/v1/messages/:id/reactions`
- `POST /api/v1/messages/:id/read`
- `POST /api/v1/messages/:id/deliver`

Shape:

```json
{
  "id": 99,
  "conversation_id": 11,
  "sender_id": 8,
  "sender_name": "Boris Teacher",
  "body": "Please review this file.",
  "message_type": "file",
  "status": "read",
  "reply_to_message_id": null,
  "edited_at": null,
  "deleted_at": null,
  "created_at": "2026-03-15T19:55:12.000Z",
  "updated_at": "2026-03-15T19:55:12.000Z",
  "attachments": [
    {
      "id": 14,
      "attachment_type": "pdf",
      "file_name": "lesson-plan.pdf",
      "content_type": "application/pdf",
      "file_size": 102400,
      "storage_key": "abc123",
      "file_url": "http://localhost:3000/rails/active_storage/blobs/...",
      "created_at": "2026-03-15T19:55:12.000Z"
    }
  ],
  "reactions": [
    {
      "id": 3,
      "user_id": 7,
      "reaction": "like",
      "created_at": "2026-03-15T19:56:20.000Z"
    }
  ],
  "delivered_user_ids": [7, 8],
  "read_user_ids": [7, 8]
}
```

Notes:
- `body` can be `null` only if the message was sent with attachments only
- `message_type` is string-based, not integer-based
- `reply_to_message_id` is supported in the payload but reply UX is not otherwise expanded yet

Message type values:
- `text`
- `file`
- `image`
- `system`

Message status values:
- `sent`
- `delivered`
- `read`
- `edited`
- `deleted`

## 4) Message attachment

Nested under `message.attachments`.

Fields:
- `id`
- `attachment_type`
- `file_name`
- `content_type`
- `file_size`
- `storage_key`
- `file_url`
- `created_at`

Attachment type values:
- `file`
- `image`
- `pdf`

Notes:
- attachments are stored with Active Storage
- frontend should use `file_url` directly for preview/download

## 5) Message reaction

Nested under `message.reactions`.

Fields:
- `id`
- `user_id`
- `reaction`
- `created_at`

Reaction values currently allowed:
- `like`
- `heart`
- `laugh`
- `check`

## Suggested TypeScript types

```ts
export type ChatPresenceStatus = "online" | "offline" | "away" | "busy";

export type ChatConversationType = "direct" | "group";

export type ChatMessageType = "text" | "file" | "image" | "system";

export type ChatMessageStatus = "sent" | "delivered" | "read" | "edited" | "deleted";

export type ChatReactionType = "like" | "heart" | "laugh" | "check";

export type ChatAttachmentType = "file" | "image" | "pdf";

export type ChatParticipant = {
  id: number;
  email: string;
  first_name: string | null;
  last_name: string | null;
  full_name: string;
  roles: string[];
  joined_at: string;
  last_read_message_id: number | null;
  last_read_at: string | null;
  presence_status: ChatPresenceStatus;
  last_seen_at: string | null;
};

export type ChatCurrentUserState = {
  joined_at: string;
  last_read_message_id: number | null;
  last_read_at: string | null;
  active: boolean;
};

export type ChatMessageAttachment = {
  id: number;
  attachment_type: ChatAttachmentType;
  file_name: string | null;
  content_type: string | null;
  file_size: number | null;
  storage_key: string | null;
  file_url: string | null;
  created_at: string;
};

export type ChatMessageReaction = {
  id: number;
  user_id: number;
  reaction: ChatReactionType;
  created_at: string;
};

export type ChatMessage = {
  id: number;
  conversation_id: number;
  sender_id: number;
  sender_name: string;
  body: string | null;
  message_type: ChatMessageType;
  status: ChatMessageStatus;
  reply_to_message_id: number | null;
  edited_at: string | null;
  deleted_at: string | null;
  created_at: string;
  updated_at: string;
  attachments: ChatMessageAttachment[];
  reactions: ChatMessageReaction[];
  delivered_user_ids: number[];
  read_user_ids: number[];
};

export type ChatConversation = {
  id: number;
  school_id: number;
  conversation_type: ChatConversationType;
  active: boolean;
  last_message_at: string | null;
  created_at: string;
  updated_at: string;
  participants: ChatParticipant[];
  current_user_state: ChatCurrentUserState | null;
  unread_count: number;
  last_message: ChatMessage | null;
};
```

## FE state recommendations

- use `conversation.id` as the stable chat thread key
- for direct chat title/avatar, derive the "other person" from `participants` by excluding the current user id
- use `last_message_at ?? created_at` for inbox sorting in FE if local resorting is needed
- use `unread_count` from backend for the inbox badge
- use `read_user_ids` and `delivered_user_ids` for status indicators instead of inferring from `status` only
- treat timestamps as ISO strings and format them client-side

## Current limitations

- no edit message endpoint yet
- no delete message endpoint yet
- no group conversation creation flow yet
- no participant add/remove flow yet
- no websocket or realtime push transport yet
- list endpoints use offset pagination only
