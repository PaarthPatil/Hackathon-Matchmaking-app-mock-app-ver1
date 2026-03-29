This is PHASE 7: TEAM MATCHING ENGINE (NO ASSUMPTIONS).

---

# GOAL

Return ranked list of teams with:

* compatibility_score
* explanation string

---

# STEP 1: INPUT STRUCTURES

User:

* skills: List<String>
* experience_level: String

Team:

* required_skills: List<String>
* members: List<User>
* max_members: int

---

# STEP 2: CALCULATIONS

## Skill Match:

skill_match = (matched_skills / required_skills) * 100

---

## Missing Role Fit:

missing_roles = required_skills - team_current_skills

if user fills missing_roles:
role_score = 100
else:
role_score = 40

---

## Experience Match:

Map:

* beginner = 1
* intermediate = 2
* advanced = 3

Compute:
experience_score = 100 - abs(user_exp - team_avg_exp) * 30

Clamp between 0–100

---

# STEP 3: FINAL SCORE

final_score =
(skill_match * 0.5) +
(role_score * 0.3) +
(experience_score * 0.2)

---

# STEP 4: EXPLANATION STRING

Generate:

"You match X/Y required skills and help fill [missing roles]. Your experience level fits well with the team."

---

# STEP 5: SORT

Sort teams by final_score DESC

---

# STEP 6: OUTPUT FORMAT

List:

* team_id
* compatibility_score
* explanation

---

# IMPLEMENTATION

* Create Dart service class:
  TeamMatchingService

* Function:
  List<MatchedTeam> getMatches(User user, List<Team> teams)

---

END OF PHASE 7
