# Workouts

## Start or resume

The home screen shows the next workout in the active mesocycle. Starting it opens the pre-workout check-in before creating the active workout. If the app closes during a workout, reopening it finds the active database record and resumes its persisted sets even when the cached navigation state was not saved.

You can skip the scheduled workout by selecting a skip reason. Workouts advance in cycle order; the home screen does not substitute a different workout for the scheduled one.

While a workout is active, you can use the top-right menu to visit History or another app screen. Returning to Workout keeps the active session mounted, so its rest timer continues from the same countdown instead of restarting.

History includes the current mesocycle as soon as its first workout starts. Its calendar marks completed workouts in green with a checkmark, the active workout with a play icon, skipped workouts in red, and workouts that have not started in gray.

!!! note "Screenshot pending — workout-home"
    Capture the home screen with the next workout, mesocycle progress, expected date, and start/skip controls visible.

## Record sets

Each set displays the fields required by its movement, such as reps, weight, distance, or time. A set can be confirmed only when reps are a positive whole number, time and distance are finite values greater than zero, and weight is finite. Zero or negative weight remains valid for bodyweight and assisted exercises. Weight is recorded in pounds (`lbs`) and distance in miles (`mi`). The retired metric preference changed labels only: it did not convert or tag stored values. This app has one existing owner-controlled data set, and its values were confirmed to be pounds and miles despite that old label option. Existing numbers therefore remain unchanged; converting them would corrupt the user's records. Planned values appear as defaults. Confirming a set saves its completed values immediately. Clearing a required value prevents confirmation, and unchecking a completed set removes its confirmed values from the completed workout while leaving the editable values on screen.

Changing a set's weight carries that weight into its later unchecked sets. Repetition changes apply only to the edited set.

The rest timer begins idle. The first tap, edit, or completion interaction with each set resets and starts it; later interactions with that same set do not. Exercise boundaries and feedback questions do not restart the countdown. Interacting with the final usable set stops and clears the timer because there is no next set. A movement-specific rest duration, when configured, still determines the countdown started by that movement's sets.

When enabled in **Settings → Rest Timer**, get-ready chimes play a lower tone at 10 seconds remaining and a higher tone at 5 seconds without changing the displayed countdown. Silent alert mode suppresses both tones. When the rest timer ends, its spoken cue uses the rightmost planned value shown for the next set. If the planner left that value empty, the cue says “ready” instead of announcing an earlier value from the row. On Android, an active workout delivers the get-ready chimes, final cue, and optional vibration from its foreground workout service, so switching to another app does not postpone the alerts until Workout of Record is visible again.

Exercises and prescribed sets can be skipped when the app requests a reason. Skipping clears completed values so the history does not imply the work was performed. The skip reason remains in history, and later planning falls back to earlier completed values instead of treating a skipped exercise as a new exercise. The last unchecked set can be permanently removed whether it was prescribed or added during the workout. An untouched exercise can be replaced, but once work or a skip has been recorded it remains part of the workout; use **Add Exercise** for a substitute or additional movement. Adding work for a muscle group that was already rated clears the old rating so it can be answered again after the new work. Required exercise and muscle-group feedback must be completed before a non-empty workout can advance or finish.

## Empty workouts

An empty workout is a scheduled training session with no exercises; it is different from a rest day. Empty workouts can come from a deliberately empty template day or from removing every exercise that would otherwise carry into a later week. From the empty workout screen, add an exercise or finish the workout without exercise or muscle-group feedback. An empty active workout remains available after restarting the app.

## Finish safely

Finish a non-empty workout only after all exercises are completed or skipped and all required feedback is recorded. The app saves progress throughout the session, but completion performs the bookkeeping that advances the mesocycle and may trigger an automatic backup.
