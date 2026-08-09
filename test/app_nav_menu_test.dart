import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_of_record/screens/workout_screen.dart';
import 'package:workout_of_record/widgets/app_nav_menu.dart';

void main() {
  testWidgets('app menu and History return keep the workout route mounted', (
    tester,
  ) async {
    var initCount = 0;
    var disposeCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        initialRoute: WorkoutScreen.routeName,
        onGenerateRoute: (_) => null,
        onGenerateInitialRoutes: (initialRoute) => [
          MaterialPageRoute<void>(
            settings: RouteSettings(name: initialRoute),
            builder: (_) => _ActiveWorkoutSentinel(
              onInit: () => initCount++,
              onDispose: () => disposeCount++,
            ),
          ),
        ],
      ),
    );

    expect(initCount, 1);
    expect(disposeCount, 0);

    await tester.tap(find.byType(PopupMenuButton<AppScreen>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(initCount, 1);
    expect(disposeCount, 0);

    await tester.tap(find.byType(PopupMenuButton<AppScreen>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    expect(find.text('Active workout'), findsOneWidget);
    expect(initCount, 1);
    expect(disposeCount, 0);

    await tester.tap(find.text('Open test History'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PopupMenuButton<AppScreen>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Workout'));
    await tester.pumpAndSettle();

    expect(find.text('Active workout'), findsOneWidget);
    expect(initCount, 1);
    expect(disposeCount, 0);
  });
}

class _ActiveWorkoutSentinel extends StatefulWidget {
  const _ActiveWorkoutSentinel({required this.onInit, required this.onDispose});

  final VoidCallback onInit;
  final VoidCallback onDispose;

  @override
  State<_ActiveWorkoutSentinel> createState() => _ActiveWorkoutSentinelState();
}

class _ActiveWorkoutSentinelState extends State<_ActiveWorkoutSentinel> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active workout'),
        actions: const [
          AppNavMenu(
            current: AppScreen.workout,
            activeWorkoutId: 42,
            activeWorkoutName: 'Test workout',
          ),
        ],
      ),
      body: Center(
        child: FilledButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) => Scaffold(
                appBar: AppBar(
                  title: const Text('Test History'),
                  actions: const [
                    AppNavMenu(
                      current: AppScreen.history,
                      activeWorkoutId: 42,
                      activeWorkoutName: 'Test workout',
                    ),
                  ],
                ),
              ),
            ),
          ),
          child: const Text('Open test History'),
        ),
      ),
    );
  }
}
