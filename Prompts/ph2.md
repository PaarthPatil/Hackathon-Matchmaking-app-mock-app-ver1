You are continuing the same app.

This is PHASE 2: AUTH + PROFILE SYSTEM.

---

# 🔁 FULL PRODUCT CONTEXT

* Profile tab is DEFAULT entry point
* Users can SKIP onboarding
* Profile can be incomplete
* App MUST still function with incomplete data

---

# 🔐 AUTH FLOW (EXACT)

---

## LOGIN SCREEN

UI:

* TextField (email)
* TextField (password, obscure)
* Login button
* Switch to Register button

Validation:

* email format
* password not empty

---

## LOGIN LOGIC

onPressed:

1. set loading = true
2. call authRepository.signIn()
3. if success:
   → navigate /home
4. if error:
   → show SnackBar

---

## REGISTER SCREEN

Fields:

* email
* password

on submit:
→ signUp()
→ navigate to OTP

---

## OTP SCREEN

UI:

* 6 digit input

on submit:
→ verifyOtp()

success:
→ onboarding OR home

---

# 🧭 ONBOARDING FLOW (MULTI STEP)

---

Step 1:

* Name
* Username

Step 2:

* Skills (chips multi-select)

Step 3:

* Tech stack

Step 4:

* Links (GitHub, LinkedIn, Portfolio)

Step 5:

* Roles + availability

Each step:

* Next button
* Skip button

---

# 👤 PROFILE SYSTEM

---

## VIEW MODE

Use ListView:

Sections:

1. Header:

   * Avatar
   * Name
   * Username
   * Bio
   * XP + Level badge

2. Skills (chips)

3. Tech stack

4. Links

5. Stats:

   * hackathons joined
   * wins
   * teams joined

6. Achievements (grid)

7. Preferences:

   * roles
   * availability
   * looking_for_team toggle

---

## EDIT MODE

* Use TextEditingController
* Editable fields
* Save → updateProfile()
* Cancel → revert

---

# 🖼️ AVATAR UPLOAD

* Pick image
* Upload to Supabase Storage
* Save URL in profile

---

# 🧠 STATE MANAGEMENT

ProfileState:

* loading
* data
* error

---

# 🧊 SKELETON

Show ProfileSkeleton until data loads

---

# 📦 OUTPUT

* Full auth flow
* Profile screen (view/edit)
* Onboarding (skippable)
* Supabase auth integrated

END OF PHASE 2
