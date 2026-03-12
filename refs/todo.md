# Workout of Record — Todo

Tracks all remaining work. Each task includes enough context to execute without re-reading the conversation.

**Stack:** Flutter (Android-first), Drift ORM (SQLite), Navigator 1.0, FutureBuilder + manual re-fetch.
**Key invariant:** Every in-workout user action persists to DB immediately (crash-safe).

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
