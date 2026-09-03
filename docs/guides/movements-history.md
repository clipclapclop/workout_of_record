# Movements and history

## Movements

The movements screen lists known movements and supports filtering and grouping. Opening a movement shows its configuration and recorded performance history. Movement requirements determine whether its sets ask for reps, weight, time, or a combination. Leaving after changing a movement offers Save, Discard, or Keep editing; validation or saving failures keep the draft open.

Take care when changing an existing movement's required fields: the change affects how future sets are displayed and validated.

The bodyweight load contribution is a finite number from 0 to 1 used only by built-in deload calculations. Use 0 when body weight is not an appreciable part of the load and 1 when the full body is moved. Built-in movements include conservative defaults, while newly created movements default to 0.

Optional minimum weight must be finite, but it may be negative for assisted movements. Optional weight step must be greater than zero. The editor explains invalid values instead of saving them.

Assistance can be represented as a negative external weight. For example, enter 50 lb of pull-up assistance as `-50`, set the bodyweight contribution to `1`, and configure a sufficiently negative minimum weight so rounding can select the machine's assistance settings.

## Workout history

The history screen provides calendar-based access to completed and skipped workouts. Open a workout to inspect exercises and sets, or open a movement from relevant screens to review its history.

The calendar uses the mesocycle's progression and recorded workout dates rather than assuming every training cycle is a seven-day calendar week.

!!! note "Screenshot pending — workout-history"
    Capture the history calendar and one expanded completed workout.
