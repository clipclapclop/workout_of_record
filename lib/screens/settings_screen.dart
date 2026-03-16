import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../app_preferences.dart';
import '../db/tables/enums.dart';
import '../services/backup_scheduler.dart';
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

  late bool _timerEnabled;
  late TimerSound _timerSound;
  late bool _timerHaptic;
  late bool _timerKeepAwake;
  late int _timerDefaultSeconds;
  late final TextEditingController _timerSecondsCtrl;

  bool _backupEnabled = false;
  bool _autoBackupEnabled = false;
  int _backupHour = 2;
  int _backupMinute = 0;
  String? _backupDirPath;
  DateTime? _lastBackupTimestamp;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _aiEnabled = AppPreferences.getAiEnabled();
    _unitsMetric = AppPreferences.getUnitsMetric();
    _timerEnabled = AppPreferences.getTimerEnabled();
    _timerSound = AppPreferences.getTimerSound();
    _timerHaptic = AppPreferences.getTimerHaptic();
    _timerKeepAwake = AppPreferences.getTimerKeepAwake();
    _timerDefaultSeconds = AppPreferences.getTimerDefaultSeconds();
    _timerSecondsCtrl =
        TextEditingController(text: _timerDefaultSeconds.toString());
    _backupEnabled = AppPreferences.getBackupEnabled();
    _autoBackupEnabled = AppPreferences.getAutoBackupEnabled();
    _backupHour = AppPreferences.getBackupHour();
    _backupMinute = AppPreferences.getBackupMinute();
    _backupDirPath = AppPreferences.getBackupDirectoryPath();
    _lastBackupTimestamp = AppPreferences.getLastBackupTimestamp();
    _loadApiKey();
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _timerSecondsCtrl.dispose();
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: _apiKeyLoading ? null : _save,
            child: const Text('Save'),
          ),
        ),
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

          // ── Rest Timer ────────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Rest Timer'),
            subtitle: const Text('Show a countdown timer between sets.'),
            value: _timerEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) async {
              setState(() => _timerEnabled = v);
              await AppPreferences.setTimerEnabled(v);
            },
          ),
          if (_timerEnabled) ...[
            const SizedBox(height: 4),
            TextField(
              controller: _timerSecondsCtrl,
              decoration: const InputDecoration(
                labelText: 'Default rest (seconds)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) async {
                final seconds = int.tryParse(v.trim());
                if (seconds != null && seconds > 0) {
                  _timerDefaultSeconds = seconds;
                  await AppPreferences.setTimerDefaultSeconds(seconds);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text('Sound'),
            RadioGroup<TimerSound>(
              groupValue: _timerSound,
              onChanged: (v) async {
                setState(() => _timerSound = v!);
                await AppPreferences.setTimerSound(v!);
              },
              child: Column(
                children: const [
                  RadioListTile<TimerSound>(
                    title: Text('Read target value aloud'),
                    value: TimerSound.tts,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<TimerSound>(
                    title: Text('Chime ("ready")'),
                    value: TimerSound.chime,
                    contentPadding: EdgeInsets.zero,
                  ),
                  RadioListTile<TimerSound>(
                    title: Text('Silent'),
                    value: TimerSound.silent,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            SwitchListTile(
              title: const Text('Haptic feedback'),
              subtitle: const Text('Vibrate when the timer reaches zero.'),
              value: _timerHaptic,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) async {
                setState(() => _timerHaptic = v);
                await AppPreferences.setTimerHaptic(v);
              },
            ),
            SwitchListTile(
              title: const Text('Keep screen awake'),
              subtitle: const Text('Prevent the screen from sleeping during a workout.'),
              value: _timerKeepAwake,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) async {
                setState(() => _timerKeepAwake = v);
                await AppPreferences.setTimerKeepAwake(v);
              },
            ),
          ],
          const SizedBox(height: 32),

          // ── Backup ────────────────────────────────────────────────────────
          SwitchListTile(
            title: const Text('Enable Backups'),
            value: _backupEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: _isBusy
                ? null
                : (v) async {
                    setState(() => _backupEnabled = v);
                    await AppPreferences.setBackupEnabled(v);
                    // Cancel auto-backup when backups are fully disabled
                    if (!v && _autoBackupEnabled) {
                      await BackupScheduler.cancel();
                    }
                  },
          ),
          if (_backupEnabled) ...[
            const SizedBox(height: 4),
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
                  child: const Text('Export Folder'),
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
            const SizedBox(height: 4),
            SwitchListTile(
              title: const Text('Automatic Backups'),
              subtitle: const Text('Run a backup daily at the scheduled time.'),
              value: _autoBackupEnabled,
              contentPadding: EdgeInsets.zero,
              onChanged: _isBusy
                  ? null
                  : (v) async {
                      setState(() => _autoBackupEnabled = v);
                      await AppPreferences.setAutoBackupEnabled(v);
                      if (v) {
                        await BackupScheduler.schedule(_backupHour, _backupMinute);
                      } else {
                        await BackupScheduler.cancel();
                      }
                    },
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Backup time: ${_backupHour.toString().padLeft(2, '0')}:${_backupMinute.toString().padLeft(2, '0')}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: _isBusy
                      ? null
                      : () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay(
                                hour: _backupHour, minute: _backupMinute),
                          );
                          if (picked == null || !mounted) return;
                          setState(() {
                            _backupHour = picked.hour;
                            _backupMinute = picked.minute;
                          });
                          await AppPreferences.setBackupHour(picked.hour);
                          await AppPreferences.setBackupMinute(picked.minute);
                          if (_autoBackupEnabled) {
                            await BackupScheduler.schedule(picked.hour, picked.minute);
                          }
                        },
                  child: const Text('Change time'),
                ),
              ],
            ),
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
        ],
      ),
    );
  }
}
