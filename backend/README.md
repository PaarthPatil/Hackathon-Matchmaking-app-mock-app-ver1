# Catalyst Backend

## Development

```bash
uvicorn app.main:app --reload
```

## Tests

```bash
pytest
```

## Smoke Check

Run basic API health checks after starting the backend:

```bash
python backend/scripts/smoke_check.py --base-url http://127.0.0.1:8000
```

Authenticated checks (recommended):

```bash
python backend/scripts/smoke_check.py \
  --base-url http://127.0.0.1:8000 \
  --user-token "<USER_JWT>" \
  --admin-token "<ADMIN_JWT>" \
  --strict-auth
```

## Production

```bash
gunicorn app.main:app -k uvicorn.workers.UvicornWorker -w 4 -b 0.0.0.0:8000
```

## Required Environment Variables

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY` (preferred)
- `SUPABASE_KEY` (legacy fallback)
- `JWT_SECRET` (optional unless local JWT checks are added)
- `ENVIRONMENT` (`development` or `production`)
- `CORS_ORIGINS` (comma-separated origins in production)
- `POST_CREATE_LIMIT_PER_MINUTE`
- `VOTE_LIMIT_PER_MINUTE`
- `TEAM_JOIN_LIMIT_PER_10MIN`
- `REDIS_URL` (optional, recommended for production cache + rate limiting)

## Required SQL Migrations

Run these in Supabase SQL editor:

0. `catalyst_app/database_setup.sql` (base tables + RLS)
1. `backend/sql/001_hackathon_requests.sql`
2. `backend/sql/002_social_layer.sql`
3. `backend/sql/003_backend_hardening.sql`
