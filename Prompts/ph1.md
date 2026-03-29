You are building a production-grade Flutter mobile application.

This is PHASE 1: CORE FOUNDATION.

---

# 🔁 FULL PRODUCT CONTEXT (MANDATORY)

This app is a **gamified hackathon team formation platform**.

CORE PRINCIPLES:

* NOT Tinder-like
* NO swipe matching
* Teams are formed based on SKILLS and COMPATIBILITY
* Structured, serious, competitive UI (not playful)

---

# 🧱 CORE FEATURES (TO BE BUILT LATER BUT MUST BE RESPECTED NOW)

* Profile system (DEFAULT TAB)

* Hackathon discovery

* STRICT team flow:
  Hackathon → Click → THEN choose:

  * Create Team
  * Join Team (recommended ONLY)

* Community feed (Reddit-style)

* Gamification (XP, levels, badges)

* Chat (ONLY for team members)

* Notifications

---

# 🎨 UI + UX RULES (STRICT)

* Dark theme ONLY (Discord + Steam hybrid)
* No bright or childish UI
* Minimal neon accents
* Clean, structured layout

---

# ⚠️ LOADING RULE (CRITICAL)

* DO NOT use CircularProgressIndicator
* ALWAYS use skeleton loaders
* Skeletons MUST mimic final layout

---

# 🧭 NAVIGATION RULES

Bottom navigation MUST:

* Have EXACTLY 3 tabs:

  1. Community (left)
  2. Hackathons (center)
  3. Profile (right)

* NO Floating Action Button

* Swipe gestures MUST work

* Navigation must persist state

---

# 🎯 DEFAULT BEHAVIOR

* App ALWAYS opens on Profile tab (index = 2)
* After login → redirect to Profile tab

---

# 🏗️ TECH STACK

* Flutter (latest stable)
* Riverpod (state management ONLY)
* GoRouter (routing ONLY)
* Supabase (backend, later integration)

---

# ⚙️ STEP-BY-STEP IMPLEMENTATION

---

## STEP 1: PROJECT SETUP

Initialize Flutter project.

Add dependencies:

* flutter_riverpod
* go_router
* supabase_flutter
* shimmer

---

## STEP 2: DIRECTORY STRUCTURE (STRICT)

lib/
core/
theme/
constants/
utils/
services/
features/
auth/
profile/
hackathons/
teams/
chat/
community/
notifications/
gamification/
shared/
widgets/
models/
main.dart

---

## STEP 3: SUPABASE INIT

In main():

WidgetsFlutterBinding.ensureInitialized();

await Supabase.initialize(
url: "...",
anonKey: "..."
);

---

## STEP 4: ROOT APP

Use:
MaterialApp.router

Inject:

* GoRouter
* Theme

Wrap with ProviderScope

---

## STEP 5: THEME SYSTEM

Create AppTheme.darkTheme:

* background: #0D1117
* surface: #161B22
* cards: slightly lighter

Define:

* text styles
* spacing constants
* color constants

---

## STEP 6: ROUTING

Define routes:

/login
/register
/otp
/onboarding
/home

Use ShellRoute for bottom navigation

---

## STEP 7: HOME SHELL (CRITICAL)

Create HomeShell widget:

State:
int currentIndex = 2

---

## STEP 8: PAGEVIEW SYSTEM

Use PageController(initialPage: 2)

Pages:

* CommunityScreen
* HackathonScreen
* ProfileScreen

---

## STEP 9: BOTTOM NAV

Use NavigationBar:

onTap:
→ animate PageView

---

## STEP 10: SWIPE SYNC

onPageChanged:
→ update currentIndex

---

## STEP 11: SKELETON SYSTEM

Create reusable:

SkeletonBox:

* width
* height
* borderRadius

Use Shimmer effect

Create:

* ProfileSkeleton
* HackathonSkeleton
* PostSkeleton

---

# 📦 OUTPUT

* Fully running Flutter app
* Navigation + swipe working
* Dark theme applied
* Skeleton system implemented

NO business logic yet.

END OF PHASE 1
