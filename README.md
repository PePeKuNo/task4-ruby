# Task4 Ruby — User Management System

A Rails 8 user-management application with an admin table, bulk user actions, a chat
area, and a **real AI assistant that answers natural-language questions about the data**
using tool calling against the live database.

**Live:** https://task4-ruby-production.up.railway.app

## Stack

- Ruby 3.3, Rails 8.1
- SQLite (all environments, including production)
- Bootstrap 5 + Bootstrap Icons, Stimulus (Hotwire / Turbo)
- bcrypt (`has_secure_password`)

## Features

- **Registration / login** with any non-empty password; blocked users cannot log in.
- **Admin table** of all users, sorted by `last_seen`, with checkboxes and a header
  "select all" checkbox. A toolbar (always visible, buttons enable on selection) offers
  Block (text button), Unblock (icon) and Delete (icon). No per-row buttons.
- **Hard delete** — deleted users can register again. Every user (including the current
  one) can be blocked/unblocked/deleted; every user is an admin.
- **Access rule**: on every request except register/login the app verifies the user
  still exists and is not blocked, otherwise it redirects to login (mass-blocking
  yourself logs you out automatically).
- **Chat area** with Turbo messages.
- **AI Assistant (Part 2)** — ask anything about the users in natural language.
- **AI Tool (Part 3)** — the assistant controls the app: filter users by status etc.

## AI integration (Part 2 & 3)

The AI is a **real LLM integration** (see `app/services/ai_service.rb`):

1. The user's free-form question is sent to an OpenAI-compatible chat-completions API.
2. The model responds with **tool calls** (`count_users`, `list_users`, `find_user`).
3. The app executes them as **real ActiveRecord queries** and returns the results.
4. The model writes the final natural-language insight — numbers never come from the
   model's imagination, they always come from the database.

`app/controllers/ai_controller.rb#tools` additionally exposes explicit tool endpoints
(`filter_users`, `bulk_action`) used by the AI Tool panel in the UI.

### Configuration (environment variables)

| Variable | Required | Default | Notes |
|---|---|---|---|
| `AI_API_KEY` | yes (for AI) | — | Secret key of any OpenAI-compatible provider |
| `AI_BASE_URL` | no | `https://api.openai.com/v1` | Any OpenAI-compatible base URL |
| `AI_MODEL` | no | `gpt-4o-mini` | Model id; comma-separated fallback list supported |

Provider examples:

```bash
# OpenAI
AI_API_KEY=sk-...            AI_MODEL=gpt-4o-mini

# Groq (free tier: https://console.groq.com/keys)
AI_API_KEY=gsk_...           AI_BASE_URL=https://api.groq.com/openai/v1       AI_MODEL=llama-3.3-70b-versatile

# Google Gemini (free tier: https://aistudio.google.com/apikey)
AI_API_KEY=AIza...           AI_BASE_URL=https://generativelanguage.googleapis.com/v1beta/openai  AI_MODEL=gemini-3.5-flash,gemini-3.6-flash
```

**Fallback:** if `AI_API_KEY` is not configured or the provider is unreachable, the
controller answers from a small set of deterministic intents so the feature never
breaks (those answers are template-shaped, real-AI answers are free-form).

## Local setup

```bash
bundle install
bin/rails db:prepare     # creates the DB, loads schema, seeds from db/users.json
bin/rails server
```

All seeded users share the password `password123`. User data is loaded **only** from
the organizer-provided `db/users.json` (200 users, 96 active / 104 blocked).

## Database

- Unique index on `email` at the database level: `index_users_on_email_unique`
  (verified again in `db/seeds.rb` on every seed run).
- Indexes on `status` and `last_seen` (sorting/filtering).
- Local development database lives in `storage/development.sqlite3`.

To print the index SQL straight from the database:

```bash
bin/rails runner "puts ActiveRecord::Base.connection.select_values(%q{SELECT sql FROM sqlite_master WHERE type='index' AND tbl_name='users'})"
```

(On Windows PowerShell prefix commands with `ruby`: `ruby bin\rails runner "..."`.)

## Deployment (Railway)

- Start command: `bin/rails db:prepare && bin/rails server` (see `railway.json`).
- SQLite in production: 4 databases (`db/production*.sqlite3`), created on boot.
- There is **no volume**, so every redeploy resets the database to the seeded 200 users.
- Set `AI_API_KEY` (and optionally `AI_BASE_URL` / `AI_MODEL`) in the service
  Variables before the final demo.
