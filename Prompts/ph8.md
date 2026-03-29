This is PHASE 8: REALTIME + DATA FLOW.

---

# CHAT FLOW

1. User opens team screen

2. App subscribes:
   supabase.from('messages').stream()

3. Filter by team_id

4. On new message:

   * append to list
   * scroll to bottom

---

# SEND MESSAGE FLOW

1. User types message
2. Insert into messages table
3. Supabase realtime pushes update

---

# PERFORMANCE RULES

* Use pagination:

  * hackathons → limit 10
  * posts → limit 10

* Use lazy loading

* Cache profile data locally

---

# RIVERPOD STRUCTURE

Providers:

* authProvider
* profileProvider
* hackathonProvider
* teamProvider
* chatProvider

---

# UI RULE

* ALWAYS show skeleton before data loads
* NEVER block UI

---

END OF PHASE 8
