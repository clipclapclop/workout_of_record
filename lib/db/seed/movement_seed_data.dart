import '../tables/enums.dart';

class MovementSeedEntry {
  final String name;
  final MuscleGroup muscleGroup;
  final bool isRequiredReps;
  final bool isRequiredWeight;
  final bool isRequiredTime;
  final bool isRequiredDistance;
  final double? minWeight;
  final double? weightDelta;

  const MovementSeedEntry({
    required this.name,
    required this.muscleGroup,
    this.isRequiredReps = true,
    this.isRequiredWeight = true,
    this.isRequiredTime = false,
    this.isRequiredDistance = false,
    this.minWeight,
    this.weightDelta,
  });
}

// ── Weight profile helpers ────────────────────────────────────────────────────

/// Barbell / Smith Machine: min 45, step 5
MovementSeedEntry _bb(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 45, weightDelta: 5);

/// EZ Bar: min 25, step 5
MovementSeedEntry _ez(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 25, weightDelta: 5);

/// Dumbbell: min 5, step 5
MovementSeedEntry _db(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 5, weightDelta: 5);

/// Lat pulldown / assisted pullup machines: min 10, step 10
MovementSeedEntry _pd(String name) =>
    MovementSeedEntry(name: name, muscleGroup: MuscleGroup.back, minWeight: 10, weightDelta: 10);

/// Cable (non-pulldown): min 3.5, step 3.5
MovementSeedEntry _ca(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 3.5, weightDelta: 3.5);

/// Bodyweight: no weight required
MovementSeedEntry _bw(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, isRequiredWeight: false);

/// Stack machine: min 10, step 5
MovementSeedEntry _mc(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 10, weightDelta: 5);

/// Plate-loaded machine (hack squat, leg press, etc.): min 45, step 5
MovementSeedEntry _pm(String name, MuscleGroup mg) =>
    MovementSeedEntry(name: name, muscleGroup: mg, minWeight: 45, weightDelta: 5);

/// Cardio: time + distance only, no reps/weight
MovementSeedEntry _cardio(String name) => MovementSeedEntry(
      name: name,
      muscleGroup: MuscleGroup.other,
      isRequiredReps: false,
      isRequiredWeight: false,
      isRequiredTime: true,
      isRequiredDistance: true,
    );

// ── Seed list ─────────────────────────────────────────────────────────────────
// Exercises that target multiple muscle groups appear more than once.
// Composite unique key is (name, muscleGroup), so this is intentional.

final kMovementSeeds = <MovementSeedEntry>[
  // ── A ──────────────────────────────────────────────────────────────────────
  _bw('Ab Wheel', MuscleGroup.abs),
  _bw('Assisted Dip', MuscleGroup.triceps),
  _db('Arnold Press', MuscleGroup.shoulders),
  _pd('Assisted Pullup (Narrow Grip)'),
  _pd('Assisted Pullup (Normal Grip)'),
  _pd('Assisted Pullup (Parallel Grip)'),
  _pd('Assisted Pullup (Underhand Grip)'),
  _pd('Assisted Pullup (Wide Grip)'),

  // ── B ──────────────────────────────────────────────────────────────────────
  const MovementSeedEntry(
    name: 'Bar Hang',
    muscleGroup: MuscleGroup.back,
    isRequiredReps: false,
    isRequiredWeight: false,
    isRequiredTime: true,
  ),
  _bb('Barbell Bent Over Row', MuscleGroup.back),
  _bb('Barbell Bent Over Shrug', MuscleGroup.traps),
  _bb('Barbell Curl (Narrow Grip)', MuscleGroup.biceps),
  _bb('Barbell Curl (Normal Grip)', MuscleGroup.biceps),
  _bb('Barbell Facepull', MuscleGroup.shoulders),
  _bb('Barbell Facepull', MuscleGroup.traps),
  _bb('Barbell Flexion Row', MuscleGroup.back),
  _bb('Barbell Front Raise', MuscleGroup.shoulders),
  _ez('Barbell Front Raise (EZ Bar, Underhand)', MuscleGroup.shoulders),
  _bb('Barbell Front Raise (Overhand)', MuscleGroup.shoulders),
  _bb('Barbell Good Morning (Cambered Bar)', MuscleGroup.hamstrings),
  _bb('Barbell Good Morning (High Bar)', MuscleGroup.hamstrings),
  _bb('Barbell Good Morning (Low Bar)', MuscleGroup.hamstrings),
  _bb('Barbell Good Morning (Safety Bar)', MuscleGroup.hamstrings),
  _bb('Barbell Hip Thrust', MuscleGroup.glutes),
  _bb('Barbell Overhead Tricep Extension', MuscleGroup.triceps),
  _bb('Barbell Overhead Tricep Extension (Seated)', MuscleGroup.triceps),
  _bb('Barbell Pullover', MuscleGroup.back),
  _bb('Barbell Row to Chest', MuscleGroup.back),
  _bb('Barbell Shoulder Press (Seated)', MuscleGroup.shoulders),
  _bb('Barbell Shoulder Press (Standing)', MuscleGroup.shoulders),
  _bb('Barbell Shrug', MuscleGroup.traps),
  _bb('Barbell Skullcrusher', MuscleGroup.triceps),
  _bb('Barbell Split Squat', MuscleGroup.quads),
  _bb('Barbell Squat (Cambered Bar)', MuscleGroup.quads),
  _bb('Barbell Squat (Cross Stance, Feet Forward)', MuscleGroup.quads),
  _bb('Barbell Squat (High Bar)', MuscleGroup.quads),
  _bb('Barbell Squat (Narrow Stance)', MuscleGroup.quads),
  _bb('Barbell Squat (Safety Bar)', MuscleGroup.quads),
  _bb('Barbell Squat (Sumo Stance)', MuscleGroup.quads),
  _bb('Barbell Standing Wrist Curl', MuscleGroup.forearms),
  _bb('Barbell Upright Row', MuscleGroup.shoulders),
  _bb('Barbell Upright Row', MuscleGroup.traps),
  _ca('Bayesian Curl', MuscleGroup.biceps),
  _pm('Belt Squat', MuscleGroup.quads),
  _pm('Belt Squat (Wide Stance)', MuscleGroup.quads),
  _pm('Belt Squat Calves', MuscleGroup.calves),
  _bb('Bench Press (Cambered Bar)', MuscleGroup.chest),
  _bb('Bench Press (Close Grip)', MuscleGroup.chest),
  _bb('Bench Press (Decline)', MuscleGroup.chest),
  _bb('Bench Press (Incline, Medium Grip)', MuscleGroup.chest),
  _bb('Bench Press (Incline, Narrow Grip)', MuscleGroup.chest),
  _bb('Bench Press (Incline, Wide Grip)', MuscleGroup.chest),
  _bb('Bench Press (Medium Grip)', MuscleGroup.chest),
  _bb('Bench Press (Narrow Grip)', MuscleGroup.chest),
  _bb('Bench Press (Wide Grip)', MuscleGroup.chest),
  _bw('Bodyweight Squat', MuscleGroup.quads),
  _bw('Bulgarian Split Squat (Glute-Focused)', MuscleGroup.glutes),
  _bw('Bulgarian Split Squat (Quad-Focused)', MuscleGroup.quads),

  // ── C ──────────────────────────────────────────────────────────────────────
  _ca('Cable Bent Over Shrug', MuscleGroup.traps),
  _ca('Cable Chest Press', MuscleGroup.chest),
  _ca('Cable Cross Body Bent Lateral Raise', MuscleGroup.shoulders),
  _ca('Cable Cross Body Lateral Raise', MuscleGroup.shoulders),
  _ca('Cable Curl', MuscleGroup.biceps),
  _ca('Cable Curl (EZ Bar)', MuscleGroup.biceps),
  _ca('Cable Curl (EZ Bar, Wide Grip)', MuscleGroup.biceps),
  _ca('Cable Curl (Single-Arm)', MuscleGroup.biceps),
  _ca('Cable Flexion Row', MuscleGroup.back),
  _ca('Cable Fly', MuscleGroup.chest),
  _ca('Cable Fly (Bent Over)', MuscleGroup.chest),
  _ca('Cable Fly (High)', MuscleGroup.chest),
  _ca('Cable Fly (Seated)', MuscleGroup.chest),
  _ca('Cable Fly (Underhand)', MuscleGroup.chest),
  _ca('Cable Front Raise (Overhand)', MuscleGroup.shoulders),
  _ca('Cable Front Raise (Underhand)', MuscleGroup.shoulders),
  _ca('Cable Hammer Curl (Rope)', MuscleGroup.biceps),
  _ca('Cable Kickback', MuscleGroup.triceps),
  _ca('Cable Lateral Raise (Single-Arm)', MuscleGroup.shoulders),
  _ca('Cable Leaning Lateral Raise', MuscleGroup.shoulders),
  _ca('Cable Overhead Tricep Extension', MuscleGroup.triceps),
  _ca('Cable Overhead Tricep Extension (Rope)', MuscleGroup.triceps),
  _ca('Cable Pull Through', MuscleGroup.glutes),
  _ca('Cable Pullover', MuscleGroup.back),
  _ca('Cable Rope Crunch', MuscleGroup.abs),
  _ca('Cable Rope Facepull', MuscleGroup.shoulders),
  _ca('Cable Rope Facepull', MuscleGroup.traps),
  _ca('Cable Rope Facepull (Kneeling)', MuscleGroup.shoulders),
  _ca('Cable Rope Facepull (Kneeling)', MuscleGroup.traps),
  _ca('Cable Rope Twist Curl', MuscleGroup.biceps),
  _ca('Cable Shrug', MuscleGroup.traps),
  _ca('Cable Side Shrug', MuscleGroup.traps),
  _ca('Cable Single Arm Rear Delt Raise', MuscleGroup.shoulders),
  _ca('Cable Single Arm Side Shrug', MuscleGroup.traps),
  _ca('Cable Tricep Kickback', MuscleGroup.triceps),
  _ca('Cable Tricep Pushdown (Bar)', MuscleGroup.triceps),
  _ca('Cable Tricep Pushdown (Rope)', MuscleGroup.triceps),
  _ca('Cable Tricep Pushdown (Single-Arm)', MuscleGroup.triceps),
  _ca('Cable Upright Row', MuscleGroup.shoulders),
  _ca('Cable Upright Row', MuscleGroup.traps),
  _ca('Cable Wrist Curl', MuscleGroup.forearms),
  _mc('Calf Machine', MuscleGroup.calves),
  _bb('Cambered Bar Row', MuscleGroup.back),
  _db('Chest Supported Row', MuscleGroup.back),
  _db('Concentration Curl', MuscleGroup.biceps),

  // ── D ──────────────────────────────────────────────────────────────────────
  _bb('Deadlift', MuscleGroup.back),
  _bb('Deadlift', MuscleGroup.glutes),
  _bb('Deadlift (Deficit)', MuscleGroup.back),
  _bb('Deadlift (Flexion)', MuscleGroup.back),
  _bb('Deadlift (Sumo Stance)', MuscleGroup.glutes),
  _bb('Deadlift (Sumo Stance, Deficit)', MuscleGroup.glutes),
  _db('Decline Dumbbell Curl', MuscleGroup.biceps),
  _bw('Dip (Assisted, Chest-Focused)', MuscleGroup.chest),
  _bw('Dip (Assisted, Tricep-Focused)', MuscleGroup.triceps),
  _bw('Dip (Chest-Focused)', MuscleGroup.chest),
  _bw('Dip (Tricep-Focused)', MuscleGroup.triceps),
  _db('Dip (Weighted, Chest-Focused)', MuscleGroup.chest),
  _db('Dip (Weighted, Tricep-Focused)', MuscleGroup.triceps),
  _bw('Donkey Calf Raise', MuscleGroup.calves),
  _ca('Double Cable Pullover', MuscleGroup.back),
  _db('Dumbbell Bench Wrist Curl', MuscleGroup.forearms),
  _db('Dumbbell Bent Lateral Raise', MuscleGroup.shoulders),
  _db('Dumbbell Bent Over Shrug', MuscleGroup.traps),
  _db('Dumbbell Curl (2-Arm)', MuscleGroup.biceps),
  _db('Dumbbell Curl (Alternating)', MuscleGroup.biceps),
  _db('Dumbbell Curl (Incline, 45 deg)', MuscleGroup.biceps),
  _db('Dumbbell Curl (Lying)', MuscleGroup.biceps),
  _db('Dumbbell Facepull', MuscleGroup.shoulders),
  _db('Dumbbell Facepull', MuscleGroup.traps),
  _db('Dumbbell Facepull (Incline)', MuscleGroup.shoulders),
  _db('Dumbbell Facepull (Incline)', MuscleGroup.traps),
  _db('Dumbbell Flexion Row', MuscleGroup.back),
  _db('Dumbbell Flye (Flat)', MuscleGroup.chest),
  _db('Dumbbell Flye (Incline)', MuscleGroup.chest),
  _db('Dumbbell Front Raise', MuscleGroup.shoulders),
  _db('Dumbbell Front Squat', MuscleGroup.quads),
  _db('Dumbbell Hip Thrust (Single Leg)', MuscleGroup.glutes),
  _db('Dumbbell Lateral Raise', MuscleGroup.shoulders),
  _db('Dumbbell Lateral Raise (Incline)', MuscleGroup.shoulders),
  _db('Dumbbell Lateral Raise (Seated)', MuscleGroup.shoulders),
  _db('Dumbbell Lateral Raise (Super ROM)', MuscleGroup.shoulders),
  _db('Dumbbell Lateral Raise (Thumbs Down)', MuscleGroup.shoulders),
  _db('Dumbbell Lateral Raise (Top Hold)', MuscleGroup.shoulders),
  _db('Dumbbell Leaning Shrug', MuscleGroup.traps),
  _db('Dumbbell Overhead Extension', MuscleGroup.triceps),
  _db('Dumbbell Overhead Extension (Single-Arm)', MuscleGroup.triceps),
  _db('Dumbbell Preacher Curl (Single-Arm)', MuscleGroup.biceps),
  _db('Dumbbell Press (Flat)', MuscleGroup.chest),
  _db('Dumbbell Press (High Incline)', MuscleGroup.chest),
  _db('Dumbbell Press (High Incline)', MuscleGroup.shoulders),
  _db('Dumbbell Press (Low Incline)', MuscleGroup.chest),
  _db('Dumbbell Press (Medium Incline)', MuscleGroup.chest),
  _db('Dumbbell Press (Shoulders)', MuscleGroup.shoulders),
  _db('Dumbbell Press Flye (Flat)', MuscleGroup.chest),
  _db('Dumbbell Press Flye (Incline)', MuscleGroup.chest),
  _db('Dumbbell Pullover', MuscleGroup.back),
  _db('Dumbbell Row (2-Arm)', MuscleGroup.back),
  _db('Dumbbell Row (2-Arm, Incline)', MuscleGroup.back),
  _db('Dumbbell Row (Single-Arm, Supported)', MuscleGroup.back),
  _db('Dumbbell Row to Hips', MuscleGroup.back),
  _db('Dumbbell Shoulder Press (Seated)', MuscleGroup.shoulders),
  _db('Dumbbell Shoulder Press (Single-Arm, Supported)', MuscleGroup.shoulders),
  _db('Dumbbell Shrug', MuscleGroup.traps),
  _db('Dumbbell Shrug (Seated)', MuscleGroup.traps),
  _db('Dumbbell Skullcrusher', MuscleGroup.triceps),
  _db('Dumbbell Spider Curl', MuscleGroup.biceps),
  _db('Dumbbell Split Squat', MuscleGroup.quads),
  _db('Dumbbell Standing Wrist Curl', MuscleGroup.forearms),
  _db('Dumbbell Stiff Legged Deadlift', MuscleGroup.hamstrings),
  _db('Dumbbell Twist Curl', MuscleGroup.biceps),
  _db('Dumbbell Upright Row', MuscleGroup.shoulders),
  _db('Dumbbell Upright Row', MuscleGroup.traps),

  // ── E ──────────────────────────────────────────────────────────────────────
  _ez('EZ Bar Curl (Narrow Grip)', MuscleGroup.biceps),
  _ez('EZ Bar Curl (Normal Grip)', MuscleGroup.biceps),
  _ez('EZ Bar Curl (Wide Grip)', MuscleGroup.biceps),
  _ez('EZ Bar Overhead Tricep Extension', MuscleGroup.triceps),
  _ez('EZ Bar Overhead Tricep Extension (Seated)', MuscleGroup.triceps),
  _ez('EZ Bar Preacher Curl', MuscleGroup.biceps),
  _ez('EZ Bar Row (Underhand)', MuscleGroup.back),
  _ez('EZ Bar Skullcrusher', MuscleGroup.triceps),
  _ez('EZ Bar Spider Curl', MuscleGroup.biceps),

  // ── F ──────────────────────────────────────────────────────────────────────
  _ca('Freemotion Curl (Facing Away)', MuscleGroup.biceps),
  _ca('Freemotion Curl (Facing Machine)', MuscleGroup.biceps),
  _ca('Freemotion Curl (Single-Arm)', MuscleGroup.biceps),
  _ca('Freemotion Rear Delt Flyes', MuscleGroup.shoulders),
  _ca('Freemotion Y-Raises', MuscleGroup.shoulders),
  _ca('Freemotion Y-Raises', MuscleGroup.traps),
  _ca('Freemotion Y-Raises (Paused)', MuscleGroup.shoulders),
  _ca('Freemotion Y-Raises (Paused)', MuscleGroup.traps),
  _bb('Front Foot Elevated Smith Lunge', MuscleGroup.quads),
  _bb('Front Squat', MuscleGroup.quads),
  _bb('Front Squat (Cross Grip)', MuscleGroup.quads),

  // ── G ──────────────────────────────────────────────────────────────────────
  _db('Goblet Squat', MuscleGroup.quads),
  const MovementSeedEntry(
    name: 'Grip Roller',
    muscleGroup: MuscleGroup.forearms,
    minWeight: 5,
    weightDelta: 5,
  ),

  // ── H ──────────────────────────────────────────────────────────────────────
  _pm('Hack Squat', MuscleGroup.quads),
  _db('Hammer Curl', MuscleGroup.biceps),
  _mc('Hammer Machine Chest Press (Flat)', MuscleGroup.chest),
  _mc('Hammer Machine Chest Press (Incline)', MuscleGroup.chest),
  _mc('Hammer Machine Row (High)', MuscleGroup.back),
  _mc('Hammer Machine Row (Low)', MuscleGroup.back),
  _db('Hammer Preacher Curl', MuscleGroup.biceps),
  _bw('Hanging Knee Raise', MuscleGroup.abs),
  _bw('Hanging Straight Leg Raise', MuscleGroup.abs),
  _mc('Hip Abduction Machine', MuscleGroup.glutes),
  _mc('Hip Adduction', MuscleGroup.quads),

  // ── I ──────────────────────────────────────────────────────────────────────
  _bw('Inverted Row', MuscleGroup.back),
  _bw('Inverted Skullcrusher', MuscleGroup.triceps),

  // ── J ──────────────────────────────────────────────────────────────────────
  _bb('JM Press', MuscleGroup.triceps),

  // ── L ──────────────────────────────────────────────────────────────────────
  _bb('Landmine Row', MuscleGroup.back),
  _mc('Leg Extension', MuscleGroup.quads),
  _pm('Leg Press Calves', MuscleGroup.calves),
  _db('Lying Biceps Dumbbell Curl', MuscleGroup.biceps),
  _ca('Lying Cable Curl', MuscleGroup.biceps),
  _db('Lying Dumbbell Curl', MuscleGroup.biceps),
  _mc('Lying Leg Curl', MuscleGroup.hamstrings),

  // ── M ──────────────────────────────────────────────────────────────────────
  _mc('Machine Chest Press', MuscleGroup.chest),
  _mc('Machine Chest Press (Incline)', MuscleGroup.chest),
  _mc('Machine Chest Supported Row', MuscleGroup.back),
  _mc('Machine Crunch', MuscleGroup.abs),
  _mc('Machine Flye', MuscleGroup.chest),
  _mc('Machine Glute Kickback', MuscleGroup.glutes),
  _mc('Machine Hip Thrust', MuscleGroup.glutes),
  _mc('Machine Lateral Raise', MuscleGroup.shoulders),
  _mc('Machine Preacher Curl', MuscleGroup.biceps),
  _pd('Machine Pulldown'),
  _mc('Machine Pullover', MuscleGroup.back),
  _mc('Machine Reverse Fly', MuscleGroup.shoulders),
  _mc('Machine Shoulder Press', MuscleGroup.shoulders),
  _mc('Machine Shrug', MuscleGroup.traps),
  _mc('Machine Tricep Extension', MuscleGroup.triceps),
  _mc('Machine Tricep Pushdown', MuscleGroup.triceps),
  _bb('Meadows Row', MuscleGroup.back),
  _bw('Modified Candlestick', MuscleGroup.abs),

  // ── N ──────────────────────────────────────────────────────────────────────
  _bw('Nordic Curl', MuscleGroup.hamstrings),

  // ── P ──────────────────────────────────────────────────────────────────────
  _mc('Pec Dec Fly', MuscleGroup.chest),
  _pm('Pendulum Squat', MuscleGroup.quads),
  _pd('Pulldown (Narrow Grip)'),
  _pd('Pulldown (Normal Grip)'),
  _pd('Pulldown (Parallel Grip)'),
  _pd('Pulldown (Single-Arm)'),
  _pd('Pulldown (Straight Arm)'),
  _pd('Pulldown (Underhand Grip)'),
  _pd('Pulldown (Upright Torso to Abs)'),
  _bw('Pullup (Normal Grip)', MuscleGroup.back),
  _bw('Pullup (Parallel Grip)', MuscleGroup.back),
  _bw('Pullup (Underhand Grip)', MuscleGroup.back),
  _db('Pullup (Weighted, Normal Grip)', MuscleGroup.back),
  _db('Pullup (Weighted, Parallel Grip)', MuscleGroup.back),
  _db('Pullup (Weighted, Underhand Grip)', MuscleGroup.back),
  _db('Pullup (Weighted, Wide Grip)', MuscleGroup.back),
  _bw('Pullup (Wide Grip)', MuscleGroup.back),
  _bw('Pushup', MuscleGroup.chest),
  _bw('Pushup (Deficit)', MuscleGroup.chest),
  _bw('Pushup (Narrow Grip)', MuscleGroup.chest),
  _db('Pushup (Weighted, Narrow Grip)', MuscleGroup.chest),
  _db('Pushup (Weighted, Normal Grip)', MuscleGroup.chest),

  // ── R ──────────────────────────────────────────────────────────────────────
  _bw('Reaching Sit-Up', MuscleGroup.abs),
  _bb('Reverse Curl', MuscleGroup.forearms),
  _pm('Reverse Hyper', MuscleGroup.glutes),
  _bb('Reverse Lunge (Barbell)', MuscleGroup.quads),
  _db('Reverse Lunge (Dumbbell)', MuscleGroup.quads),
  _bb('Rogers Good Morning', MuscleGroup.hamstrings),
  _bb('Rogers Reverse Lunge', MuscleGroup.quads),
  _bb('Rogers Squat', MuscleGroup.quads),

  // ── S ──────────────────────────────────────────────────────────────────────
  _bb('Seal Row', MuscleGroup.back),
  _ca('Seated Cable Row', MuscleGroup.back),
  _ca('Seated Cable Row (Single-Arm)', MuscleGroup.back),
  _mc('Seated Leg Curl', MuscleGroup.hamstrings),
  _mc('Single Leg Extension', MuscleGroup.quads),
  _pm('Single Leg Press', MuscleGroup.quads),
  _db('Single Leg Romanian Deadlift', MuscleGroup.hamstrings),
  _mc('Single-Leg Leg Curl', MuscleGroup.hamstrings),
  _bw('Sissy Squat (Machine)', MuscleGroup.quads),
  _bw('Sissy Squat (No Machine)', MuscleGroup.quads),
  _db('Slant Board Sit-Up (Weighted)', MuscleGroup.abs),
  _bb('Smith Machine Bench Press (Medium Grip)', MuscleGroup.chest),
  _bb('Smith Machine Bench Press (Narrow Grip)', MuscleGroup.chest),
  _bb('Smith Machine Bench Press (Wide Grip)', MuscleGroup.chest),
  _bb('Smith Machine Calves', MuscleGroup.calves),
  _bb('Smith Machine Good Morning', MuscleGroup.hamstrings),
  _bb('Smith Machine JM Press', MuscleGroup.triceps),
  _bb('Smith Machine Press (High Incline, Medium Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (High Incline, Narrow Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (High Incline, Wide Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Incline, Medium Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Incline, Wide Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Low Incline, Medium Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Low Incline, Narrow Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Low Incline, Wide Grip)', MuscleGroup.chest),
  _bb('Smith Machine Press (Medium Incline, Wide Grip)', MuscleGroup.chest),
  _bb('Smith Machine Row', MuscleGroup.back),
  _bb('Smith Machine Shoulder Press (Seated)', MuscleGroup.shoulders),
  _bb('Smith Machine Shrug', MuscleGroup.traps),
  _bb('Smith Machine Skullcrusher', MuscleGroup.triceps),
  _bb('Smith Machine Split Squat', MuscleGroup.quads),
  _bb('Smith Machine Squat (Feet Forward)', MuscleGroup.quads),
  _bb('Smith Machine Upright Row', MuscleGroup.shoulders),
  _bb('Smith Machine Upright Row', MuscleGroup.traps),
  _bw('Stair Calves', MuscleGroup.calves),
  _bw('Stair Calves (Single Leg)', MuscleGroup.calves),
  _bw('Standing Calf Raise', MuscleGroup.calves),
  _bb('Stiff-Legged Deadlift', MuscleGroup.hamstrings),

  // ── T ──────────────────────────────────────────────────────────────────────
  _bb('T-Bar Row', MuscleGroup.back),
  _bb('Trap Bar Deadlift', MuscleGroup.back),

  // ── V ──────────────────────────────────────────────────────────────────────
  _db('V-Up (Weighted)', MuscleGroup.abs),

  // ── Cardio ─────────────────────────────────────────────────────────────────
  _cardio('Rowing'),
  _cardio('Running/Jogging'),

  // ── W ──────────────────────────────────────────────────────────────────────
  _bb('Walking Lunges (Glute-Focused, Barbell)', MuscleGroup.glutes),
  _bw('Walking Lunges (Glute-Focused, Bodyweight)', MuscleGroup.glutes),
  _db('Walking Lunges (Glute-Focused, Dumbbell)', MuscleGroup.glutes),
  _bb('Walking Lunges (Quad-Focused, Barbell)', MuscleGroup.quads),
  _bw('Walking Lunges (Quad-Focused, Bodyweight)', MuscleGroup.quads),
  _db('Walking Lunges (Quad-Focused, Dumbbell)', MuscleGroup.quads),
];
