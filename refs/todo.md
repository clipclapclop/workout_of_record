# Workout of Record — Todo

Tracks all remaining work. Each task includes enough context to execute without re-reading the conversation.

**Stack:** Flutter (Android-first), Drift ORM (SQLite), Navigator 1.0, FutureBuilder + manual re-fetch.
**Key invariant:** Every in-workout user action persists to DB immediately (crash-safe).

---

### 1. Meso Template Builder

**Goal:** Let the user create new `meso_template` rows in-app (name, days per week, which movements per day, order).

**UX Flow:**
1. Entry point from `MesocycleSetupScreen` — "Create new template" button.
2. User names the template and picks number of training days per week.
3. For each training day, user adds movements (via movement picker / search). Order is drag-reorderable.
4. Save creates `meso_template` + `workout_template` + `exercise_template` rows.

**DB methods needed:**
- `createMesoTemplate(String name) → Future<int>`
- `addWorkoutTemplate(int mesoTemplateId, int orderIndex) → Future<int>`
- `addExerciseTemplate(int workoutTemplateId, int movementId, int orderIndex) → Future<void>`
- `getMesoTemplates()` — already needed by task 8.

**Note:** Movements are created/managed separately (Movement screens already exist). Template builder just picks from existing movements.

---

### 2. Cold Boot / Mesocycle Selection UI

**Goal:** When `app_state.currentMesocycleId` is null (fresh install or end of mesocycle), guide the user through selecting/creating a mesocycle.

**UX Flow:**
1. `HomeScreen` detects `currentMesocycleId == null` → navigates to `MesocycleSetupScreen`.
2. `MesocycleSetupScreen` lists available `meso_templates` (from DB) for user to pick. Includes "Create new template" → task 5.
3. User picks a template and sets total week count (hard weeks + 1 deload).
4. App creates `mesocycle`, week 1 `week`,
4.5. all `workout` rows from the template's `workout_template` rows, and `planned_workout` / `planned_exercises` / `planned_sets` for week 1 training days (values: 2 sets, blank reps/weight — cold start default) will be created after each respective workout preworkout questionaire is submitted (if it's not presently done this way, that'll need to change) (eventually this will be done more inteligently base based on each days' )
5. `app_state.currentMesocycleId` is set to the new mesocycle.
6. Navigate to `HomeScreen` (which now shows the first workout).

**DB methods needed:**
- `getMesoTemplates() → Future<List<MesoTemplate>>`
- `createMesocycle(int templateId, int totalWeeks) → Future<int>` — full transaction creating the meso + week, but the workout creations will need to reference the meso template... so above methods may need adjusting

**Cold start values:** 2 sets per exercise, `reps = null`, `weight = null` (user fills in first time).

---

### 3. Deterministic Fallback Heuristics

**Goal:** When AI is off/unavailable, still generate reasonable planned set values.

**Hard week heuristic:** Use last completed values directly (same reps/weight as last week).

**Deload heuristic:** Reduce volume — e.g., 2 sets, 60–70% of last weight, same reps.

**Cold start (no history):** 2 sets, reps/weight blank (null) — user fills in manually.

**Implementation:** Pure Dart function `PlannedSetValues computeHeuristic(ExerciseHistory history, WeekGoal goal)` — no DB writes, called from `generatePlannedWorkout`.

---

### 4. Week 2+ Workout Planning (Template Generation from Prior Week)

**Goal:** When week N+1 starts, auto-generate `planned_workout` / `planned_exercises` / `planned_sets` for each training day using last week's completed workout as the template.

**Rules (from overview.md):**
- Filter completed exercises by `isPersistent = true` only.
- User-added sets (no planned_set) are included if their exercise is persistent.
- Planned values for the new week = completed values from last week (reps/weight/time).
- If a completed set had a `skipReason`, it still becomes a planned set in week N+1 (it was prescribed; skipping was a one-off).
- If an exercise was skipped (`skipReason != null`), it is still included if `isPersistent = true`.

**Trigger:** Called during `initializeWorkout` for week 2+. Detect week number from the workout's week row.

**DB method:** `generatePlannedWorkout(int workoutId) → Future<void>` — checks if a `planned_workout` already exists (idempotent). If week 1, seed data already handled it. If week 2+, find the matching workout from week N-1 (same `orderIndex` within same mesocycle), copy its persistent completed exercises/sets.

**Edge cases:** First mesocycle ever (no prior week) → use seed data (already done). No completed workout for prior week slot (workout was skipped entirely) → generate empty planned workout.

---

### 5. `isPersistent` Flag in Workout Screen

**Goal:** Let user toggle whether a completed exercise carries forward to next week's planned workout.

**Current state:** `completed_exercise.isPersistent` is set to `true` for all exercises in `initializeWorkout`. User has no way to change it.

**UX:** Toggle in exercise header (e.g., a bookmark icon). Default `true`. If user sets to `false`, the exercise won't appear in week N+1's planned workout.

**DB:** `setExercisePersistence(int completedExerciseId, bool isPersistent)` — simple update.

---

### 6. Workout Skip

**Goal:** User can skip the current prescribed workout and advance to the next one.

**Rules (from overview.md):** Workouts within a week can be skipped but not reordered. Skipping creates a `completed_workout` with `status = abandoned` and a `WorkoutSkipReason`.

**UX:** On `HomeScreen`, add a "Skip" option (e.g., secondary button or overflow menu item) alongside "Start Workout." Needs a popup to ensure user wants to skip the workout

**DB:** Add `skipWorkout(int workoutId, WorkoutSkipReason reason) → Future<void>` — inserts `completed_workout(status=abandoned, startedAt=now, completedAt=now)`, no exercises/sets. Then re-fetch next workout.

**`WorkoutSkipReason` enum:** Already in `lib/db/tables/enums.dart`.

**`getNextWorkout`:** Already filters on "no completed_workout row at all" — abandoned workouts have a row, so they're naturally excluded. Verify this works correctly.

---

### 7. End of Mesocycle Handling

**Goal:** When `getNextWorkout` returns null (all workouts completed), the mesocycle is done.

**UX:** `HomeScreen` shows a "Mesocycle Complete" state with a "Start New Mesocycle" button.

**Flow:** Button → set `app_state.currentMesocycleId = null`, `currentCompletedWorkoutId = null` → navigate to `MesocycleSetupScreen` (task 8).

---

### 8. User Profile

**Goal:** Store user profile fields used by the recommendation engine.

**Fields:** age (int), weight (double, kg), training goal (enum: strength / hypertrophy / endurance / general).

**DB:** Add `user_profile` table (singleton like `app_state`). Schema migration required (version bump).

**UI:** `ProfileScreen` with form fields. Link from Settings or app drawer.

---

### 9. Settings Screen

**Goal:** Central settings hub.

**Initial settings:**
- AI recommendations: on/off toggle
- Anthropic API key: text field (stored securely via `flutter_secure_storage`)
- (Future) units: lbs / kg

---

### 10. History / Analytics Screens

**Goal:** Let user review past workouts.

**Screens:**
- `HistoryScreen`: list of `completed_workouts` ordered by `startedAt` desc. Tap → `WorkoutHistoryDetailScreen`.
- `WorkoutHistoryDetailScreen`: shows all exercises + sets with planned vs completed values side by side.
- (Future) Per-movement trend charts.

**DB methods:**
- `getCompletedWorkouts() → Future<List<CompletedWorkout>>`
- `getWorkoutData(int completedWorkoutId)` — already implemented, reuse.

**Remaining:**
- Add new movement form (create flow, not just edit).

**Note:** Movements are global, not per-mesocycle. Editing a movement affects future planned workouts only (planned/completed rows already store movementId, so history is unaffected).

---

### 11. AI / LLM Recommendations

**Goal:** Pre-fill set reps/weight/time using openrouter API based on historical data and user context.

**Input to LLM (per exercise):**
- User profile: age, weight, training goal
- Mesocycle position: week number, total weeks, goal (`hard`/`deload`)
- Pre-workout check-in values (soreness per muscle group, sleep/energy/mental state)
- Last N completed sessions for this workout slot (exercises + sets + skip reasons, filtered on `isPersistent`)
- Post-workout check-in history (effort/volume per muscle group)

**Output:** Recommended sets array — each with reps, weight, time (matching movement's isRequired* flags).

**Constraints:** Sets count ≈ prior count ±1. Reps ≈ prior ±2. Weight ≈ prior ± weight_delta. Hard bounds enforced (min weight, sane maximums).

**Integration point:** Called during `initializeWorkout` (or lazily on `WorkoutScreen` load) to populate `planned_set` values before the user sees the screen. Failures fall through to deterministic heuristics (task 12).

**Settings:** AI on/off toggle in Settings screen. API key input field.

---

### 12. Inactivity Reminder

**Goal:** Nudge user if workout has been active for ~1 hour with no interaction.

**Implementation:** In `WorkoutScreen`, track last interaction timestamp in state. Use a `Timer.periodic` (check every few minutes). If elapsed > 1 hour, show a `SnackBar` or notification: "Still working out? Don't forget to log your sets."

**Note:** Keep it simple — in-app only for now (no system notifications required).

---

### 13. Additional Test Coverage

**Current:** 8 tests in `test/db/workout_flow_test.dart` covering core DB flow.

**Needed:**
- `skipSet` and `clearCompletedSet` (with skipReason) round-trip
- `skipExercise` — verify skipReason saved, sets unaffected
- `addSet` / `deleteSet` — verify counts before and after
- `generatePlannedWorkout` week 2 — verify planned values match prior week's completed values
- `skipWorkout` — verify abandoned status, getNextWorkout skips it
- `finishWorkout` — verify `currentCompletedWorkoutId` cleared in app_state

---

## Architecture Notes

- **DB naming:** `get*` = `Future<T>` (one-shot), `watch*` = `Stream<T>` (reactive). All current screens use `get*` with manual re-fetch.
- **Immediate persistence:** Every write (set value, check, skip, check-in) calls a DB method before `setState`. No buffering.
- **Crash recovery:** `app_state.currentCompletedWorkoutId` is an acceleration pointer. True source of truth is `completed_workout` rows with `completedAt = null` + `status = active`. `getWorkoutData` is the re-hydration method.
- **`putIfAbsent` pattern:** `WorkoutScreen._load()` uses `_setStates.putIfAbsent` so UI controller state (typed but unchecked values) survives re-renders triggered by DB writes.
- **No DAO layer:** All DB methods live directly on `AppDatabase`. Keep this pattern until complexity clearly demands separation.
- **Rest day squish:** `!candidate.isAfter(today)` means candidate ≤ today → advance `currentDate`. Candidate > today → stay (squish multiple rest days to same date).
