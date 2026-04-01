You are continuing development of a production-grade FastAPI backend for a gamified hackathon team formation platform.

This phase defines the **social layer and engagement engine** of the application. It includes the community posting system, voting logic, comment handling, gamification (XP and levels), and the notification system that ties all user actions together.

This is not a simple CRUD implementation. Every action must be validated, controlled, and connected to the rest of the system. The goal is to create a system that is fair, resistant to spam, and capable of scaling without breaking logical consistency.

---

## SYSTEM CONTEXT

The platform is not only about forming teams — it is also about learning, sharing, and showcasing progress. The community system allows users to:

* share hackathon experiences
* post achievements
* discuss strategies
* announce opportunities

At the same time, the system must avoid becoming noisy, spammy, or low-quality. Therefore, all interactions must be controlled and meaningful.

Additionally, every meaningful action contributes to a **gamification layer**, which reinforces engagement through XP, levels, and achievements.

---

## COMMUNITY POST SYSTEM

The post system is a structured feed similar to Reddit, but without chaos.

A post is always tied to a user and represents a meaningful contribution. The backend must enforce that posts are intentional and not spam.

### Post Creation Behavior

When a user creates a post:

1. The backend must extract the user identity from JWT.

2. The content must be validated:

   * content must not be empty
   * content length must be within reasonable bounds
   * optional image URL must be valid if provided

3. The backend stores the post with:

   * user_id
   * content
   * optional image_url
   * created_at timestamp
   * upvotes = 0
   * downvotes = 0

4. The system may trigger gamification updates (defined later).

Posts must not be created anonymously. There is no concept of anonymous posting.

---

## POST RETRIEVAL (FEED)

The feed must be returned in a controlled, paginated format.

The backend must support:

* pagination using limit and offset
* sorting:

  * latest (by created_at)
  * trending (based on vote score)

Trending logic should consider:

* upvotes
* downvotes
* recency (optional weighting)

The backend must NOT return unbounded lists.

---

## VOTING SYSTEM (CRITICAL ANTI-SPAM DESIGN)

Voting is one of the most sensitive parts of the system and must be implemented with strict guarantees.

Each user can:

* upvote a post
* downvote a post

But:

* a user can vote only ONCE per post
* a user cannot spam votes
* switching vote is allowed (optional but recommended)

### Voting Behavior

When a user votes:

1. Extract user_id from JWT
2. Check if user has already voted on this post

If NO previous vote:

* insert vote record
* increment upvotes OR downvotes

If vote exists:

* either:

  * reject duplicate vote
    OR
  * allow switching (recommended)

If switching:

* adjust counters accordingly

---

### REQUIRED DATABASE DESIGN (IMPORTANT)

You MUST maintain a separate table:

post_votes:

* user_id
* post_id
* vote_type ("upvote" or "downvote")

This table is the source of truth.

Do NOT rely only on counters.

---

## COMMENT SYSTEM

Comments allow discussion under posts.

### Behavior

When a user comments:

1. Validate:

   * content not empty
2. Store:

   * post_id
   * user_id
   * content
   * created_at

Comments must be linked strictly to posts.

---

### Retrieval

* Comments must be fetched per post
* Must support pagination
* Must return user info alongside comment

---

## GAMIFICATION SYSTEM (CORE ENGAGEMENT ENGINE)

Gamification must be handled entirely in backend. The frontend must never calculate XP.

---

### XP SYSTEM DESIGN

XP is awarded based on meaningful actions:

* Completing profile → +50 XP
* Joining a team (accepted) → +30 XP
* Creating a post → +10 XP

XP must be updated immediately after the action is confirmed.

---

### LEVEL SYSTEM

Level is derived from XP using a deterministic formula:

level = floor(xp / 100)

This calculation must always be consistent and must NOT be stored independently unless necessary for performance.

---

### UPDATE FLOW

After every XP-triggering event:

1. Fetch current user XP
2. Add new XP
3. Recalculate level
4. Update profile

---

### CONSISTENCY RULE

XP updates must be atomic.
There must be no race conditions where XP is lost or double-counted.

---

## NOTIFICATION SYSTEM (EVENT-DRIVEN)

Notifications are not manually created — they are triggered by events.

---

### EVENTS THAT TRIGGER NOTIFICATIONS

* User sends team join request
* Team leader accepts request
* Team leader rejects request
* Someone likes your post
* Someone comments on your post

---

### CREATION FLOW

When an event occurs:

1. Determine target user
2. Generate message
3. Insert into notifications table

---

### NOTIFICATION STRUCTURE

Each notification must contain:

* id
* user_id (recipient)
* type (string)
* message (string)
* read (boolean, default false)
* created_at

---

## RETRIEVAL

Users must be able to:

* fetch all notifications
* fetch unread notifications
* mark notifications as read

---

## INTEGRATION WITH OTHER SYSTEMS

This phase must integrate with:

* Team system (join request notifications)
* Profile system (XP updates)
* Community system (post interactions)

No system should operate in isolation.

---

## SECURITY RULES

* All endpoints require authentication
* user_id must always come from JWT
* never trust client input for identity

---

## ERROR HANDLING

Every endpoint must:

* validate inputs
* catch exceptions
* return structured error responses

---

## FINAL EXPECTATION

By the end of this phase, the backend must:

* support a structured, non-spammy community feed
* enforce strict voting rules with no duplication
* allow meaningful discussions via comments
* maintain a consistent XP and level system
* generate notifications automatically from events
* integrate all systems cleanly without breaking constraints

There must be no ambiguity in how actions are processed. Every input must produce a predictable and validated output.

---

END OF PHASE B4
