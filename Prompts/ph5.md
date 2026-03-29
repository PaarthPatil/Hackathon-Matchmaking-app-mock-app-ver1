This is PHASE 5.

---

# CHAT SCREEN

Use StreamBuilder:

stream:
supabase.from('messages').stream()

---

# MESSAGE UI

Bubble:

* left (others)
* right (user)

---

# SEND MESSAGE

TextField + send button

on send:
→ insert message

---

# NOTIFICATIONS SCREEN

ListView:

Item:

* message text
* timestamp

---

# MARK AS READ

onTap:
→ update notification

---

# EDGE CONDITIONS

* if no chat → show placeholder
* if no notifications → show placeholder

---

# OUTPUT

* Chat realtime working
* Notifications working

END PHASE 5
This is PHASE 5: CHAT + NOTIFICATIONS.

---

# 🔁 FULL RULE

Chat MUST ONLY exist if:

* user is in team
* hackathon active

---

# 💬 CHAT UI

Use StreamBuilder:

stream:
supabase.from('messages').stream()

---

# MESSAGE UI

* left bubble (others)
* right bubble (user)

---

# SEND MESSAGE

TextField + send button

on send:
→ insert message

---

# 🔔 NOTIFICATIONS

Types:

* team invite
* join request
* hackathon reminder
* likes/comments

---

# NOTIFICATION SCREEN

ListView:

* message
* timestamp
* unread highlight

---

# MARK AS READ

onTap:
→ update notification

---

# 📭 EMPTY STATES

* no chat → show placeholder
* no notifications → show placeholder

---

# 📦 OUTPUT

* Chat working realtime
* Notifications working

END OF PHASE 5
