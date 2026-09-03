import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';
import '../widgets/app_nav_menu.dart';
import '../widgets/unsaved_changes_dialog.dart';
import '../workout_units.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _dateOfBirth;
  final _weightController = TextEditingController();
  final _liftingYearsController = TextEditingController();
  TrainingGoal? _trainingGoal;
  CalorieState? _calorieState;
  late (DateTime?, String, String, TrainingGoal?, CalorieState?) _savedDraft;

  (DateTime?, String, String, TrainingGoal?, CalorieState?) get _currentDraft => (
        _dateOfBirth,
        _weightController.text.trim(),
        _liftingYearsController.text.trim(),
        _trainingGoal,
        _calorieState,
      );

  bool get _hasUnsavedChanges => _currentDraft != _savedDraft;

  @override
  void initState() {
    super.initState();
    _dateOfBirth = AppPreferences.getDateOfBirth();
    final weight = AppPreferences.getWeight();
    if (weight != null) _weightController.text = weight.toString();
    _trainingGoal = AppPreferences.getTrainingGoal();
    _calorieState = AppPreferences.getCalorieState();
    final startDate = AppPreferences.getTrainingStartDate();
    if (startDate != null) {
      final years = DateTime.now().difference(startDate).inDays / 365.25;
      final rounded = double.parse(years.toStringAsFixed(1));
      _liftingYearsController.text =
          rounded == rounded.truncateToDouble() ? rounded.toInt().toString() : rounded.toString();
    }
    _savedDraft = _currentDraft;
  }

  @override
  void dispose() {
    _weightController.dispose();
    _liftingYearsController.dispose();
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

  String? _validateWeight(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value <= 0) {
      return 'Enter a number greater than 0';
    }
    return null;
  }

  String? _validateLiftingYears(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null || !value.isFinite || value < 0) {
      return 'Enter a number of 0 or more';
    }
    return null;
  }

  Future<bool> _persist() async {
    if (!_formKey.currentState!.validate()) return false;
    final weight = double.tryParse(_weightController.text.trim());
    final liftingYears = double.tryParse(_liftingYearsController.text.trim());
    DateTime? trainingStartDate;
    if (liftingYears != null && liftingYears > 0) {
      final days = (liftingYears * 365.25).round();
      trainingStartDate = DateTime.now().subtract(Duration(days: days));
    }
    try {
      await AppPreferences.setDateOfBirth(_dateOfBirth);
      await AppPreferences.setWeight(weight);
      await AppPreferences.setTrainingGoal(_trainingGoal);
      await AppPreferences.setCalorieState(_calorieState);
      await AppPreferences.setTrainingStartDate(trainingStartDate);
      if (mounted) setState(() => _savedDraft = _currentDraft);
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Couldn’t save profile.')),
        );
      }
      return false;
    }
  }

  Future<void> _save() async {
    if (!await _persist() || !mounted) return;
    if (widget.activeWorkoutId != null) {
      AppNavMenu.returnToActiveWorkout(
        context,
        activeWorkoutId: widget.activeWorkoutId!,
        activeWorkoutName: widget.activeWorkoutName,
      );
      return;
    }
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (_) => false,
    );
  }

  /// Persist if requested, then let AppNavMenu open the selected destination.
  Future<bool> _confirmMenuNavigation() async {
    if (!_hasUnsavedChanges) return true;
    final action = await showUnsavedChangesDialog(context);
    return switch (action) {
      UnsavedChangesAction.keepEditing => false,
      UnsavedChangesAction.discard => true,
      UnsavedChangesAction.save => _persist(),
    };
  }

  Future<void> _handleSystemBack() async {
    if (!_hasUnsavedChanges) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final action = await showUnsavedChangesDialog(context);
    if (!mounted || action == UnsavedChangesAction.keepEditing) return;
    if (action == UnsavedChangesAction.discard) {
      Navigator.pop(context);
      return;
    }
    if (!await _persist() || !mounted) return;
    if (widget.activeWorkoutId != null) {
      AppNavMenu.returnToActiveWorkout(
        context,
        activeWorkoutId: widget.activeWorkoutId!,
        activeWorkoutName: widget.activeWorkoutName,
      );
    } else {
      Navigator.pop(context);
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _handleSystemBack();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.profile,
            activeWorkoutId: widget.activeWorkoutId,
            activeWorkoutName: widget.activeWorkoutName,
            onNavigateAway: _confirmMenuNavigation,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
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

          // ── Weight and experience ────────────────────────────────────────
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _weightController,
                  decoration: InputDecoration(
                    labelText: 'Weight',
                    border: const OutlineInputBorder(),
                    suffixText: WorkoutUnits.weight,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateWeight,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _liftingYearsController,
                  decoration: const InputDecoration(
                    labelText: 'Years lifting / exercising',
                    hintText: 'e.g. 3.5',
                    border: OutlineInputBorder(),
                    suffixText: 'yrs',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: _validateLiftingYears,
                ),
              ],
            ),
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
