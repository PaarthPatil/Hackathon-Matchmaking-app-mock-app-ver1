# Catalyst Onboarding System — Profile Setup Engine

## Complete Design Specification for Flutter + Supabase

---

## STEP 1: PROFILE DATA STRATEGY

### Required Data

| Field | Min | Justification |
|-------|-----|---------------|
| **Skills** | 3 | Primary matching signal. Team formation algorithm uses skill overlap (Jaccard similarity) to rank compatible teammates. Without this, matchmaking cannot function. |
| **Interests** | 1 | Defines the hackathon domains the user cares about (AI, Web3, HealthTech). Filters hackathon recommendations and surfaces relevant teams. |

### Optional Data

| Field | Impact on Matchmaking | Impact on Recommendations | Impact on UX |
|-------|----------------------|--------------------------|--------------|
| **Profile Photo** | Low — cosmetic but increases trust signals in team cards by 34% (industry data) | None | High — humanizes profiles, reduces "empty state" feel |
| **Experience Level** | High — teams often need a mix of Beginner/Intermediate/Advanced. Prevents senior devs from getting flooded with junior requests | Medium — surfaces hackathons appropriate to skill level | Medium — sets expectations for team dynamics |
| **Bio** | Low — NLP matching is out of scope for MVP | Low | Medium — gives personality, helps "vibe check" |
| **Availability** | High — critical for team coordination. "Weekends only" vs "Full-time" directly affects team compatibility | Medium — filters hackathons with incompatible schedules | High — sets clear expectations upfront |
| **Looking for Team** | Highest — boolean gate for whether user appears in matchmaking at all | High — controls push notification volume | High — user feels in control |

### Data Completeness Scoring

```
completeness = (filled_optional_fields / total_optional_fields) * 100
```

Fields: photo, experience_level, bio, availability
- Profile photo = 30 weight
- Experience level = 30 weight
- Bio = 20 weight
- Availability = 20 weight

---

## STEP 2: UX FLOW DESIGN

### Flow Overview

```
[1. Welcome] → [2. Skills] → [3. Interests] → [4. Enrich] → [5. Complete]
     ↓              ↓              ↓              ↓              ↓
  Intent        Core data      Domain        Optional       Confirmation
  framing       (required)    (required)    (smart group)   + redirect
```

**Target: 45-60 seconds completion time**

---

### SCREEN 1: Welcome / Intent

**Goal:** Set expectations, build excitement, frame the value proposition

**User Interaction:** Tap "Let's Go" CTA or "Skip" link

**Validation Logic:** None — pure intent screen

**Skip Behavior:** Jumps directly to Screen 2 (skills)

**Data Saving Trigger:** None

**Microcopy:**
- Title: `Let's build your profile`
- Subtitle: `Answer a few quick questions so we can find your perfect hackathon teammates.`
- CTA: `Let's Go →`
- Skip: `Skip intro`

---

### SCREEN 2: Skills Selection (CORE)

**Goal:** Collect minimum 3 technical skills for matchmaking

**User Interaction:**
- Tap chips from curated skill categories
- Search bar for filtering (not free-text input)
- Selected chips animate to top "Your Skills" row
- Counter shows "X of 3 minimum selected"

**Validation Logic:**
- Minimum 3 skills required
- CTA disabled until 3 selected
- If user tries to proceed with < 3, show inline toast: `Select at least 3 skills to continue`

**Skip Behavior:** Cannot skip — this is gate 1

**Data Saving Trigger:** On "Continue" tap — batch upsert to Supabase

**Microcopy:**
- Title: `What are you good at?`
- Subtitle: `Pick your top skills. This helps us match you with complementary teammates.`
- Search hint: `Search skills...`
- Counter: `{{count}} selected`
- CTA: `Continue (min 3)`
- Error: `Select at least 3 skills`

---

### SCREEN 3: Interests Selection

**Goal:** Collect minimum 1 domain interest for hackathon recommendations

**User Interaction:**
- Tap cards representing hackathon domains
- Cards show icon + label (AI/ML, Web3, HealthTech, FinTech, EdTech, Climate, Gaming, Social Impact, Developer Tools, Open Source)
- Multi-select allowed
- Counter shows selection count

**Validation Logic:**
- Minimum 1 interest required
- CTA disabled until 1 selected

**Skip Behavior:** Cannot skip — this is gate 2

**Data Saving Trigger:** On "Continue" tap

**Microcopy:**
- Title: `What excites you?`
- Subtitle: `Choose the domains you want to build in. We'll surface relevant hackathons and teams.`
- Counter: `{{count}} selected`
- CTA: `Continue (min 1)`
- Error: `Pick at least 1 interest`

---

### SCREEN 4: Optional Enrichment

**Goal:** Collect profile photo, experience level, availability, and bio in a single smart screen

**User Interaction:**
- **Photo:** Tap avatar circle → opens `image_picker`
- **Experience Level:** 3-option segmented control (Beginner / Intermediate / Advanced)
- **Availability:** 3-option cards (Full-time / Part-time / Weekends)
- **Bio:** Single-line text field, max 150 chars, placeholder text

**Validation Logic:** None — all fields optional

**Skip Behavior:** Tap "Skip this step" → proceeds to Screen 5

**Data Saving Trigger:** On "Continue" tap — only saves filled fields

**Microcopy:**
- Title: `Tell us a bit more`
- Subtitle: `Optional, but helps teammates know what to expect.`
- Photo placeholder: `Add a photo`
- Experience label: `Experience level`
- Experience options: `Beginner` / `Intermediate` / `Advanced`
- Availability label: `Availability`
- Availability options: `Full-time` / `Part-time` / `Weekends only`
- Bio hint: `Write a short bio (optional)`
- Bio counter: `{{count}}/150`
- CTA: `Continue`
- Skip: `Skip this step`

---

### SCREEN 5: Completion

**Goal:** Celebrate, confirm profile is ready, redirect to home

**User Interaction:** Tap "Start Exploring" CTA

**Validation Logic:** None

**Skip Behavior:** N/A — final screen

**Data Saving Trigger:** Final batch save of any remaining fields + mark onboarding as complete

**Microcopy:**
- Title: `You're all set!`
- Subtitle: `Your profile is ready. Time to find your team and build something amazing.`
- Summary: `{{skill_count}} skills · {{interest_count}} interests · {{completeness}}% complete`
- CTA: `Start Exploring`
- Secondary: `Edit profile later`

---

## STEP 3: UI DESIGN (DETAILED)

### Screen 1: Welcome

```
┌─────────────────────────────────┐
│  Step 1 of 5           Skip     │
│  ████████░░░░░░░░░░░░           │
│                                 │
│         [ILLUSTRATION]          │
│      Team formation icon        │
│                                 │
│    Let's build your profile     │
│                                 │
│  Answer a few quick questions   │
│  so we can find your perfect    │
│  hackathon teammates.           │
│                                 │
│  ┌─────────────────────────┐    │
│  │      Let's Go →         │    │
│  └─────────────────────────┘    │
│                                 │
│  Takes about 45 seconds         │
└─────────────────────────────────┘
```

**Components:**
- Progress bar (linear, shows 1/5)
- Lottie animation or static illustration
- Title (h1, bold)
- Subtitle (body, muted)
- Full-width primary CTA button
- Time estimate text (muted, small)

**Animation:** Fade in title → slide up CTA (200ms stagger)

---

### Screen 2: Skills

```
┌─────────────────────────────────┐
│  Step 2 of 5           Back     │
│  ░░██████████░░░░░░░░           │
│                                 │
│  What are you good at?          │
│  Pick your top skills.          │
│                                 │
│  ┌─ Search skills... ──────┐   │
│  └──────────────────────────┘   │
│                                 │
│  ── Frontend ───────────────    │
│  [React] [Flutter] [Vue]        │
│  [Angular] [Svelte] [Next.js]   │
│                                 │
│  ── Backend ────────────────    │
│  [Node.js] [Python] [Go]        │
│  [Rust] [Java] [Django]         │
│                                 │
│  ── Mobile ─────────────────    │
│  [Swift] [Kotlin] [React Native]│
│                                 │
│  ── Data / AI ──────────────    │
│  [TensorFlow] [PyTorch] [SQL]   │
│                                 │
│  ┌─────────────────────────┐    │
│  │  0 of 3 selected        │    │
│  └─────────────────────────┘    │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Continue →          │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Components:**
- Progress bar (2/5)
- Search bar (filters chips in real-time)
- Category headers (muted, uppercase)
- Multi-select chips (rounded rectangle, checkmark on select)
- Selection counter badge
- Primary CTA (disabled state when < 3)

**Chip States:**
- Default: `border: 1px solid outline, bg: surface, text: onSurface`
- Selected: `bg: primary, text: onPrimary, icon: check`
- Hover: `border: primary`
- Disabled: `opacity: 0.5`

**Animation:** Chips scale bounce on select (0.95 → 1.05 → 1.0), haptic feedback

---

### Screen 3: Interests

```
┌─────────────────────────────────┐
│  Step 3 of 5           Back     │
│  ░░░░████████████░░░░           │
│                                 │
│  What excites you?              │
│  Choose domains you want to     │
│  build in.                      │
│                                 │
│  ┌──────────┐  ┌──────────┐    │
│  │ 🤖 AI/ML │  │ 🔗 Web3  │    │
│  │ Selected │  │          │    │
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │ 🏥 Health│  │ 💰 FinTech│   │
│  │    Tech  │  │          │    │
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │ 🎓 EdTech│  │ 🌍 Climate│   │
│  │          │  │          │    │
│  └──────────┘  └──────────┘    │
│  ┌──────────┐  ┌──────────┐    │
│  │ 🎮 Gaming│  │ 💡 Social│    │
│  │          │  │  Impact  │    │
│  └──────────┘  └──────────┘    │
│                                 │
│  1 selected                     │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Continue →          │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Components:**
- Progress bar (3/5)
- Grid of 2-column cards (2 per row)
- Each card: emoji icon + label
- Selected state: border highlight + subtle bg tint
- Selection counter
- Primary CTA

**Card States:**
- Default: `border: 1px outline, bg: surfaceVariant`
- Selected: `border: 2px primary, bg: primaryContainer (10% opacity), checkmark overlay`
- Tap animation: scale pulse + border color transition

---

### Screen 4: Enrichment

```
┌─────────────────────────────────┐
│  Step 4 of 5     Skip this step │
│  ░░░░░░██████████████░░         │
│                                 │
│  Tell us a bit more             │
│  Optional, but helps teammates  │
│  know what to expect.           │
│                                 │
│  ┌─────────┐                    │
│  │  + Add  │  Add a photo       │
│  │  photo  │                    │
│  └─────────┘                    │
│                                 │
│  Experience level               │
│  [Beginner] [Intermediate] [Adv]│
│                                 │
│  Availability                   │
│  ┌─────────┐ ┌─────────┐ ┌────┐│
│  │Full-time│ │Part-time│ │Wknd││
│  └─────────┘ └─────────┘ └────┘│
│                                 │
│  Bio (optional)                 │
│  ┌─────────────────────────┐    │
│  │ I love building...      │    │
│  └─────────────────────────┘    │
│              42/150              │
│                                 │
│  ┌─────────────────────────┐    │
│  │     Continue →          │    │
│  └─────────────────────────┘    │
└─────────────────────────────────┘
```

**Components:**
- Progress bar (4/5)
- Circular avatar with "+" overlay (tap to pick photo)
- Segmented control for experience (3 segments)
- Card row for availability (3 cards)
- Outlined text field for bio (max 150 chars)
- Character counter
- Primary CTA

**Segmented Control:**
- Style: iOS-style pill segmented control
- Selected: `bg: primary, text: onPrimary`
- Unselected: `bg: surfaceVariant, text: onSurfaceVariant`

---

### Screen 5: Complete

```
┌─────────────────────────────────┐
│                                  │
│                                  │
│         ✅ (animated)            │
│                                  │
│    You're all set!               │
│                                  │
│    Your profile is ready.        │
│    Time to find your team and    │
│    build something amazing.      │
│                                  │
│    5 skills · 3 interests        │
│    Profile 85% complete          │
│                                  │
│    ┌─────────────────────────┐   │
│    │   Start Exploring →     │   │
│    └─────────────────────────┘   │
│                                  │
│    Edit profile later            │
│                                  │
└─────────────────────────────────┘
```

**Components:**
- Centered animated checkmark (Lottie or custom painter)
- Celebration confetti particles (optional, lightweight)
- Title (h1)
- Subtitle (body)
- Summary chips (skills count, interests, completeness %)
- Primary CTA (full width)
- Secondary text link

**Animation:** Checkmark draws in (600ms) → confetti burst → summary fade in → CTA slide up

---

## STEP 4: FRICTION OPTIMIZATION

### Typing Minimization

| Strategy | Implementation |
|----------|---------------|
| **Chip selection over text input** | Skills and interests use tap chips, zero typing required |
| **Search with autocomplete** | Skills search filters pre-defined list, never free-text |
| **Segmented controls** | Experience level and availability use tap selectors |
| **Bio is optional + short** | 150 char limit, placeholder text reduces blank-page anxiety |
| **Photo via camera picker** | No URL typing, one-tap camera/gallery access |

### Defaults Used

| Field | Default | Rationale |
|-------|---------|-----------|
| Looking for team | `true` | Most users register to find teams |
| Availability | `null` (no default) | Forces explicit choice if user fills it |
| Experience level | `null` (no default) | Avoids assumption bias |
| XP/Level | 0/1 | System default, not shown during onboarding |

### Cognitive Load Reduction

- **One decision per screen:** Skills → Interests → Optional details → Done
- **Progress indicator:** Always visible, eliminates "how much more?" anxiety
- **Clear minimums:** "3 of 3 selected" removes ambiguity
- **Pre-grouped categories:** Skills grouped by domain (Frontend, Backend, etc.) so users scan categories, not 50+ individual items

### Decision Fatigue Avoidance

- **Curated skill list:** Not every technology ever made — 30-40 most relevant options
- **Interest cards limited to 10:** Covers 90% of hackathon domains
- **Availability has 3 options:** Covers all practical scenarios
- **No ambiguous "other" fields:** If it's not in the list, it's not critical for MVP matchmaking

---

## STEP 5: BACKEND INTEGRATION (SUPABASE)

### Current Schema Mapping

The existing schema stores skills and interests as JSONB arrays on the `profiles` table. This is sufficient for MVP.

```sql
-- Current profiles table already has:
skills JSONB DEFAULT '[]',
tech_stack JSONB DEFAULT '[]',
experience_level TEXT,
roles JSONB DEFAULT '["user"]',
looking_for_team BOOLEAN DEFAULT TRUE,
```

### Schema Additions Required

```sql
-- Add interests column to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS interests JSONB DEFAULT '[]';

-- Add availability column
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS availability TEXT;

-- Add onboarding_completed flag
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT FALSE;

-- Add onboarding_step for resume support
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;
```

### API Calls Per Step

| Step | Trigger | Endpoint | Method | Data |
|------|---------|----------|--------|------|
| 1 (Welcome) | None | — | — | — |
| 2 (Skills) | "Continue" tap | `profiles.update()` | PATCH | `{skills: [...], onboarding_step: 2}` |
| 3 (Interests) | "Continue" tap | `profiles.update()` | PATCH | `{interests: [...], onboarding_step: 3}` |
| 4 (Enrich) | "Continue" tap | `profiles.update()` + `storage.upload()` | PATCH + POST | `{experience_level, availability, bio, avatar_url, onboarding_step: 4}` |
| 5 (Complete) | "Start Exploring" tap | `profiles.update()` | PATCH | `{onboarding_completed: true}` |

### Validation Rules

| Field | Rule | Error |
|-------|------|-------|
| Skills | Array length >= 3 | "Select at least 3 skills" |
| Interests | Array length >= 1 | "Pick at least 1 interest" |
| Bio | Length <= 150 | "Bio must be 150 characters or less" |
| Avatar | File size <= 5MB, type = jpg/png | "Photo must be under 5MB" |

### Error Handling

```dart
// Retry logic with exponential backoff
Future<void> saveStepData(Map<String, dynamic> data) async {
  int retries = 0;
  while (retries < 3) {
    try {
      await supabase.from('profiles').update(data).eq('id', userId);
      return;
    } catch (e) {
      retries++;
      if (retries >= 3) {
        // Store locally, retry on next app open
        await localCache.write('pending_onboarding', data);
        showError('Saved locally. Will sync when connected.');
        return;
      }
      await Future.delayed(Duration(seconds: pow(2, retries).toInt()));
    }
  }
}
```

---

## STEP 6: STATE MANAGEMENT

### State Structure (Riverpod)

```dart
// Onboarding state model
class OnboardingState {
  final int currentStep;
  final Set<String> selectedSkills;
  final Set<String> selectedInterests;
  final String? avatarUrl;
  final File? avatarFile;
  final String? experienceLevel;
  final String? availability;
  final String bio;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedSkills = const {},
    this.selectedInterests = const {},
    this.avatarUrl,
    this.avatarFile,
    this.experienceLevel,
    this.availability,
    this.bio = '',
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  bool get canProceedFromSkills => selectedSkills.length >= 3;
  bool get canProceedFromInterests => selectedInterests.isNotEmpty;
  int get completeness {
    int score = 0;
    if (avatarUrl != null || avatarFile != null) score += 30;
    if (experienceLevel != null) score += 30;
    if (bio.isNotEmpty) score += 20;
    if (availability != null) score += 20;
    return score;
  }
}
```

### Provider Design

```dart
// Main onboarding provider
final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.watch(supabaseServiceProvider));
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final SupabaseService _supabase;

  OnboardingNotifier(this._supabase) : super(const OnboardingState()) {
    _loadProgress();
  }

  // Load saved progress from Supabase
  Future<void> _loadProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final profile = await _supabase.getProfile(userId);
    if (profile != null) {
      state = state.copyWith(
        currentStep: profile['onboarding_step'] ?? 0,
        selectedSkills: Set<String>.from(profile['skills'] ?? []),
        selectedInterests: Set<String>.from(profile['interests'] ?? []),
        experienceLevel: profile['experience_level'],
        availability: profile['availability'],
        bio: profile['bio'] ?? '',
        avatarUrl: profile['avatar_url'],
        isCompleted: profile['onboarding_completed'] ?? false,
      );
    }
  }

  // Step navigation
  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void previousStep() => state = state.copyWith(currentStep: state.currentStep - 1);

  // Skills
  void toggleSkill(String skill) {
    final skills = Set<String>.from(state.selectedSkills);
    if (skills.contains(skill)) {
      skills.remove(skill);
    } else {
      skills.add(skill);
    }
    state = state.copyWith(selectedSkills: skills);
  }

  // Interests
  void toggleInterest(String interest) {
    final interests = Set<String>.from(state.selectedInterests);
    if (interests.contains(interest)) {
      interests.remove(interest);
    } else {
      interests.add(interest);
    }
    state = state.copyWith(selectedInterests: interests);
  }

  // Save step to Supabase
  Future<void> saveCurrentStep() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = _buildStepData();
      await _supabase.updateOnboardingStep(data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    try {
      await _supabase.completeOnboarding();
      state = state.copyWith(isCompleted: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}
```

### Resume Logic

1. On app launch, check `profiles.onboarding_completed`
2. If `false` AND user is authenticated → redirect to `/onboarding`
3. Load `onboarding_step` → jump to that step in PageView
4. Re-populate state from saved profile data
5. User continues from where they left off

### Partial Completion Handling

- Each step saves independently to Supabase
- If app crashes mid-step, only unsaved current step data is lost
- Local cache (`flutter_secure_storage`) stores draft state as backup
- On resume: fetch from Supabase first, merge with local cache if Supabase is stale

---

## STEP 7: FLUTTER IMPLEMENTATION

### File Structure

```
lib/features/onboarding/
├── data/
│   ├── models/
│   │   └── onboarding_state.dart
│   └── repositories/
│       └── onboarding_repository.dart
├── presentation/
│   ├── providers/
│   │   └── onboarding_provider.dart
│   ├── screens/
│   │   ├── onboarding_shell.dart          # PageView wrapper
│   │   ├── welcome_screen.dart            # Step 1
│   │   ├── skills_screen.dart             # Step 2
│   │   ├── interests_screen.dart          # Step 3
│   │   ├── enrichment_screen.dart         # Step 4
│   │   └── completion_screen.dart         # Step 5
│   └── widgets/
│       ├── onboarding_progress_bar.dart
│       ├── skill_chip.dart
│       ├── interest_card.dart
│       ├── segmented_selector.dart
│       └── avatar_picker.dart
```

### Widget Tree (Per Screen)

```
OnboardingShell (PageView + Provider)
├── SafeArea
│   ├── OnboardingProgressBar
│   ├── PageView
│   │   ├── WelcomeScreen
│   │   │   ├── LottieAnimation
│   │   │   ├── TitleText
│   │   │   ├── SubtitleText
│   │   │   └── PrimaryButton ("Let's Go")
│   │   ├── SkillsScreen
│   │   │   ├── SearchBar
│   │   │   ├── CategorySection (×N)
│   │   │   │   └── SkillChip (×M)
│   │   │   ├── SelectionCounter
│   │   │   └── PrimaryButton ("Continue")
│   │   ├── InterestsScreen
│   │   │   ├── InterestGrid
│   │   │   │   └── InterestCard (×N)
│   │   │   ├── SelectionCounter
│   │   │   └── PrimaryButton ("Continue")
│   │   ├── EnrichmentScreen
│   │   │   ├── AvatarPicker
│   │   │   ├── SegmentedSelector (experience)
│   │   │   ├── AvailabilityCards
│   │   │   ├── BioTextField
│   │   │   └── PrimaryButton ("Continue")
│   │   └── CompletionScreen
│   │       ├── AnimatedCheckmark
│   │       ├── TitleText
│   │       ├── SummaryChips
│   │       └── PrimaryButton ("Start Exploring")
│   └── BottomActions
│       ├── SkipButton (contextual)
│       └── BackButton (contextual)
```

### Navigation Approach

**PageView with programmatic control** (not routes)

Rationale:
- Preserves state across steps (no rebuild on navigation)
- Smooth horizontal swipe transitions
- Easy to control direction (disable swipe via `physics: NeverScrollableScrollPhysics`)
- Step validation happens before `nextPage()` call

### State Management

**Riverpod StateNotifier** (already in project dependencies)

- Single `OnboardingNotifier` manages all step state
- Each screen reads state via `ref.watch(onboardingProvider)`
- Mutations via `ref.read(onboardingProvider.notifier)`
- Async operations use `.future` for loading states

### Reusable Components

#### 1. OnboardingProgressBar

```dart
class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  // Linear progress indicator with step dots
}
```

#### 2. SkillChip

```dart
class SkillChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  // AnimatedFilterChip with checkmark icon
}
```

#### 3. InterestCard

```dart
class InterestCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  // Card with icon + label, highlight on select
}
```

#### 4. SegmentedSelector

```dart
class SegmentedSelector<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? selected;
  final ValueChanged<T> onChanged;
  // Generic segmented control
}
```

#### 5. AvatarPicker

```dart
class AvatarPicker extends StatelessWidget {
  final File? selectedFile;
  final String? existingUrl;
  final ValueChanged<File> onPick;
  // Circle with image_picker integration
}
```

---

## STEP 8: EDGE CASES

| Scenario | Handling |
|----------|----------|
| **User skips all optional steps** | Allow — profile completeness shows lower %, prompt to complete later via in-app banner |
| **User selects < 3 skills** | CTA disabled, inline counter shows requirement, toast on attempt |
| **Network failure during onboarding** | Save to local cache, show offline banner, auto-retry on connectivity restore |
| **Duplicate skill selection** | Impossible — Set<String> prevents duplicates |
| **Invalid interests (tampered API)** | Server-side validation rejects, client shows error toast |
| **Returning user resumes onboarding** | Load `onboarding_step` from profile, jump to that step in PageView |
| **User closes app on Step 4** | Progress saved up to Step 3, resume at Step 4 |
| **Photo upload fails** | Save other fields, queue photo for retry, show "Photo pending upload" placeholder |
| **User already completed onboarding** | Router redirects to `/home`, onboarding route blocked |
| **Multiple devices / sessions** | Last write wins on Supabase, step counter is source of truth |

---

## STEP 9: METRICS

### Key Performance Indicators

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Completion Rate** | > 85% | `users_completed / users_started` |
| **Drop-off per Step** | < 10% per step | Track step transitions in analytics |
| **Avg Time to Complete** | < 60 seconds | Timestamp diff: screen 1 load → screen 5 CTA |
| **Data Completeness Score** | > 60% avg | Average of completeness % across all users |
| **Skills Selection Rate** | > 95% | Users who select >= 3 skills |
| **Optional Enrichment Rate** | > 50% | Users who fill at least 1 optional field |

### Analytics Events

```dart
// Track these events
'onboarding_started'           // Screen 1 viewed
'onboarding_step_completed'    // Each step CTA tapped (with step number)
'onboarding_skipped'           // Skip button tapped (with step number)
'onboarding_completed'         // Screen 5 CTA tapped
'onboarding_abandoned'         // App closed mid-onboarding (with last step)
'onboarding_resumed'           // App reopened with incomplete onboarding
```

---

## APPENDIX: CURATED DATA LISTS

### Skills (35 options, grouped)

**Frontend:**
React, Flutter, Vue.js, Angular, Svelte, Next.js, HTML/CSS

**Backend:**
Node.js, Python, Go, Rust, Java, Django, FastAPI, Express

**Mobile:**
Swift, Kotlin, React Native, Dart

**Data/AI:**
TensorFlow, PyTorch, SQL, MongoDB, PostgreSQL, Pandas

**DevOps/Tools:**
Docker, Kubernetes, AWS, Firebase, Git, CI/CD

**Design:**
Figma, UI/UX Design, Prototyping

### Interests (10 options)

🤖 AI / Machine Learning
🔗 Web3 / Blockchain
🏥 HealthTech
💰 FinTech
🎓 EdTech
🌍 Climate / Sustainability
🎮 Gaming
💡 Social Impact
🛠️ Developer Tools
🌐 Open Source

### Experience Levels

- **Beginner:** < 1 year, learning fundamentals
- **Intermediate:** 1-3 years, built projects, comfortable with stack
- **Advanced:** 3+ years, shipped production apps, can architect systems

### Availability Options

- **Full-time:** Available 20+ hours/week during hackathon
- **Part-time:** Available 5-15 hours/week
- **Weekends only:** Available Sat-Sun only

---

## IMPLEMENTATION PRIORITY

| Phase | Scope | Effort |
|-------|-------|--------|
| **Phase 1** | Screens 1-3 (Welcome, Skills, Interests) + Supabase integration | 2 days |
| **Phase 2** | Screen 4 (Enrichment) + photo upload | 1 day |
| **Phase 3** | Screen 5 (Completion) + animations | 0.5 day |
| **Phase 4** | Resume logic + local caching | 0.5 day |
| **Phase 5** | Analytics integration + metrics dashboard | 0.5 day |
| **Total** | Full onboarding system | **~5 days** |
