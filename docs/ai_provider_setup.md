# AI Provider Setup

This backend already supports OpenAI, but it is opt-in.

By default, the tutor uses the mock provider. The switch to OpenAI happens only when both of these are true:

- `AI_PROVIDER=openai`
- `OPENAI_API_KEY` is present

If your stored key value is base64-encoded, also set:

- `OPENAI_API_KEY_BASE64=true`

The current implementation reads environment variables directly in:
- [open_ai_client.rb](/home/andrejbugi/projects/be_education_ai/app/services/ai_providers/open_ai_client.rb)
- [client_factory.rb](/home/andrejbugi/projects/be_education_ai/app/services/ai_providers/client_factory.rb)

## Environment Variables

Required:

```bash
AI_PROVIDER=openai
OPENAI_API_KEY=your_openai_api_key
```

Optional:

```bash
OPENAI_MODEL=gpt-4.1-mini
OPENAI_API_KEY_BASE64=true
```

If `OPENAI_MODEL` is omitted, the backend defaults to `gpt-4.1-mini`.
If `OPENAI_API_KEY_BASE64=true`, the backend base64-decodes `OPENAI_API_KEY` before sending requests to OpenAI.

## Recommended Local Setup

The safest project-local approach in this repo is:

1. Create an untracked local env file.
2. Restrict its permissions.
3. Source it into your shell before starting Rails.

This repo already ignores `.env*` in [.gitignore](/home/andrejbugi/projects/be_education_ai/.gitignore), so the file will stay out of git unless you force-add it.

### Example

Create `.env.development.local` in the project root:

```bash
cat > .env.development.local <<'EOF'
AI_PROVIDER=openai
OPENAI_API_KEY=your_base64_encoded_openai_api_key
OPENAI_API_KEY_BASE64=true
OPENAI_MODEL=gpt-4.1-mini
EOF

chmod 600 .env.development.local
```

Load it into your current shell and start the server:

```bash
set -a
source .env.development.local
set +a
bin/rails server
```

Important:
- this app does not currently load Rails credentials for OpenAI
- this app does not currently auto-load `.env.development.local`
- the values must exist in the shell environment when Rails boots
- if your key is plain text, omit `OPENAI_API_KEY_BASE64` or set it to `false`

## How To Verify It Works

Start or reuse an AI session, then send a student question through:

- `POST /api/v1/ai_sessions`
- `POST /api/v1/ai_sessions/:id/messages`

On success, the assistant message metadata should show:

```json
{
  "provider": "openai",
  "model": "gpt-4.1-mini"
}
```

If OpenAI is configured but the request fails, the backend falls back to the mock tutor in [generate_response.rb](/home/andrejbugi/projects/be_education_ai/app/services/ai_tutor/generate_response.rb). In that case the response metadata may include fallback details such as:

```json
{
  "provider": "mock",
  "requested_provider": "open_ai_client",
  "fallback_reason": "..."
}
```

## What Not To Do

- Do not commit the key to the repository.
- Do not hardcode it in frontend code.
- Do not put it in tracked YAML, JSON, or README snippets with real values.
- Do not rely on Rails credentials for this specific setting unless you also change the backend code to read from credentials.

## Production Note

For deployment, store the key in your platform secret manager or deployment secret store and expose it as `OPENAI_API_KEY`.

For Kamal-style deployment, the practical split is:
- secret: `OPENAI_API_KEY`
- clear env: `AI_PROVIDER=openai`
- clear env: `OPENAI_MODEL=gpt-4.1-mini`

## Current AI Flow

The FE/API flow itself is documented here:
- [ai_instructions_for_fe.md](/home/andrejbugi/projects/be_education_ai/docs/ai_instructions_for_fe.md)
