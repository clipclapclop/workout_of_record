import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  TrainingGoal? _trainingGoal;
  CalorieState? _calorieState;

  @override
  void initState() {
    super.initState();
    final age = AppPreferences.getAge();
    final weight = AppPreferences.getWeight();
    if (age != null) _ageController.text = age.toString();
    if (weight != null) _weightController.text = weight.toString();
    _trainingGoal = AppPreferences.getTrainingGoal();
    _calorieState = AppPreferences.getCalorieState();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final age = int.tryParse(_ageController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());
    await AppPreferences.setAge(age);
    await AppPreferences.setWeight(weight);
    await AppPreferences.setTrainingGoal(_trainingGoal);
    await AppPreferences.setCalorieState(_calorieState);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved.')),
      );
    }
  }

  void _showCalorieStateInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calorie State'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Surplus', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('You are eating more than you burn — intentionally gaining weight.'),
            SizedBox(height: 12),
            Text('Maintenance', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('You are eating roughly what you burn — weight is stable.'),
            SizedBox(height: 12),
            Text('Deficit', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('You are eating less than you burn — intentionally losing weight.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [AppNavMenu(current: AppScreen.profile)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Age ──────────────────────────────────────────────────────────
          TextField(
            controller: _ageController,
            decoration: const InputDecoration(
              labelText: 'Age',
              border: OutlineInputBorder(),
              suffixText: 'years',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // ── Weight ───────────────────────────────────────────────────────
          TextField(
            controller: _weightController,
            decoration: const InputDecoration(
              labelText: 'Weight',
              border: OutlineInputBorder(),
              suffixText: 'kg',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 24),

          // ── Training Goal ─────────────────────────────────────────────────
          Text('Training Goal', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          RadioGroup<TrainingGoal>(
            groupValue: _trainingGoal,
            onChanged: (v) => setState(() => _trainingGoal = v),
            child: Column(
              children: [
                for (final goal in TrainingGoal.values)
                  RadioListTile<TrainingGoal>(
                    title: Text(_trainingGoalLabel(goal)),
                    value: goal,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Calorie State ─────────────────────────────────────────────────
          Row(
            children: [
              Text('Calorie State',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.info_outline, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _showCalorieStateInfo(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RadioGroup<CalorieState>(
            groupValue: _calorieState,
            onChanged: (v) => setState(() => _calorieState = v),
            child: Column(
              children: [
                for (final state in CalorieState.values)
                  RadioListTile<CalorieState>(
                    title: Text(_calorieStateLabel(state)),
                    value: state,
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          FilledButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  String _trainingGoalLabel(TrainingGoal g) => switch (g) {
        TrainingGoal.strength => 'Strength',
        TrainingGoal.hypertrophy => 'Hypertrophy',
        TrainingGoal.endurance => 'Endurance',
        TrainingGoal.general => 'General',
      };

  String _calorieStateLabel(CalorieState s) => switch (s) {
        CalorieState.surplus => 'Surplus',
        CalorieState.maintenance => 'Maintenance',
        CalorieState.deficit => 'Deficit',
      };
}
