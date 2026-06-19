# rcd-ai-proxy

Cloudflare Worker that sits between the relationship clarity dashboard clients
(web + iOS) and OpenAI. The browser/app sends a Supabase JWT and a structured
payload; the Worker verifies the JWT, calls OpenAI with `response_format:
json_object`, validates the response, and returns clean JSON.

The OpenAI key never leaves the Worker.

## Endpoints

| Path                | Method | Purpose                                      |
| ------------------- | ------ | -------------------------------------------- |
| `/health`           | GET    | Liveness check, returns `{ ok: true }`.      |
| `/analyze-entry`    | POST   | Structure one user entry + score deltas.     |
| `/weekly-summary`   | POST   | Synthesize a week of entries into a summary. |

All POST endpoints require `Authorization: Bearer <supabase_access_token>`.
Request/response shapes are documented in:
- `app/api/aiServer.js` (web client)
- `SupabaseStarter/SupabaseStarter/Services/AIServerService.swift` (iOS client)

## One-time setup

```bash
cd ai-proxy
npm install
npx wrangler login          # opens your browser to authorize Cloudflare
```

Set required configuration:

```bash
# Public, lives in wrangler.toml — edit before deploying:
#   SUPABASE_PROJECT_REF        e.g. "abcd1234" (the part before .supabase.co)
#   OPENAI_MODEL                default "gpt-4o-mini"
#   ALLOWED_ORIGINS             comma-separated list

# Secrets (set via wrangler, never committed):
npx wrangler secret put OPENAI_API_KEY
```

### Pick a JWT verification mode

The Worker supports both Supabase auth modes:

- **Asymmetric (RS256, JWKS) — default and recommended.**
  Requires no extra secret. The Worker fetches your project's JWKS at
  `https://<project_ref>.supabase.co/auth/v1/.well-known/jwks.json`. Only works
  if your Supabase project has asymmetric JWT signing keys enabled (Dashboard →
  Project Settings → JWT Keys).

- **Symmetric (HS256, legacy default).** Set the shared JWT secret as a Worker
  secret:
  ```bash
  npx wrangler secret put SUPABASE_JWT_SECRET
  ```
  Find the value at Supabase Dashboard → Project Settings → API → JWT Settings.
  If this secret is set, the Worker uses HS256 and skips JWKS.

If you don't know which mode your project uses, set `SUPABASE_JWT_SECRET` —
that's the safer default.

## Develop locally

```bash
npm run dev     # http://localhost:8787
```

To test from the web client, point `app/config.js` at `http://localhost:8787`
and add `http://localhost:8000` to `ALLOWED_ORIGINS` in `wrangler.toml`.

## Deploy

```bash
npm run deploy
```

The Worker will be live at `https://rcd-ai-proxy.<your-subdomain>.workers.dev`.
Set that URL as `AI_SERVER_BASE_URL` in `app/config.js` (web) and
`AIServer+Config.swift` (iOS).

## Smoke test

```bash
# 1. Get an access token by signing in via the web app or iOS app,
#    then inspecting localStorage / Keychain. Or use curl + Supabase:

curl -s -X POST \
  "https://<project_ref>.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: <anon_key>" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"..."}' \
  | jq -r .access_token

# 2. Hit the analyze endpoint:
TOKEN="..."
curl -s -X POST "https://rcd-ai-proxy.<sub>.workers.dev/analyze-entry" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "entry_id": "00000000-0000-0000-0000-000000000001",
    "person": {
      "id": "00000000-0000-0000-0000-000000000002",
      "display_name": "M.",
      "relationship_type": "romantic",
      "current_scores": {
        "emotionalSafety": 60, "consistency": 50, "reciprocity": 55,
        "growthAlignment": 60, "integrity": 70, "attraction": 75
      }
    },
    "raw_text": "He went silent for 8 hours then sent a sweet message at midnight.",
    "occurred_at": "2026-06-19T22:00:00Z",
    "recent_entries": [],
    "boundaries": ["No silent treatment for more than 24 hours."]
  }' | jq
```

You should get back:

```json
{
  "model": "gpt-4o-mini",
  "analysis": {
    "headline": "...",
    "facts": [...],
    "emotions": [...],
    "deltas": { "emotionalSafety": -3, ... },
    ...
  }
}
```

## Cost

On Cloudflare's free tier (100k requests/day, 10ms CPU per request) you'll
never run out: a typical analyze-entry request uses ~1-2ms of Worker CPU
(the OpenAI call wait time doesn't count). The variable cost is OpenAI itself
— `gpt-4o-mini` is roughly $0.15/1M input tokens and $0.60/1M output tokens.
A typical entry analysis is ~600 in + 250 out tokens, so a few hundred
analyses cost cents.

## Errors

The Worker always returns JSON. Error shape:

```json
{ "error": { "code": "...", "message": "..." } }
```

| Code             | HTTP | Meaning                                           |
| ---------------- | ---- | ------------------------------------------------- |
| `invalid_jwt`    | 401  | Missing or unverifiable Supabase token.           |
| `bad_request`    | 400  | Body wasn't valid JSON.                           |
| `not_found`      | 404  | Unknown route.                                    |
| `method_not_allowed` | 405 | Wrong HTTP method.                            |
| `openai_error`   | 502  | OpenAI returned non-2xx.                          |
| `bad_response`   | 502  | OpenAI returned non-JSON twice in a row.          |
| `internal_error` | 500  | Anything else.                                    |

Clients should surface `error.message` to the user, save the raw entry without
its analysis, and offer a "Retry analysis" button.
