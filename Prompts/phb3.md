You are building a production-grade backend using FastAPI for a Flutter application that enables structured, skill-based hackathon team formation. This phase focuses entirely on designing and implementing the hackathon lifecycle and the administrative control system that governs it.

This is not a CRUD system. It is a controlled, moderated, multi-role system where hackathons are not freely created by users but are instead curated through a request-and-approval pipeline. You must implement this with strict enforcement of permissions, state transitions, and data validation. No part of this system should be left ambiguous.

---

## SYSTEM CONTEXT AND INTENT

The hackathon system is the **entry point of all meaningful activity in the application**. Every team, every collaboration, every recommendation, and every interaction originates from a hackathon entity. Therefore, the integrity of hackathon data must be preserved at all times.

Users do not create hackathons directly. This is a deliberate design decision to:

* prevent spam
* ensure quality
* maintain trust in the platform

Instead, users submit **hackathon requests**, which are then reviewed and approved (or rejected) by administrators. Only administrators have the authority to create actual hackathon records that become visible in the system.

This creates two parallel but connected systems:

1. **Hackathon Request System (user-driven)**
2. **Hackathon Management System (admin-controlled)**

Both must be implemented in this phase.

---

## ROLE SYSTEM INTEGRATION

This phase depends on a strict role system already defined in the backend:

* Every user has a role stored in the `profiles` table
* Valid roles are:

  * `"user"`
  * `"admin"`

All administrative endpoints must enforce role validation. At no point should a non-admin user be able to:

* create hackathons directly
* edit hackathons
* delete hackathons
* approve requests

This must be enforced through dependency injection using a function such as `get_current_admin`, which internally:

1. Extracts the user from JWT
2. Fetches their profile
3. Verifies role == "admin"
4. Rejects otherwise with HTTP 403

This logic must be reused consistently across all admin endpoints.

---

## HACKATHON REQUEST SYSTEM (USER SIDE)

The hackathon request system is the only entry point for users to suggest new hackathons.

When a user cannot find a hackathon they are looking for, they should be able to submit a structured request that contains enough information for an admin to evaluate it.

### Behavior

A user initiates a POST request to the backend to submit a hackathon request. The backend must:

* Extract the user identity from JWT
* Validate all input fields strictly
* Store the request in a dedicated table (`hackathon_requests`)
* Associate the request with the requesting user

### Required Fields

A hackathon request must contain:

* title (string, required)
* description (string, required)
* organizer (string, optional but recommended)
* expected_start_date (timestamp or string)
* expected_end_date (timestamp or string)
* mode (online/offline/hybrid)
* location (optional if online)
* tags (array of strings, optional)
* any additional metadata (optional)

### Validation Rules

* title must not be empty
* description must not be empty
* duplicate requests (same title + organizer) should be discouraged or flagged
* input must be sanitized

### Storage

Each request must be stored with:

* id (UUID)
* user_id
* status ("pending", "approved", "rejected")
* created_at timestamp

All new requests must default to `"pending"`.

---

## ADMIN REVIEW SYSTEM

Admins must be able to retrieve and review all hackathon requests.

### Retrieval

An admin-only endpoint must return:

* all hackathon requests
* sorted by created_at descending
* optionally filtered by status

### Review Actions

Admins can take two actions:

1. **Approve request**
2. **Reject request**

---

### APPROVAL FLOW

When an admin approves a request:

1. The system must:

   * update request status → "approved"

2. The system must then:

   * create a new record in the `hackathons` table

3. The hackathon record must be constructed using:

   * data from the request
   * additional admin-specified details if needed

4. The system must ensure:

   * no duplicate hackathons are created

5. The system may optionally:

   * notify the user who submitted the request

---

### REJECTION FLOW

When an admin rejects a request:

* update request status → "rejected"
* optionally store a rejection reason (optional but recommended)

---

## HACKATHON ENTITY (CORE OBJECT)

Once approved, hackathons exist as first-class entities in the system.

These are what users see in the hackathon tab in the frontend.

### Required Fields

Each hackathon must include:

* id
* title
* description
* organizer
* start_date
* end_date
* mode
* location
* prize_pool (optional)
* max_team_size
* tags (json array)
* created_at

---

## HACKATHON VISIBILITY RULES

* All users can view hackathons
* Hackathons must be returned in paginated form
* No hackathon should be partially visible (data must be complete)

---

## ADMIN CONTROL OVER HACKATHONS

Admins must be able to:

### CREATE

Even outside of request approval, admins must be able to manually create hackathons.

### UPDATE

Admins can modify:

* dates
* description
* prize pool
* tags
* team size

Validation must ensure:

* no invalid date ranges
* no empty required fields

### DELETE

Admins can delete hackathons.

However, deletion must consider:

* existing teams
* existing members

Recommended approach:

* soft delete OR
* prevent deletion if active teams exist

---

## RELATIONSHIP WITH TEAM SYSTEM

This phase must enforce a critical constraint:

Teams are always tied to a hackathon.

Therefore:

* Every team must reference a valid hackathon_id
* If a hackathon does not exist → teams cannot exist

---

## API DESIGN (STRICT BEHAVIOR)

You must implement the following endpoints with full validation and security:

### USER SIDE

* POST /hackathons/request
  → creates a hackathon request

---

### ADMIN SIDE

* GET /admin/hackathon-requests
  → fetch all requests

* POST /admin/hackathon-requests/{id}/approve
  → approve + create hackathon

* POST /admin/hackathon-requests/{id}/reject
  → reject request

* POST /admin/hackathons/create
  → manual creation

* PUT /admin/hackathons/{id}
  → update hackathon

* DELETE /admin/hackathons/{id}
  → delete hackathon

---

### PUBLIC

* GET /hackathons
  → paginated list

* GET /hackathons/{id}
  → full detail

---

## ERROR HANDLING

Every operation must:

* validate inputs
* catch exceptions
* return structured responses

Example:

{
"error": "Hackathon not found"
}

---

## FINAL EXPECTATION

By the end of this phase, the backend must have:

* a fully working hackathon request system
* a complete admin moderation system
* strict role-based access control
* a clean, validated hackathon data model
* endpoints that are safe, predictable, and production-ready

Nothing should be left undefined. No logic should be implied. Every action must have a clear validation path and outcome.

---

END OF PHASE B3
