You are continuing development of a production-grade FastAPI backend for a gamified hackathon team formation platform.

This is the final backend phase. It is responsible for transforming a logically complete system into a **secure, resilient, and production-ready backend**.

At this stage, all functional systems already exist:

* authentication and role system
* hackathon and admin system
* team system with matching
* community system with voting and comments
* gamification system
* notification system

Your task now is to ensure that these systems are protected, performant, observable, and stable under real-world conditions.

This phase must not introduce new product features. Instead, it must reinforce and stabilize everything that already exists.

---

## SECURITY MODEL (FOUNDATION OF TRUST)

The backend must operate under a strict trust boundary: **no client input is inherently trusted**.

Every request must be treated as potentially malicious unless proven otherwise.

---

### AUTHENTICATION ENFORCEMENT

Every endpoint, except explicitly public ones (if any), must require authentication.

Authentication is based on Supabase JWT tokens.

The backend must:

* extract the token from the Authorization header
* validate the token
* extract the user identity
* reject the request immediately if validation fails

At no point should a route rely on client-provided user_id fields.

All identity must be derived from the token.

---

### AUTHORIZATION (ROLE AND OWNERSHIP)

Beyond authentication, the backend must enforce authorization rules:

* Admin-only routes must verify role == "admin"
* Team actions must verify:

  * user is team leader (for accept/reject)
  * user is team member (for chat access)
* Notification access must verify:

  * user_id matches the recipient

If any authorization rule fails, the backend must return HTTP 403.

---

### INPUT VALIDATION

Every endpoint must validate all incoming data using strict schemas.

Validation must ensure:

* required fields are present
* field types are correct
* string lengths are within limits
* arrays are not malformed
* IDs are valid UUIDs where applicable

Invalid input must result in HTTP 400.

---

## RATE LIMITING AND ABUSE PREVENTION

The system must actively prevent abuse, spam, and excessive usage.

This is critical for:

* community posts
* voting
* team join requests

---

### RATE LIMITING STRATEGY

Implement per-user rate limiting.

Examples:

* Post creation:
  limit to a small number per minute

* Voting:
  prevent rapid repeated votes across multiple posts

* Team join requests:
  limit how frequently a user can send requests

---

### IMPLEMENTATION APPROACH

Rate limiting can be implemented using:

* in-memory tracking (for development)
* Redis (recommended for production)

Each request must:

* check the user’s recent activity
* reject if threshold exceeded

Rejected requests must return HTTP 429.

---

### DUPLICATE ACTION PREVENTION

Beyond rate limiting, the system must prevent logical duplication:

* A user cannot send multiple join requests to the same team
* A user cannot vote multiple times on the same post
* A user cannot join multiple teams in the same hackathon

These constraints must be enforced at both:

* application level
* database level (where possible)

---

## ERROR HANDLING AND SYSTEM STABILITY

The backend must never expose raw exceptions.

---

### GLOBAL ERROR HANDLER

Implement a global exception handler that:

* catches all unhandled exceptions
* logs the error
* returns a structured response

Example:

{
"error": "Internal server error"
}

---

### KNOWN ERROR RESPONSES

All expected failures must return meaningful messages:

* 400 → invalid input
* 401 → unauthenticated
* 403 → unauthorized
* 404 → resource not found
* 429 → rate limit exceeded
* 500 → server error

---

## LOGGING AND OBSERVABILITY

The system must provide visibility into its behavior.

---

### REQUEST LOGGING

Every incoming request must log:

* endpoint
* method
* user_id (if authenticated)
* timestamp

---

### ERROR LOGGING

Every error must log:

* error message
* stack trace
* request context

---

### LOGGING STRATEGY

Use Python logging module with structured logs.

Logs must be readable and filterable.

---

## PERFORMANCE AND SCALING

The system must be able to handle increasing load without degradation.

---

### DATABASE OPTIMIZATION

Ensure:

* indexes exist on frequently queried fields:

  * hackathon_id
  * team_id
  * user_id
  * post_id

* queries are efficient and do not fetch unnecessary data

---

### PAGINATION (MANDATORY)

All list endpoints must:

* enforce limit + offset
* never return unbounded results

---

### CACHING STRATEGY

Certain data can be cached:

* hackathon list
* team recommendations (short-term cache)
* user profile (optional)

Caching must be:

* time-limited
* invalidated when data changes

---

## CONCURRENCY AND DATA CONSISTENCY

The backend must handle concurrent requests safely.

---

### CRITICAL OPERATIONS

These must be atomic:

* joining a team
* updating XP
* voting

---

### APPROACH

Use:

* database constraints
* careful transaction handling (if supported)

Ensure no race conditions lead to:

* duplicate entries
* inconsistent counts

---

## DEPLOYMENT READINESS

The backend must be ready to run in a production environment.

---

### SERVER SETUP

Use:

uvicorn app.main:app

For production:

* use Gunicorn with Uvicorn workers

---

### ENVIRONMENT CONFIGURATION

All secrets must be stored in environment variables:

* Supabase URL
* Supabase key
* any API keys

---

### CORS CONFIGURATION

Restrict origins appropriately in production.

---

## FINAL SYSTEM GUARANTEES

By the end of this phase, the backend must:

* reject invalid or malicious requests reliably
* enforce strict authentication and authorization
* prevent spam and abuse through rate limiting
* maintain consistent data even under concurrent usage
* log all critical events and errors
* scale gracefully with increasing usage
* be deployable without structural changes

The system must behave predictably under both normal and adverse conditions.

There must be no undefined behavior, no silent failures, and no trust in client input.

---

END OF PHASE B5
