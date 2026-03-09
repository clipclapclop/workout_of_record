import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../widgets/app_nav_menu.dart';
import 'home_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _aiEnabled;
  late bool _unitsMetric;
  final _apiKeyController = TextEditingController();
  bool _apiKeyLoading = true;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    _aiEnabled = AppPreferences.getAiEnabled();
    _unitsMetric = AppPreferences.getUnitsMetric();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await AppPreferences.getApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _apiKeyLoading = false;
      });
    }
  }

  Future<void> _save() async {
    final value = _apiKeyController.text.trim();
    await AppPreferences.setApiKey(value.isEmpty ? null : value);
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [AppNavMenu(current: AppScreen.settings)],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // ── Units ─────────────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Use metric units'),
            subtitle: Text(_unitsMetric ? 'kg' : 'lbs'),
            value: _unitsMetric,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) async {
              setState(() => _unitsMetric = v);
              await AppPreferences.setUnitsMetric(v);
            },
          ),
          const SizedBox(height: 8),

          // ── AI Recommendations ────────────────────────────────────────────
          SwitchListTile(
            title: const Text('AI Recommendations'),
            subtitle: const Text(
                'Use AI to pre-fill set targets based on your history and profile.'),
            value: _aiEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) async {
              setState(() => _aiEnabled = v);
              await AppPreferences.setAiEnabled(v);
            },
          ),
          const SizedBox(height: 24),

          // ── API Key ───────────────────────────────────────────────────────
          Text('Anthropic API Key',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_apiKeyLoading)
            const LinearProgressIndicator()
          else
            TextField(
              controller: _apiKeyController,
              obscureText: _obscureApiKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'sk-ant-...',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureApiKey ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscureApiKey = !_obscureApiKey),
                ),
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _apiKeyLoading ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
