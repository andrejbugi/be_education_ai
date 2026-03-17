# Chat Messaging API For FE

Base path: `/api/v1`

This doc focuses on the request and response flow frontend should use for chat.

For exact entity fields, see:
- [data_model_for_fe.md](./data_model_for_fe.md)

Current realtime status:
- backend is configured with Redis-backed Action Cable at `/cable`
- new-message realtime is implemented for conversation subscriptions
- delivered, read, reactions, and presence still use the existing HTTP flow

## Headers

Send on all protected requests:

```http
Authorization: Bearer <jwt>
X-School-Id: <selected_school_id>
```

## Recommended FE flow

1. Load conversations with `GET /api/v1/conversations`.
2. When user opens one conversation, load messages with `GET /api/v1/conversations/:conversation_id/messages`.
3. Open a websocket connection to `/cable?token=<jwt>`.
4. Subscribe to the current conversation channel.
5. When a `message.created` event arrives, append the message to local state.
6. After rendering unread incoming messages, call `POST /api/v1/messages/:id/deliver` and/or `POST /api/v1/messages/:id/read`.
7. When user sends a message, call `POST /api/v1/conversations/:conversation_id/messages`.
8. For reactions, call `POST /api/v1/messages/:id/reactions` or `DELETE /api/v1/messages/:id/reactions`.
9. Refresh presence periodically with `POST /api/v1/presence/update`.

## Websocket connection

Websocket endpoint:

```text
/cable?token=<jwt>
```

Example:

```text
ws://localhost:3000/cable?token=YOUR_JWT
```

Authentication:
- websocket auth uses the JWT in the `token` query param
- the backend rejects the connection if the token is missing, invalid, expired, or belongs to an inactive user

## Conversation channel subscription

Channel:

```text
ConversationChannel
```

Subscribe payload:

```json
{
  "command": "subscribe",
  "identifier": "{\"channel\":\"ConversationChannel\",\"conversation_id\":11}"
}
```

Rules:
- user must be an active participant in that conversation
- non-participants are rejected

## Realtime event currently implemented

Current event:

```json
{
  "type": "message.created",
  "conversation_id": 11,
  "message": {
    "id": 99,
    "conversation_id": 11,
    "sender_id": 8,
    "sender_name": "Boris Teacher",
    "body": "Please review this file.",
    "message_type": "file",
    "status": "sent",
    "reply_to_message_id": null,
    "edited_at": null,
    "deleted_at": null,
    "created_at": "2026-03-17T12:00:00.000Z",
    "updated_at": "2026-03-17T12:00:00.000Z",
    "attachments": [],
    "reactions": [],
    "delivered_user_ids": [8],
    "read_user_ids": [8]
  }
}
```

Notes:
- `message` uses the same shape as the normal HTTP chat message payload
- sender also receives the broadcast if subscribed to the same conversation

## 1) List conversations

`GET /api/v1/conversations`

Query params:
- `limit`
- `offset`

Response:
- array of `ChatConversation`

Notes:
- sorted by latest activity first
- only conversations where current user is an active participant are returned

## 2) Create direct conversation

`POST /api/v1/conversations`

Payload:

```json
{
  "school_id": 3,
  "conversation_type": "direct",
  "participant_ids": [8]
}
```

Response:
- returns one `ChatConversation`

Behavior:
- if an active direct conversation already exists for the same pair in the same school, backend returns that existing conversation
- status is `201 Created` for a new conversation
- status is `200 OK` when an existing conversation is reused

Current permission rules:
- teacher-teacher in same school: allowed
- teacher-student in same school with shared classroom: allowed
- student-student: blocked

## 3) List messages

`GET /api/v1/conversations/:conversation_id/messages`

Query params:
- `limit`
- `offset`

Response:
- array of `ChatMessage`

Notes:
- returns non-deleted visible messages only
- current backend ordering is oldest first within the page

## 4) Send message

`POST /api/v1/conversations/:conversation_id/messages`

Supports standard form submission with files.

Text-only payload example:

```json
{
  "body": "Can you review this?",
  "message_type": "text"
}
```

Multipart example:

```text
body=Please review the attached file
files[]=<binary>
```

Optional fields:
- `message_type`
- `reply_to_message_id`
- `files[]`

Response:
- returns one `ChatMessage`

Backend behavior:
- sender is automatically marked as delivered and read for their own message
- conversation `last_message` and `last_message_at` are updated automatically
- if files are attached and `message_type` is omitted, backend infers `image` or `file`

## 5) Add reaction

`POST /api/v1/messages/:id/reactions`

Payload:

```json
{
  "reaction": "like"
}
```

Response:
- returns the full updated `ChatMessage`

Notes:
- same user cannot create the exact same reaction twice on the same message

## 6) Remove reaction

`DELETE /api/v1/messages/:id/reactions`

Payload:

```json
{
  "reaction": "like"
}
```

Response:
- returns the full updated `ChatMessage`

## 7) Mark delivered

`POST /api/v1/messages/:id/deliver`

Payload:
- no body required

Response:
- returns the full updated `ChatMessage`

Use when:
- message has reached the chat screen or client has confirmed receipt

## 8) Mark read

`POST /api/v1/messages/:id/read`

Payload:
- no body required

Response:
- returns the full updated `ChatMessage`

Backend side effects:
- creates or updates read state for the current user
- also ensures delivery state exists
- updates conversation participant `last_read_message_id`
- may change message `status` to `read`

## 9) Update presence

`POST /api/v1/presence/update`

Payload:

```json
{
  "status": "online"
}
```

Compatibility note:
- backend also accepts `{ "presence": { "status": "online" } }`
- top-level `status` is the preferred documented shape

Response:

```json
{
  "user_id": 8,
  "status": "online",
  "last_seen_at": "2026-03-15T19:56:10.000Z"
}
```

Suggested FE usage:
- call on chat screen open
- call periodically while active
- call with `away` or `offline` if app wants to manage explicit transitions

## Error handling

Common responses:

- `401 Unauthorized`
  - missing or invalid token

- `403 Forbidden`
  - not used often in current chat endpoints because inaccessible resources are usually hidden as not found

- `404 Not found`
  - conversation or message is not visible to current user

- `422 Unprocessable Entity`
  - invalid participant selection
  - disallowed role combination
  - blank message without attachments
  - invalid reaction value
  - reply target not in the same conversation

Example error response:

```json
{
  "errors": ["This conversation is not allowed"]
}
```

## Frontend implementation notes

- for a direct chat row, display the other participant from `participants`
- if `last_message` exists, use that for preview text and timestamp
- if `body` is blank and `attachments.length > 0`, render an attachment-only preview
- use optimistic UI carefully for reactions and sends if desired, but backend returns the full updated message after each state mutation
- keep the HTTP message create flow as the source of truth for sending
- use realtime only to append incoming `message.created` updates
- keep polling or manual refresh for conversation list updates unless FE also refetches inbox on incoming events

## Not implemented yet

- edit message
- delete message
- group chat management
- typing indicators
- websocket broadcasts for delivered, read, reactions, and presence
