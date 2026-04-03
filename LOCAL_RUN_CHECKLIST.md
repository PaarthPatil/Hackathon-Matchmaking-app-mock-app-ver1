# Catalyst Local Run Checklist

## 1. Apply SQL Migrations (Supabase SQL Editor)
Run these in order:

1. `catalyst_app/database_setup.sql`
2. `backend/sql/001_hackathon_requests.sql`
3. `backend/sql/002_social_layer.sql`
4. `backend/sql/003_backend_hardening.sql`
5. `backend/sql/004_admin_role_support.sql`

## 2. Backend Environment
Create `backend/.env` with at least:

- `SUPABASE_URL=...`
- `SUPABASE_SERVICE_ROLE_KEY=...`
- `ENVIRONMENT=development`
- `CORS_ORIGINS=http://localhost:3000,http://localhost:5173`

Optional but recommended:

- `REDIS_URL=redis://127.0.0.1:6379/0`
- `POST_CREATE_LIMIT_PER_MINUTE=5`
- `VOTE_LIMIT_PER_MINUTE=30`
- `TEAM_JOIN_LIMIT_PER_10MIN=10`

## 3. Install Backend Dependencies

```bash
pip install -r backend/requirements-dev.txt
```

## 4. Start Backend

```bash
cd backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

Backend base URL: `http://127.0.0.1:8001`

## 5. Run Backend Validation

```bash
python -m compileall backend/app
python -m pytest -q backend/tests
python backend/scripts/smoke_check.py --base-url http://127.0.0.1:8001
```

For full auth smoke checks, include tokens:

```bash
python backend/scripts/smoke_check.py \
  --base-url http://127.0.0.1:8001 \
  --user-token "<USER_JWT>" \
  --admin-token "<ADMIN_JWT>" \
  --strict-auth
```

## 6. Flutter Setup

```bash
cd catalyst_app
flutter pub get
flutter test
flutter analyze
```

## 7. Start Flutter App

```bash
cd catalyst_app
flutter run
```

The app calls FastAPI at:

- `catalyst_app/lib/core/constants/api_constants.dart`
  - `pythonBaseUrl` from `--dart-define=PYTHON_API_BASE_URL=...`

The app initializes Supabase from:

- `--dart-define=SUPABASE_URL=...`
- `--dart-define=SUPABASE_ANON_KEY=...`

Example:

```bash
flutter run \
  --dart-define=PYTHON_API_BASE_URL=http://192.168.6.107:8001/api/v1 \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
.