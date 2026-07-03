# Mesocycles and progression

A mesocycle repeats an ordered cycle of workout and rest days. It contains hard weeks followed by a final deload week. The app presents the next cycle item in order and uses completed work from earlier weeks when planning later workouts.

## Create a mesocycle

Choose or create a mesocycle template, set its duration, and review its ordered days and exercises. A template establishes the first week; later weeks build from what was actually completed.

Within a template, exercises can be reordered, added, or removed. Automatic progression can be configured per exercise.

## Change the duration

The mesocycle calendar shows materialized weeks and workouts. When the current workout state permits it, add a hard week before the deload or remove a future week. Changing the duration invalidates affected future plans so they can be regenerated with the correct hard/deload goal.

!!! note "Screenshot pending — mesocycle-calendar"
    Capture the expanded mesocycle calendar with hard and deload weeks plus the add/remove-week controls.

## Automatic progression

For exercises with automatic progression enabled, hard weeks can increase reps and periodically append a set according to the exercise's position within its muscle group. A newly appended set carries forward the prior set's weight while leaving reps empty for confirmation.

The built-in deload planner front-loads approximately one-third of the week's training days as heavy deload workouts. Heavy days use 40% of the prior sets, 50% of the prior reps, and 90% of the prior effective load. Later easy days use 30% of the prior sets, 65% of the prior reps, and 65% of the prior effective load. Sets and reps round to the nearest whole number with a minimum of one; weights round to the movement's available increment. Exercises with automatic progression disabled are copied unchanged during deloads.

Effective load can include a movement-specific portion of body weight. This prevents loaded squats, lunges, pull-ups, and similar movements from treating bar or implement weight as the entire load. If body weight is not recorded, planning falls back to external weight alone.

You remain free to edit planned values while recording the workout. Completed values—not merely planned values—become the basis for subsequent weeks.
