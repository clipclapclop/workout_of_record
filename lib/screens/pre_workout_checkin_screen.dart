import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../db/db.dart';
import '../db/tables/enums.dart';
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
  // Soreness defaults — most benign = none
  Soreness _quads = Soreness.none;
  Soreness _hamstrings = Soreness.none;
  Soreness _abs = Soreness.none;
  Soreness _chest = Soreness.none;
  Soreness _back = Soreness.none;
  Soreness _biceps = Soreness.none;
  Soreness _triceps = Soreness.none;
  Soreness _traps = Soreness.none;
  Soreness _forearms = Soreness.none;
  Soreness _glutes = Soreness.none;
  Soreness _calves = Soreness.none;
  Soreness _shoulders = Soreness.none;

  // Status defaults — most benign = great
  CurrentState _sleepQuality = CurrentState.great;
  CurrentState _vimVigor = CurrentState.great;
  CurrentState _mentalState = CurrentState.great;

  Future<void> _submit() async {
    await db.savePreWorkoutCheckin(PreWorkoutCheckinsCompanion.insert(
      workoutId: widget.workoutId,
      quads: Value(_quads),
      hamstrings: Value(_hamstrings),
      abs: Value(_abs),
      chest: Value(_chest),
      back: Value(_back),
      biceps: Value(_biceps),
      triceps: Value(_triceps),
      traps: Value(_traps),
      forearms: Value(_forearms),
      glutes: Value(_glutes),
      calves: Value(_calves),
      shoulders: Value(_shoulders),
      sleepQuality: Value(_sleepQuality),
      vimVigor: Value(_vimVigor),
      mentalState: Value(_mentalState),
    ));
    final completedWorkoutId =
        await db.initializeWorkout(widget.workoutId);
    if (!mounted) return;
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          completedWorkoutId: completedWorkoutId,
          workoutName: widget.workoutName,
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
                _sectionHeader('Soreness'),
                ..._sorenessRows(),
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

  List<Widget> _sorenessRows() => [
        _sorenessRow('Quads', _quads, (v) => setState(() => _quads = v!)),
        _sorenessRow('Hamstrings', _hamstrings,
            (v) => setState(() => _hamstrings = v!)),
        _sorenessRow('Abs', _abs, (v) => setState(() => _abs = v!)),
        _sorenessRow('Chest', _chest, (v) => setState(() => _chest = v!)),
        _sorenessRow('Back', _back, (v) => setState(() => _back = v!)),
        _sorenessRow('Biceps', _biceps, (v) => setState(() => _biceps = v!)),
        _sorenessRow(
            'Triceps', _triceps, (v) => setState(() => _triceps = v!)),
        _sorenessRow('Traps', _traps, (v) => setState(() => _traps = v!)),
        _sorenessRow(
            'Forearms', _forearms, (v) => setState(() => _forearms = v!)),
        _sorenessRow('Glutes', _glutes, (v) => setState(() => _glutes = v!)),
        _sorenessRow('Calves', _calves, (v) => setState(() => _calves = v!)),
        _sorenessRow(
            'Shoulders', _shoulders, (v) => setState(() => _shoulders = v!)),
      ];

  List<Widget> _statusRows() => [
        _statusRow('Sleep Quality', _sleepQuality,
            (v) => setState(() => _sleepQuality = v!)),
        _statusRow(
            'Energy', _vimVigor, (v) => setState(() => _vimVigor = v!)),
        _statusRow('Mental State', _mentalState,
            (v) => setState(() => _mentalState = v!)),
      ];

  Widget _sorenessRow(
      String label, Soreness value, ValueChanged<Soreness?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          SegmentedButton<Soreness>(
            segments: const [
              ButtonSegment(value: Soreness.none, label: Text('None')),
              ButtonSegment(value: Soreness.aLittle, label: Text('A Little')),
              ButtonSegment(value: Soreness.some, label: Text('Some')),
              ButtonSegment(value: Soreness.lots, label: Text('Lots')),
            ],
            selected: {value},
            onSelectionChanged: (s) => onChanged(s.first),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }

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
