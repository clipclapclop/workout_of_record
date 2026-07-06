import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/db/app_database.dart';
import 'package:workout_of_record/db/tables/enums.dart';
import 'package:workout_of_record/db/template_data.dart';
import 'package:workout_of_record/screens/past_week_review_screen.dart';

void main() {
  testWidgets('past week review explains and offers use or edit', (
    tester,
  ) async {
    final movement = Movement(
      id: 1,
      name: 'Curl',
      muscleGroup: MuscleGroup.biceps,
      isRequiredReps: true,
      isRequiredWeight: true,
      isRequiredTime: false,
      isRequiredDistance: false,
      category: MovementCategory.resistance,
      bodyweightLoadFraction: 0,
    );
    final day = WorkoutDayData(
      template: const WorkoutTemplate(
        id: -1,
        weekTemplateId: -1,
        name: 'Monday',
        isRestDay: false,
        dayIndex: 0,
      ),
      exercises: [ExerciseDayEntry(movement: movement, autoProgress: true)],
    );
    final associated = MesoTemplateData(
      template: MesoTemplate(
        id: 4,
        name: 'Push/Pull',
        createdAt: DateTime(2025),
      ),
      days: [day],
    );
    final data = PastWeekTemplateData(
      mesocycle: Mesocycle(
        id: 8,
        mesoTemplateId: 4,
        name: 'Spring Block',
        totalWeekCount: 4,
        createdAt: DateTime(2025, 3),
        completedAt: DateTime(2025, 4),
      ),
      week: Week(
        id: 12,
        mesocycleId: 8,
        weekNumber: 3,
        goal: WeekGoal.hard,
        createdAt: DateTime(2025, 3, 15),
      ),
      weekData: MesoTemplateData(
        template: MesoTemplate(
          id: -1,
          name: 'From Spring Block W3',
          createdAt: DateTime(2025, 4),
        ),
        days: [day],
      ),
      associatedTemplate: associated,
    );

    await tester.pumpWidget(
      MaterialApp(home: PastWeekReviewScreen(data: data)),
    );

    expect(find.text('Review Week 3'), findsOneWidget);
    expect(find.text('Curl'), findsOneWidget);
    expect(find.text('Edit Week'), findsOneWidget);
    expect(find.text('Use Week'), findsOneWidget);
    expect(find.textContaining('Push/Pull'), findsOneWidget);
  });
}
