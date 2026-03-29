# 🚨 BACKEND ARCHITECTURE RULE (CRITICAL)

This application uses a HYBRID BACKEND:

* Supabase → database, auth, storage ONLY
* Python backend → ALL business logic and APIs

---

# STRICT RULES

* Flutter MUST NOT implement business logic
* Flutter MUST NOT compute team matching
* Flutter MUST NOT trigger notifications directly

---

# ALL COMPLEX LOGIC MUST GO THROUGH PYTHON API

Examples:

* Team matching → Python API
* Team join flow → Python API
* Notifications → Python API
* Validation logic → Python API

---

# DATA FLOW

Flutter → Python API → Supabase DB

---

# EXCEPTION

Flutter MAY:

* read simple data from Supabase (optional)
* use Supabase Auth
* use Supabase Realtime for chat

---

# VIOLATION IS NOT ALLOWED

If any logic is implemented in Flutter instead of Python → it is WRONG
