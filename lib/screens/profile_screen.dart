import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTime? _dateOfBirth;
  final _weightController = TextEditingController();
  TrainingGoal? _trainingGoal;
  CalorieState? _calorieState;

  @override
  void initState() {
    super.initState();
    _dateOfBirth = AppPreferences.getDateOfBirth();
    final weight = AppPreferences.getWeight();
    if (weight != null) _weightController.text = weight.toString();
    _trainingGoal = AppPreferences.getTrainingGoal();
    _calorieState = AppPreferences.getCalorieState();
  }

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 10),
      helpText: 'Select Date of Birth',
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    final weight = double.tryParse(_weightController.text.trim());
    await AppPreferences.setDateOfBirth(_dateOfBirth);
    await AppPreferences.setWeight(weight);
    await AppPreferences.setTrainingGoal(_trainingGoal);
    await AppPreferences.setCalorieState(_calorieState);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
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

  String _formatDob(DateTime dob) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return '${months[dob.month - 1]} ${dob.day}, ${dob.year}  (age $age)';
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
          // ── Date of Birth ─────────────────────────────────────────────────
          InkWell(
            onTap: _pickDateOfBirth,
            borderRadius: BorderRadius.circular(4),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date of Birth',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              child: Text(
                _dateOfBirth != null
                    ? _formatDob(_dateOfBirth!)
                    : 'Tap to select',
                style: _dateOfBirth == null
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Weight ───────────────────────────────────────────────────────
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight',
              border: const OutlineInputBorder(),
              suffixText: AppPreferences.getUnitsMetric() ? 'kg' : 'lbs',
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
