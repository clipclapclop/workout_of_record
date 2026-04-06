import 'package:flutter/material.dart';
import '../../app_preferences.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late bool _unitsMetric;
  late bool _initUnitsMetric;

  bool get _hasUnsavedChanges => _unitsMetric != _initUnitsMetric;

  @override
  void initState() {
    super.initState();
    _unitsMetric = AppPreferences.getUnitsMetric();
    _initUnitsMetric = _unitsMetric;
  }

  Future<void> _save() async {
    await AppPreferences.setUnitsMetric(_unitsMetric);
    _initUnitsMetric = _unitsMetric;
  }

  Future<bool> _onPop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text('You have unsaved settings.'),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, 'dismiss'),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, 'save'),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (result == 'save') {
      await _save();
      return true;
    }
    return result == 'dismiss';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _onPop();
        if (ok && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('General')),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: FilledButton(
              onPressed: () async {
                await _save();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card.outlined(
              child: SwitchListTile(
                title: const Text('Metric units'),
                subtitle: Text(_unitsMetric ? 'kg' : 'lbs'),
                value: _unitsMetric,
                onChanged: (v) => setState(() => _unitsMetric = v),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
