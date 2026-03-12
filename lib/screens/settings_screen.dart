import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_preferences.dart';
import '../services/backup_service.dart';
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

  String? _backupDirPath;
  DateTime? _lastBackupTimestamp;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _aiEnabled = AppPreferences.getAiEnabled();
    _unitsMetric = AppPreferences.getUnitsMetric();
    _backupDirPath = AppPreferences.getBackupDirectoryPath();
    _lastBackupTimestamp = AppPreferences.getLastBackupTimestamp();
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

  Future<void> _pickBackupLocation() async {
    var status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      status = await Permission.manageExternalStorage.request();
      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission required to set backup location.'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
        return;
      }
    }
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;
    await AppPreferences.setBackupDirectoryPath(dirPath);
    if (mounted) setState(() => _backupDirPath = dirPath);
  }

  Future<void> _backupNow() async {
    setState(() => _isBusy = true);
    try {
      await BackupService.backup(_backupDirPath!);
      final ts = AppPreferences.getLastBackupTimestamp();
      if (mounted) {
        setState(() => _lastBackupTimestamp = ts);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup complete.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _restoreFromBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from backup?'),
        content: const Text(
            'This will replace all current data. The app will need to restart afterward.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Restore')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await BackupService.restore(path);
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Restore complete'),
            content: const Text(
                'Please close and reopen the app to apply the restored data.'),
            actions: [
              FilledButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Close app'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  String _formatTimestamp(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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
          Text('OpenRouter API Key (not implimented)',
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
                hintText: 'sk-or-...',
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
          const SizedBox(height: 32),

          // ── Backup ────────────────────────────────────────────────────────
          Text('Backup', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _backupDirPath ?? 'No backup location set',
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: _isBusy ? null : _pickBackupLocation,
                child: const Text('Change'),
              ),
            ],
          ),
          if (_lastBackupTimestamp != null) ...[
            const SizedBox(height: 2),
            Text(
              'Last backup: ${_formatTimestamp(_lastBackupTimestamp!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_backupDirPath == null || _isBusy) ? null : _backupNow,
                  child: _isBusy
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Back Up Now'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isBusy ? null : _restoreFromBackup,
                  child: const Text('Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
