import '../tables/enums.dart';

class MovementRef {
  final String name;
  final MuscleGroup muscleGroup;

  const MovementRef(this.name, this.muscleGroup);
}

class MesoTemplateSeedDay {
  final String name;
  final bool isRestDay;
  final List<MovementRef> movements;

  const MesoTemplateSeedDay({
    required this.name,
    this.isRestDay = false,
    this.movements = const [],
  });
}

class MesoTemplateSeedEntry {
  final String name;
  final String weekName;
  final List<MesoTemplateSeedDay> days;

  const MesoTemplateSeedEntry({
    required this.name,
    required this.weekName,
    required this.days,
  });
}

final kMesoTemplateSeeds = <MesoTemplateSeedEntry>[
  MesoTemplateSeedEntry(
    name: 'Full Body (Back Focus)',
    weekName: 'Standard Week',
    days: [
      MesoTemplateSeedDay(
        name: 'Monday',
        movements: [
          MovementRef('Barbell Bent Over Row', MuscleGroup.back),
          MovementRef('Barbell Pullover', MuscleGroup.back),
          MovementRef('Dumbbell Curl (Lying)', MuscleGroup.biceps),
          MovementRef('Dumbbell Lateral Raise', MuscleGroup.shoulders),
          MovementRef('Hanging Straight Leg Raise', MuscleGroup.abs),
        ],
      ),
      MesoTemplateSeedDay(
        name: 'Tuesday',
        movements: [
          MovementRef('Dumbbell Press (Medium Incline)', MuscleGroup.chest),
          MovementRef('Cable Flye', MuscleGroup.chest),
          MovementRef('Dumbbell Overhead Extension', MuscleGroup.triceps),
          MovementRef('EZ Bar Skullcrusher', MuscleGroup.triceps),
          MovementRef('Barbell Squat (High Bar)', MuscleGroup.quads),
          MovementRef('Barbell Good Morning (High Bar)', MuscleGroup.hamstrings),
        ],
      ),
      MesoTemplateSeedDay(
        name: 'Wednesday',
        movements: [
          MovementRef('Dumbbell Lateral Raise', MuscleGroup.shoulders),
          MovementRef('Cable Rope Facepull', MuscleGroup.shoulders),
          MovementRef('Pulldown (Underhand Grip)', MuscleGroup.back),
          MovementRef('Dumbbell Curl (Incline)', MuscleGroup.biceps),
          MovementRef('Dumbbell Bench Wrist Curl', MuscleGroup.forearms),
        ],
      ),
      MesoTemplateSeedDay(
        name: 'Thursday',
        movements: [
          MovementRef('Dumbbell Flye (Incline)', MuscleGroup.chest),
          MovementRef('Bench Press (Medium Grip)', MuscleGroup.chest),
          MovementRef('Cable Overhead Triceps Extension', MuscleGroup.triceps),
          MovementRef('Sissy Squat (No Machine)', MuscleGroup.quads),
          MovementRef('Nordic Curl', MuscleGroup.hamstrings),
        ],
      ),
      MesoTemplateSeedDay(
        name: 'Friday',
        movements: [
          MovementRef('Pulldown (Wide Grip)', MuscleGroup.back),
          MovementRef('Cable Flexion Row', MuscleGroup.back),
          MovementRef('Cable Curl', MuscleGroup.biceps),
          MovementRef('Dumbbell Upright Row', MuscleGroup.shoulders),
          MovementRef('Bar Hang', MuscleGroup.forearms),
        ],
      ),
    ],
  ),
];
