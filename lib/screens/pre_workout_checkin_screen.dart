import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
import '../widgets/body_map_widget.dart';
import 'workout_screen.dart';

class PreWorkoutCheckinScreen extends StatefulWidget {
  const PreWorkoutCheckinScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  final int workoutId;
  final String workoutName;

  @override
  State<PreWorkoutCheckinScreen> createState() =>
      _PreWorkoutCheckinScreenState();
}

class _PreWorkoutCheckinScreenState extends State<PreWorkoutCheckinScreen> {
  final Map<MuscleGroup, Soreness> _soreness = {
    for (final m in MuscleGroup.values) m: Soreness.none,
  };

  // Status defaults — most benign = great
  CurrentState _sleepQuality = CurrentState.great;
  CurrentState _vimVigor = CurrentState.great;
  CurrentState _mentalState = CurrentState.great;

  Future<void> _submit() async {
    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: widget.workoutId,
      quads: Value(_soreness[MuscleGroup.quads]!),
      hamstrings: Value(_soreness[MuscleGroup.hamstrings]!),
      abs: Value(_soreness[MuscleGroup.abs]!),
      chest: Value(_soreness[MuscleGroup.chest]!),
      back: Value(_soreness[MuscleGroup.back]!),
      biceps: Value(_soreness[MuscleGroup.biceps]!),
      triceps: Value(_soreness[MuscleGroup.triceps]!),
      traps: Value(_soreness[MuscleGroup.traps]!),
      forearms: Value(_soreness[MuscleGroup.forearms]!),
      glutes: Value(_soreness[MuscleGroup.glutes]!),
      calves: Value(_soreness[MuscleGroup.calves]!),
      shoulders: Value(_soreness[MuscleGroup.shoulders]!),
      tibialis: Value(_soreness[MuscleGroup.tibialis]!),
      sleepQuality: Value(_sleepQuality),
      vimVigor: Value(_vimVigor),
      mentalState: Value(_mentalState),
    ));
    await db.generatePlannedWorkout(widget.workoutId);
    final completedWorkoutId = await db.initializeWorkout(widget.workoutId);
    await AppPreferences.setCurrentCompletedWorkoutId(completedWorkoutId);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          completedWorkoutId: completedWorkoutId,
          workoutName: widget.workoutName,
          mesocycleId: AppPreferences.getCurrentMesocycleId()!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _sectionHeader("Today's Soreness"),
                BodyMapWidget(
                  soreness: _soreness,
                  onChanged: (muscle, soreness) =>
                      setState(() => _soreness[muscle] = soreness),
                ),
                const SizedBox(height: 24),
                _sectionHeader("Today's Status"),
                ..._statusRows(),
              ],
            ),
          ),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );

  List<Widget> _statusRows() => [
        _statusRow('Sleep Quality', _sleepQuality,
            (v) => setState(() => _sleepQuality = v!)),
        _statusRow(
            'Energy', _vimVigor, (v) => setState(() => _vimVigor = v!)),
        _statusRow('Mental State', _mentalState,
            (v) => setState(() => _mentalState = v!)),
      ];

  Widget _statusRow(String label, CurrentState value,
      ValueChanged<CurrentState?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          SegmentedButton<CurrentState>(
            segments: const [
              ButtonSegment(value: CurrentState.bad, label: Text('Bad')),
              ButtonSegment(
                  value: CurrentState.notGood, label: Text('Not Good')),
              ButtonSegment(value: CurrentState.good, label: Text('Good')),
              ButtonSegment(value: CurrentState.great, label: Text('Great')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submit,
            child: const Text('Submit'),
          ),
        ),
      ),
    );
  }
}
