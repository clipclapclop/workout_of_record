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

enum Soreness { none, aLittle, some, lots }

enum CurrentState { bad, notGood, good, great }

enum Effort { tooEasy, easy, hard, tooHard }

enum Volume { tooLittle, good, aLot, wayTooMuch }

enum SkipReason {
  systemicFatigue,
  muscleFatigue,
  jointPain,
  time,
  musclePain,
  softTissuePainOther,
  dontLikeTheExercise,
}

enum WorkoutStatus { active, completed, skipped }

enum WorkoutSkipReason { time, soreness, illness, other }

enum WeekGoal { hard, deload }

enum TrainingGoal { strength, hypertrophy, endurance, general }

enum CalorieState { surplus, maintenance, deficit }

enum MovementCategory { resistance, cardio }
