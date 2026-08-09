# Workouts

## Start or resume

The home screen shows the next workout in the active mesocycle. Starting it opens the pre-workout check-in before creating the active workout. If the app closes during a workout, reopening it finds the active database record and resumes its persisted sets even when the cached navigation state was not saved.

You can skip the scheduled workout by selecting a skip reason. Workouts advance in cycle order; the home screen does not substitute a different workout for the scheduled one.

While a workout is active, you can use the top-right menu to visit History or another app screen. Returning to Workout keeps the active session mounted, so its rest timer continues from the same countdown instead of restarting.

!!! note "Screenshot pending — workout-home"
    Capture the home screen with the next workout, mesocycle progress, expected date, and start/skip controls visible.

## Record sets

Each set displays the fields required by its movement, such as reps, weight, or time. Planned values appear as defaults. Confirming a set saves its completed values immediately. Clearing a required value prevents confirmation, and unchecking a completed set removes its confirmed values from the completed workout while leaving the editable values on screen.

Changing a set's weight carries that weight into its later unchecked sets. Repetition changes apply only to the edited set.

Exercises and prescribed sets can be skipped when the app requests a reason. Skipping clears completed values so the history does not imply the work was performed. The skip reason remains in history, and later planning falls back to earlier completed values instead of treating a skipped exercise as a new exercise. User-added sets can be removed. Required exercise and muscle-group feedback must be completed before the workout can advance or finish.

## Finish safely

Finish the workout only after all exercises are completed or skipped and all required feedback is recorded. The app saves progress throughout the session, but completion performs the bookkeeping that advances the mesocycle and may trigger an automatic backup.
