# Workouts

## Start or resume

The home screen shows the next workout in the active mesocycle. Starting it opens the pre-workout check-in before creating the active workout. If the app closes during a workout, reopening it finds the active database record and resumes its persisted sets even when the cached navigation state was not saved.

You can skip the scheduled workout by selecting a skip reason. Workouts advance in cycle order; the home screen does not substitute a different workout for the scheduled one.

While a workout is active, you can use the top-right menu to visit History or another app screen. Returning to Workout keeps the active session mounted, so its rest timer continues from the same countdown instead of restarting.

History includes the current mesocycle as soon as its first workout starts. Its calendar marks completed workouts in green with a checkmark, the active workout with a play icon, skipped workouts in red, and workouts that have not started in gray.

!!! note "Screenshot pending — workout-home"
    Capture the home screen with the next workout, mesocycle progress, expected date, and start/skip controls visible.

## Record sets

Each set displays the fields required by its movement, such as reps, weight, distance, or time. Weight is recorded in pounds (`lbs`) and distance in miles (`mi`). The retired metric preference changed labels only: it did not convert or tag stored values. This app has one existing owner-controlled data set, and its values were confirmed to be pounds and miles despite that old label option. Existing numbers therefore remain unchanged; converting them would corrupt the user's records. Planned values appear as defaults. Confirming a set saves its completed values immediately. Clearing a required value prevents confirmation, and unchecking a completed set removes its confirmed values from the completed workout while leaving the editable values on screen.

Changing a set's weight carries that weight into its later unchecked sets. Repetition changes apply only to the edited set.

When enabled in **Settings → Rest Timer**, get-ready chimes play a lower tone at 10 seconds remaining and a higher tone at 5 seconds without changing the displayed countdown. Silent alert mode suppresses both tones. When the rest timer ends, its spoken cue uses the rightmost planned value shown for the next set. If the planner left that value empty, the cue says “ready” instead of announcing an earlier value from the row. On Android, an active workout delivers the get-ready chimes, final cue, and optional vibration from its foreground workout service, so switching to another app does not postpone the alerts until Workout of Record is visible again.

Exercises and prescribed sets can be skipped when the app requests a reason. Skipping clears completed values so the history does not imply the work was performed. The skip reason remains in history, and later planning falls back to earlier completed values instead of treating a skipped exercise as a new exercise. User-added sets can be removed. Required exercise and muscle-group feedback must be completed before the workout can advance or finish.

## Finish safely

Finish the workout only after all exercises are completed or skipped and all required feedback is recorded. The app saves progress throughout the session, but completion performs the bookkeeping that advances the mesocycle and may trigger an automatic backup.
