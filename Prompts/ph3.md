This is PHASE 3: HACKATHONS + TEAM SYSTEM.

---

# 🔁 FULL PRODUCT RULE

Users MUST NEVER see teams globally.

ONLY FLOW:

Hackathon → Click → THEN:

* Create Team
* Join Team (recommended ONLY)

---

# 🏆 HACKATHON LIST

Use ListView.builder

Each card:

* title
* organizer
* date
* mode
* tags

---

# 📄 HACKATHON DETAIL

Sections:

* description
* rules
* timeline
* location
* prize
* team size

---

# 🚨 TEAM ENTRY POINT

At bottom:

Column:

* ElevatedButton("Create Team")
* OutlinedButton("Join Team")

---

# 👥 CREATE TEAM

Fields:

* team name
* team size
* required skills
* commitment level
* availability
* description

Validation required

---

# 🤝 JOIN TEAM (CORE FEATURE)

User sees ONLY recommended teams.

Each card MUST include:

* team name
* members count
* missing roles
* compatibility %
* explanation text

---

# 🧠 MATCHING INTEGRATION

Call matching service BEFORE showing list

---

# 📄 TEAM DETAIL

* members
* roles
* skills

---

# ⚠️ STRICT RULE

No screen should show all teams directly.

---

# 📦 OUTPUT

* Hackathon list + detail
* Team creation flow
* Team recommendation flow

END OF PHASE 3
