You are continuing a production-grade FastAPI backend.

This is **PHASE B2: TEAM SYSTEM + MATCHING ENGINE (CORE OF THE APP)**.

You MUST implement everything exactly as described. Do NOT simplify. Do NOT skip validation. Do NOT expose incorrect data.

---

# 🔁 FULL PRODUCT CONTEXT (MANDATORY)

This is a **gamified hackathon team formation platform**.

---

# 🚨 CRITICAL PRODUCT RULE (NON-NEGOTIABLE)

Users MUST NEVER browse teams directly.

The ONLY valid flow:

1. User selects a hackathon
2. THEN chooses:

   * Create Team
   * Join Team

If user chooses **Join Team**:
→ Backend MUST return ONLY **recommended teams**

❌ NEVER return all teams
❌ NEVER expose raw team lists

---

# 👥 TEAM SYSTEM — FULL SPECIFICATION

---

## DATABASE ASSUMPTION (ALREADY EXISTS)

Tables:

### teams

* id
* hackathon_id
* creator_id
* name
* description
* required_skills (jsonb)
* max_members
* created_at

---

### team_members

* id
* team_id
* user_id
* role
* status ("pending", "accepted", "rejected")

---

---

# 🧠 MATCHING ENGINE (CORE LOGIC)

This is the MOST IMPORTANT feature.

---

## ENDPOINT

POST /teams/recommendations

---

## INPUT

{
hackathon_id: string
}

User is derived from JWT (DO NOT accept user_id in body)

---

## STEP-BY-STEP LOGIC

### STEP 1: GET CURRENT USER

* Extract user_id from JWT

---

### STEP 2: VALIDATE USER STATE

Check:

* Is user already in an ACCEPTED team for this hackathon?

If YES:
→ return error:
"You are already in a team for this hackathon"

---

### STEP 3: FETCH USER PROFILE

Get:

* skills
* experience_level

---

### STEP 4: FETCH TEAMS

Query:

* all teams for hackathon_id

---

### STEP 5: FILTER TEAMS

REMOVE teams where:

* team is FULL
* user already requested (pending)
* user already rejected
* team creator is the user

---

### STEP 6: FETCH TEAM MEMBERS

For each team:

* get accepted members
* derive:

  * current skills in team
  * average experience

---

### STEP 7: CALCULATE MATCH SCORE

---

#### 1. SKILL MATCH

matching_skills = intersection(user.skills, team.required_skills)

skill_score = (len(matching_skills) / len(team.required_skills)) * 100

---

#### 2. ROLE FIT

missing_roles = team.required_skills - current_team_skills

If user fills missing_roles:
role_score = 100
Else:
role_score = 40

---

#### 3. EXPERIENCE MATCH

Map:

* beginner = 1
* intermediate = 2
* advanced = 3

experience_score = 100 - abs(user_exp - team_avg_exp) * 30

Clamp:
0 ≤ score ≤ 100

---

### FINAL SCORE

final_score =
(skill_score * 0.5) +
(role_score * 0.3) +
(experience_score * 0.2)

---

### STEP 8: GENERATE EXPLANATION

MANDATORY:

"You match X/Y required skills and fill a missing [role]. Your experience aligns well with the team."

---

### STEP 9: SORT

Sort teams by:
final_score DESC

---

### STEP 10: RETURN RESPONSE

[
{
team_id,
team_name,
members_count,
compatibility_score,
explanation
}
]

---

# 👥 CREATE TEAM ENDPOINT

POST /teams/create

---

## INPUT

{
name,
description,
required_skills,
max_members
}

---

## VALIDATIONS

* user NOT already in a team for this hackathon
* required_skills NOT empty

---

## LOGIC

1. Insert into teams
2. Insert creator into team_members:

   * role = "leader"
   * status = "accepted"

---

# 🤝 JOIN TEAM (REQUEST SYSTEM)

POST /teams/join

---

## INPUT

{
team_id
}

---

## VALIDATIONS

* user NOT already in a team
* user NOT already requested
* team NOT full

---

## LOGIC

Insert into team_members:

* status = "pending"

---

## SIDE EFFECT

→ Create notification for team leader

---

# ✅ ACCEPT REQUEST

POST /teams/accept

---

## INPUT

{
team_member_id
}

---

## VALIDATIONS

* requester MUST be team leader

---

## LOGIC

* update status → accepted

---

# ❌ REJECT REQUEST

POST /teams/reject

---

## INPUT

{
team_member_id
}

---

## LOGIC

* update status → rejected

---

# 🔐 SECURITY RULES

* ALL endpoints require authentication
* Use get_current_user dependency
* DO NOT accept user_id from client

---

# ⚠️ EDGE CASES (MUST HANDLE)

* user already in team
* team full
* duplicate request
* invalid team_id

---

# 📦 OUTPUT REQUIREMENTS

You MUST generate:

1. team.py router
2. schemas:

   * CreateTeamRequest
   * JoinTeamRequest
   * RecommendationResponse
3. service layer:

   * TeamService
   * MatchingService
4. all validation logic
5. DB queries using Supabase client

---

# 🚨 FINAL RULES

* DO NOT expose raw team list anywhere
* DO NOT skip explanation generation
* DO NOT skip validation

---

END OF PHASE B2
