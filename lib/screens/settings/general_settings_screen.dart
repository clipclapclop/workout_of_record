import 'package:flutter/material.dart';
import '../../app_preferences.dart';
import 'unsaved_settings_dialog.dart';

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
    final result = await showUnsavedSettingsDialog(context);
    if (result == UnsavedSettingsAction.save) {
      await _save();
      return true;
    }
    return result == UnsavedSettingsAction.discard;
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
