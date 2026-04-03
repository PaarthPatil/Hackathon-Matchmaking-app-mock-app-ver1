# Catalyst Backend

## Development

From the `backend` directory:

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Or from the workspace root:

```bash
PYTHONPATH=backend uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

## Tests

```bash
pytest
```

## Smoke Check

Run basic API health checks after starting the backend:

```bash
python backend/scripts/smoke_check.py --base-url http://127.0.0.1:8001
```

Authenticated checks (recommended):

```bash
python backend/scripts/smoke_check.py \
  --base-url http://127.0.0.1:8001 \
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
- `ADMIN_USER_IDS` (comma-separated UUID allowlist for admin-mode access)

## Development Auth Behavior

- Missing or invalid bearer tokens return `401` for protected routes.
- `get_current_user` validates Supabase JWT and returns both `user_id` and `email`.
- Admin access is allowlisted by `ADMIN_USER_IDS` and/or profile roles.
- Admin write actions require a valid `SUPABASE_SERVICE_ROLE_KEY` (`role=service_role`).

## Required SQL Migrations

Run these in Supabase SQL editor:

0. `catalyst_app/database_setup.sql` (base tables + RLS)
1. `backend/sql/001_hackathon_requests.sql`
2. `backend/sql/002_social_layer.sql`
3. `backend/sql/003_backend_hardening.sql`
4. `backend/sql/004_admin_role_support.sql`
