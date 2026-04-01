You are building a **production-grade Python backend using FastAPI** for a Flutter mobile application.

This is **PHASE B1: BACKEND FOUNDATION**.

You MUST follow ALL instructions exactly. Do NOT assume missing logic. Do NOT simplify. Do NOT skip anything.

---

# 🔁 FULL PRODUCT CONTEXT (MANDATORY – READ CAREFULLY)

This application is a **gamified hackathon team formation platform**.

The frontend is built in Flutter and already enforces strict UX flows.

---

# 🧠 CORE PRODUCT RULES

1. This is NOT a Tinder-like app.

2. Team formation is NOT random — it is based on:

   * skills
   * roles
   * compatibility

3. Users MUST NOT browse teams globally.

---

# 🚨 STRICT TEAM FLOW (VERY IMPORTANT)

The ONLY valid flow:

Hackathon → user clicks → THEN sees:

* Create Team
* Join Team

If user selects "Join Team":
→ backend MUST return ONLY recommended teams
→ NO endpoint should ever return all teams globally

---

# 👥 TEAM SYSTEM (CONTEXT FOR FUTURE PHASES)

* Joining a team = REQUEST (not instant)

* Membership states:

  * pending
  * accepted
  * rejected

* One user can be in ONLY ONE team per hackathon

---

# 🏆 HACKATHON SYSTEM

* Users can REQUEST hackathons
* Admin approves and creates hackathons
* Admin can update/delete hackathons

---

# 🎯 GOAL OF THIS PHASE

You are NOT implementing full business logic yet.

You are building the **FOUNDATION**:

✅ FastAPI application
✅ Project structure
✅ Supabase integration
✅ Authentication system
✅ Role system (admin/user)
✅ Middleware
✅ Base routing system

---

# 🏗️ TECH STACK (STRICT)

* FastAPI
* Supabase Python client
* PostgreSQL (via Supabase)
* Pydantic (for schemas)
* Uvicorn (server)

---

# 📁 PROJECT STRUCTURE (MUST BE EXACT)

backend/
app/
main.py
core/
config.py
security.py
dependencies.py
db/
supabase_client.py
models/
schemas/
services/
api/
routes/
auth.py
profile.py
hackathon.py
team.py
admin.py
community.py
notification.py

---

# ⚙️ STEP 1: ENVIRONMENT CONFIGURATION

Create config.py:

* Load environment variables:

  * SUPABASE_URL
  * SUPABASE_KEY
  * JWT_SECRET (if needed)

Use python-dotenv or os.environ

---

# ⚙️ STEP 2: SUPABASE CLIENT SETUP

Create supabase_client.py:

* Initialize Supabase client once
* Export reusable client instance

Example:

supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

---

# ⚙️ STEP 3: FASTAPI APP INITIALIZATION

In main.py:

* Create FastAPI app

* Add CORS middleware:

  * allow all origins (for now)

* Include routers (even if empty for now)

---

# ⚙️ STEP 4: AUTHENTICATION SYSTEM (CRITICAL)

You MUST implement Supabase JWT verification.

---

## REQUIREMENTS

* Extract JWT from Authorization header:
  "Bearer <token>"

* Validate token using Supabase

* Extract:

  * user_id

---

## CREATE FUNCTION

get_current_user()

Returns:
{
user_id: string
}

If invalid:
→ raise HTTPException(401)

---

# ⚙️ STEP 5: ROLE SYSTEM

Profiles table includes:

* role: "user" or "admin"

---

## CREATE DEPENDENCY

get_current_admin()

* calls get_current_user()
* fetches profile
* checks role == admin

If not:
→ raise HTTPException(403)

---

# ⚙️ STEP 6: DEPENDENCY INJECTION SYSTEM

Create dependencies.py:

Functions:

* get_current_user
* get_current_admin

These MUST be reusable across all routes

---

# ⚙️ STEP 7: BASE ROUTERS (STRUCTURE ONLY)

Create routers:

auth.py
profile.py
hackathon.py
team.py
admin.py
community.py
notification.py

Each router must:

* be APIRouter()
* have prefix
* have at least one test route:

GET /health

Returns:
{ "status": "ok" }

---

# ⚙️ STEP 8: ERROR HANDLING SYSTEM

Implement global exception handling:

* Catch generic exceptions
* Return structured JSON:

{
"error": "message"
}

---

# ⚙️ STEP 9: LOGGING SYSTEM

* Log:

  * incoming requests
  * errors

Use Python logging module

---

# ⚙️ STEP 10: SECURITY RULES

* ALL routes (except auth) require authentication
* Admin routes require admin role
* No route should expose sensitive data

---

# ⚙️ STEP 11: RUNNING THE SERVER

Command:

uvicorn app.main:app --reload

---

# 📦 OUTPUT REQUIREMENTS

You MUST generate:

1. Full folder structure
2. main.py with app setup
3. config.py
4. supabase_client.py
5. security.py (JWT validation)
6. dependencies.py
7. All routers (with prefixes + test routes)
8. Logging setup
9. Error handling

---

# 🚨 FINAL RULES

* DO NOT skip any file
* DO NOT leave placeholders
* DO NOT assume missing logic
* Everything must be runnable

---

END OF PHASE B1
