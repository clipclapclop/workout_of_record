# Workout of Record - Requirements & Context

## What This App Is
A Flutter workout tracking app (Android-first) with optional AI-powered recommendations for sets, reps, and weight.  
AI picks from constrained options based on historical data.  
When AI is unavailable or disabled, the app remains fully usable as a local logging tool.
Local, provacy and storage space respecting
For a single user, no multi-user, no accounts

## What This App Is Not
- Not a workout builder/program generator
- Not a personal coach
- Not internet-dependent for core logging functionality

---

## Training Structure

### Cycle
- User defines a rotation, a "week", of N items (workouts + rest days) (not assumed to be 7 days like a calander week)
- Each day, workout or rest day, has a label (e.g. "Day 2", "Thursday").
- App always presents the next workout sequentially (not calendar-based, can't be reordered).
- User can skip a workout to advance.
- Rest days are explicit cycle items and auto-advance without user friction.

### Mesocycle
- The first N weeks of the cycle are hard, the last is always assumed to be a deload week.
- App tracks current mesocycle week (the word week is used for practical reasons but can actually be any number of days long)
- Recommendation logic should factor mesocycle position.

### Week
- Each week builds upon the last
- Each workout is templated upon what was completed (not assigned or planned) the same day of the previous week
- Workouts within a week can be skipped but not reordered.

### Workouts
- To have gating to prevent the user from accidently skipping around
- To have overrides to allow the user to skip around
- To allow the addition/subtraction/replacement of exercises as a one-off or permanantly
- Compresied of exercises

### Exercises (think 3 sets of 12 pullups)
- Compresied of Movements (think bench press) Sets (rep count, weight, and or time)

### Sets
- To be user adjustable
- Since all sets of an exercise are innately the same (they have the same movement, and while the values may be different, they'll have the same combination of rep count, weight, and or time) so the idea of reordering sets doesn't make sense
- If the user adds a set, it inately gets appended to the end of the list of sets
- If the user deletes or skips a set, it's inately the last one
- If the user enters data into the wrong set, it's their responsability to delete it from the wrong spot and reenter it in the correct spot

---

## Workout Flow

### 1. Pre-Workout Check-In
- User records soreness ratings for fixed muscle groups, and general state (0-3):
  - quads, hamstrings, abs, chest, back, biceps, triceps, traps, forearms, glutes, calves, shoulders
  - sleep, flatness/vigger
- Check-in persists to local storage immediately.
- Check-in data is available to recommendation logic.

### 2. Active Workout
- Each exercise has sets with reps, weights, and/or time:
  - AI on: prefilled by recommendation service
  - AI off: prefilled by deterministic heuristics
- User can edit freely; add/remove sets.
- Per-exercise, post exercise required feedback before progressing:
  - Joint pain (none|little|some|a lot)
- Per muscle group, post muscle group required feedback before progressing:
  - Since muscle groups aren't a formal thing/object/data type, if not more exercises exist which share the same muscle group type as that of the movement of the last exercise ask about muscle group workout:
  - Difficulty (too easy|easy|hard|too hard)
  - Volume (too little|just right|a lot|way too much)
- Every user action persists immediately (crash/kill-safe).

### 3. Sets / Exercises Completion Semantics
- Set can be:
  - completed as prescribed
  - edited
  - skipped with required reason
- Skip reasons include: time, tired, joint pain, muscle pain, connective tissue pain.
- Extra user-added sets can be seen as such since the number of completed sets will be greater than the number of prescribed sets.
- Exercise can be skipped formally with reason.
- Planned and completed values are both preserved.
- Once generated, planned workouts (as compared to completed workouts) will be saved as read only so they'll be available for reference
- Once a planned workout is made and saved, an accompanying completed workout will be generated with the same shape/format only with nulls for all of the sets/reps/times and immediately saved to the db
- Once a set is completed (once it's checkbox is checked in the ui), it's values should immediately be saved, replacing the nulls
- If a checkbox is unchecked for a set, the accompanying values should be immediately set to null in the db, but the values in the UI should be left
- Checkboxes should only be checkable if the accompanying values within the relevant textboxes are set with appropreate values.
- The movement of a set is what will determin what combination of reps, weight, and/or time textboxes are present for a set.
- All sets of a given movement will have the same combination of textbox types (reps, weight, time)
- On startup, either when starting a new workout or post shutdown or crash, set textboxes should be populated with the accompanying values from the associated completed workout db values that aren't null, for null values, the associated values will be gotten from the planned workout. if the planned workout doesn't have a value, such as in cases where the user added sets or exercises, textboxes will default to being empty.
- the UI will be the same size/shape/format as the associated completed workout, so it'll start as the same shape as the associated planned workout but could change as the user makes changes. so the UI and completed workout in the db should always reflect each other (other than default values from the planned workout that haven't yet been committed because their sets haven't yet been marked as completed)
- Cold boot asside, last weeks completed instance of today's workout, filtered on isPersistant, is the template for this weeks planned workout. What the user completed on day X of week Y is the starting point for the creation of the planned workout for day X of week Y + 1.

### Post Crash/mid workout close
- since order is forced, and things that aren't yet done are null, the first thing that's null is where things left off

### 4. End of Workout
- Workout is completable only when:
  - All exercises are completed or skipped
  - Required feedback is complete for each exercise
- On completion:
  - Save post-workout feedback
  - book keeping should be done so it's simple/umambiguous for the app to know where to pick up
- Inactivity reminder target: ~1 hour during active session.

### Cold boot
- the meso_template table will be a respository of basic mesocycle plans
- the meso_template table will give the user a list of basic plans to pick from
- it's intentinally a little vague, not cover the total duration, sets/reps/weights/times since those could change in time as the template's reused.
- it will be used for the basic structure of the workouts for the first week, but only the first week
- as previously/elsewhere mentioned, after the first week, the previous week's completed workouts become the templates, after being filtered against isPersistant
- the meso_templates will let the user create meso templates, then when they're between meso's and pick which to do next, as part of the creation process, they'll decide the total number of weeks (hard and deload), then this will give structure for the first week, and set/rep/weigt/time values will be generated based on a number of huristics and llm input

---

## Recommendations

### Contract
Input includes:
- user profile (age, weight, goal)
- mesocycle position (week + deload state)
- soreness/status check-in
- as much session history and whatever other info is deemed to get the best LLM responses; will likely initially start with recent session history (including skips and user-added sets)

Output includes:
- recommended sets/reps/weight per exercise within constrained bounds

### Constraints (initial)
- sets around prior set count
- reps around prior reps
- weight around prior weight and exercise increment
- hard bounds and validity clamps required

### AI Off / Failure Fallback
- Recommendation failures/timeouts/offline/disabled must fall back to deterministic heuristics with no UX break.
- Hard week heuristic: near last performed values.
- Deload heuristic: reduced volume/intensity defaults (tunable).

### Cold Start / Stale Data
- If no useful history: default to 2 sets, reps/weight blank.
- “Too stale” threshold is TBD.

## UX / Navigation
- Main focus: workout flow.
- Secondary screens: Exercises, Cycle Setup, History, Profile, Settings.
- Heavy cross-linking is expected (e.g., tap exercise to view history).
- Moderate density, practical low-noise UI.

---

## Non-Negotiable Invariants
- Every in-workout change persists immediately.
- App kill/relaunch will enable the user to quickly pick up where they left off with no data loss.
- Group/session progression is blocked until required feedback rules are satisfied.
- Planned and completed training values are both retained for analysis/recommendation.

### Important Interface / Behavior Clarification
- Recovery source of truth is `completed_workout` + `completed_*`.
- `app_state` is an acceleration pointer, not the sole truth.

### Test Scenarios
- Crash after `completed_*` write but before `app_state` update -> app still resumes active workout.
- Crash during active workout with partial nulls -> values persisted and resumable.
- Planned-origin set skipped without reason -> blocked.
- User-added set deleted -> allowed.

### Assumptions
- Single local user only.
- One active (not completed) workout at a time.
- `completedAt = null` is valid marker for “in progress.”
- Since it's single user, local only, there won't be serious db latency or race condition concerns

### basic info/persistance/ui/ux flow
- have button to start workout
- prompt user with pre workout soreness/status questions
- generate proposed_workout (eventually via llm with questions and historic data) and save to db
- generate completed_workout, have it be the same shape as the proposed_workout with the same movements, only all nullable values should be null (there might be a few exceptions but...)
- build the ui to be the same shape as the completed_workout
- for any field in the ui, if there's an accompanying non-null value in the completed_workout then use that to fill the value (presumably we're recovering from a crash/shutdown) otherwise fall back to the proposed_workout (this way we get default where relevant, but also track any changes that have been made such as reporting logged info if the app crashes mid workout)
- for each set, there should be a checkbox for the user to check to signify that the set has been completed, it should only be active if the appropreate info has been entered (default values from the planned_workout are acceptable so if the user does a set as prescribed, they can just hit the checkbox to acknowledge that it's been done), but if they delete a value, the checkbox should be no longer active until they enter a new valid value
- as soon as the checkbox is checked (assuming the values are valid), it's accompanying info should be saved to the db so the db will accurately represent confermed portions of the ui (so the ui and the completed_workout will be the same shape, confirmed values in the ui will be saved to the db, and unconfirmed/empty values will be null)
- if the user unckecks a checkbox, the accompanying values whould be removed from the db and replaced with nulls
- the various isRequired* movement fields represent the fields that should be built into the ui for a given movement's sets, all fields must have valid values in order for the set to have it's checkbox checked
- if recoving from a crash from app closure, when resuming a workout, a checkmark is added to each set (marking it completed) for which said set has non-null values for each isRequired* bool for the set's referenced movement. so if all required data is logged, it's done, otherwise it's not

## Templates
- On any given day, the user can do or skip the prescribed workout; they can't do a different one
- For a given workout, the user can:
  - do the exercises in the prescribed order
  - out of order (not reorderd in the app)
  - maybe someday reordered (this would be assumed to be persistant)
  - the user will never (now or ever in the future) reorder the exercises in the ui for this week only (really, we could probably do this, we'd just loose the non-persistant ui reorder if there was an app crash, but this isn't something I see caring to support)
- For a given exercise, the user can:
  - skip it
  - do it
- For a given set, the user can:
  - skip it if it's prescribed
  - do it
  - add one (or mere)
  - delete it if they added it
- So during the meso planning phase, the user will come up with a template for week one, but from then on, last week's completed workouts will be the templates for this week.


## Proposed rough schema (none of this is to be taken literally, just "thinking out loud")

enum MuscleGroup {
  chest,
  back,
  biceps,
  triceps,
  shoulders,
  quads,
  hamstrings,
  abs,
  traps,
  forearms,
  glutes,
  calves,
}

enum Soreness {
  none,
  a_little,
  some,
  lots,  
}

enum CurrentState {
  bad,
  not_good,
  good,
  great,  
}

enum Effort {
  to_easy,
  easy,
  hard,
  to_hard,
}

enum Volume {
  to_little,
  good,
  a_lot,
  way_to_much,
}

enum SkipReason {
  systemic_atigue,
  muscleFatigue,
  jointPain,
  time,
  musclePain,
  softTissuePainOther,
  dontLikeTheExercise,
}

### movement // "bench press", "curl", "weighted pullup"
- id: int
- name: string
- min weight: double?
- weight delta: double?
- link: string? // to video/description
- note1: string? // to be displayed on the main workout screen
- note2: string? // for larger notes in a popup
- muscleGroup: enum
- subMuscleGroup: string?
- isRequiredReps: bool
- isRequiredWeight: bool
- isRequiredTime: bool

### planned_set
- id: int
- plannedExerciseId: int (planned_exercise.id)
- reps: int?
- weight: double?
- time: double?

### completed_set
- id: int
- completedExerciseId: int (completed_exercise.id)
- reps: int?
- weight: double?
- time: double?
- skipReason: SkipReason?

### post_exercise_checkin // maybe other questions too? we probably don't need this for a v1
- id: int
- completedExerciseId: int (fk -> completed_exercise.id, unique)
- jointPain: Soreness

### post_muscle_group_checkin // maybe other questions too? we probably don't need this for a v1
- id: int
- completedWorkoutId: int (fk -> completed_workout.id)
- effortLevel: Effort
- volumeLevel: Volume
- muscleGroup: MuscleGroup
- constraints:
  - UNIQUE(completedWorkoutId, muscleGroup)

### planned_exercise // think "3 sets of 10 pushups"
- id: int
- plannedWorkoutId: int (planned_workout.id)
- movementId: int (movement.id)

### completed_exercise // think "3 sets of 10 pushups"
- id: int
- completedWorkoutId: int (fk -> completed_workout.id)
- isPersistent: bool // do we want to do it again next week/period
- movementId: int (movement.id)
- orderIndex: int
- skipReason: SkipReason?
- constraints:
  - UNIQUE(completedWorkoutId, orderIndex)

### planned_workout // (or we could have one workout and add an isPlan bool)
- id: int
- workoutId: int (fk -> workout.id, unique)

### completed_workout
- id: int
- workoutId: int (fk -> workout.id, unique)
- startedAt: datetime
- completedAt: datetime?
- status: enum(`active`, `completed`, `abandoned`)

### pre_workout_checkin // there's probably other stuff as well, maybe this should be a string holding json (so maybe it should be a field in workout?)
- id: int
- workoutId: int (fk -> workout.id, unique)
- quads: Soreness?
- hamstrings: Soreness?
- abs: Soreness?
- chest: Soreness?
- back: Soreness?
- biceps: Soreness?
- triceps: Soreness?
- traps: Soreness?
- forearms: Soreness?
- glutes: Soreness?
- calves: Soreness?
- shoulders: Soreness?
- mentalState: CurrentState
- vimVigor: CurrentState
- sleepQuality: CurrentState

### workout // name will likely be something like "Day 2" or "Thursday"
- id: int
- weekId: int (fk -> week.id)
- name: string
- orderIndex: int
- isRestDay: bool
- constraints:
  - UNIQUE(weekId, orderIndex)

### week
- id: int
- mesocycleId: int (fk -> mesocycle.id)
- weekNumber: int
- goal: enum(`hard`, `deload`)
- createdAt: datetime
- constraints:
  - UNIQUE(MesocycleID, weekNumber)

### mesocycle
- id: int
- mesoTemplateId: int (fk -> meso_template.id)
- name: string
- totalWeekCount: int
- createdAt: datetime
- completedAt: datetime

### meso_templates
- id: int
- name: string

### week_template
- id: int
- mesoTemplateId: int (fk -> meso_template.id)
- name: string
- workoutCount: int

### workout_template
- id: int
- weekTemplateId: int (fk -> week_template.id)
- name: string
- isRestDay: bool
- dayIndex: int

### exercise_template
- id: int
- workoutTemplateId: int (fk -> workout_template.id)
- movement: int (fk -> movement.id)
- exerciseIndex: int

### app_state // presumably will be useful but will need to be flushed out as a function of implimentation stuff
- updatedAt: datetime


Movements

- name: 'Cable Fly'
- min weight: 3.5
- weight delta: 3.5
- link: null
- note1: null
- note2: null
- muscleGroup: Chest
- subMuscleGroup: null
- isRequiredWeight: true
- isRequiredReps: true
- isRequiredTime: false

- name: 'Dumbell Press (Incline)'
- min weight: 5
- weight delta: 5
- link: null
- note1: null
- note2: null
- muscleGroup: Chest
- subMuscleGroup: null
- isRequiredWeight: true
- isRequiredReps: true
- isRequiredTime: false

- name: 'Barbell Bent Over Row'
- min weight: 45
- weight delta: 5
- link: null
- note1: null
- note2: null
- muscleGroup: Back
- subMuscleGroup: null
- isRequiredWeight: true
- isRequiredReps: true
- isRequiredTime: false

- name: 'Dumbell Pullover'
- min weight: 5
- weight delta: 5
- link: null
- note1: null
- note2: null
- muscleGroup: Back
- subMuscleGroup: null
- isRequiredWeight: true
- isRequiredReps: true
- isRequiredTime: false

- name: 'Lying Dumbell Curl'
- min weight: 5
- weight delta: 5
- link: null
- note1: null
- note2: null
- muscleGroup: Biceps
- subMuscleGroup: null
- isRequiredWeight: true
- isRequiredReps: true
- isRequiredTime: false


A basic planned_workout

Cable fly: 5 x 7lb
Cable fly: 6 x 10.5lb
Dumbell press (incline): 7 x 15lb
Dumbell press (incline): 8 x 20lb
Dumbell press (incline): 9 x 25lb
Lying Dumbell Curl: 3 x 10lb