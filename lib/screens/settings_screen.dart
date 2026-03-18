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

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
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
  bool _pendingFolderPick = false;

  // Initial values for dirty-checking
  late bool _initAiEnabled;
  late bool _initUnitsMetric;
  late bool _initTimerEnabled;
  late TimerSound _initTimerSound;
  late bool _initTimerHaptic;
  late bool _initTimerKeepAwake;
  late int _initTimerDefaultSeconds;
  late bool _initBackupEnabled;
  late bool _initAutoBackupEnabled;
  late int _initBackupHour;
  late int _initBackupMinute;
  String? _initBackupDirPath;
  String _initApiKey = '';

  bool get _hasUnsavedChanges =>
      _aiEnabled != _initAiEnabled ||
      _unitsMetric != _initUnitsMetric ||
      _timerEnabled != _initTimerEnabled ||
      _timerDefaultSeconds != _initTimerDefaultSeconds ||
      _timerSound != _initTimerSound ||
      _timerHaptic != _initTimerHaptic ||
      _timerKeepAwake != _initTimerKeepAwake ||
      _backupEnabled != _initBackupEnabled ||
      _autoBackupEnabled != _initAutoBackupEnabled ||
      _backupHour != _initBackupHour ||
      _backupMinute != _initBackupMinute ||
      _backupDirPath != _initBackupDirPath ||
      _apiKeyController.text.trim() != _initApiKey;

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

    // Snapshot initial values for dirty-checking
    _initAiEnabled = _aiEnabled;
    _initUnitsMetric = _unitsMetric;
    _initTimerEnabled = _timerEnabled;
    _initTimerSound = _timerSound;
    _initTimerHaptic = _timerHaptic;
    _initTimerKeepAwake = _timerKeepAwake;
    _initTimerDefaultSeconds = _timerDefaultSeconds;
    _initBackupEnabled = _backupEnabled;
    _initAutoBackupEnabled = _autoBackupEnabled;
    _initBackupHour = _backupHour;
    _initBackupMinute = _backupMinute;
    _initBackupDirPath = _backupDirPath;

    WidgetsBinding.instance.addObserver(this);
    _loadApiKey();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _pendingFolderPick) {
      _pendingFolderPick = false;
      _continueFolderPick();
    }
  }

  Future<void> _continueFolderPick() async {
    final status = await Permission.manageExternalStorage.status;
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Storage permission required to set backup location.'),
            action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
          ),
        );
      }
      return;
    }
    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;
    if (mounted) setState(() => _backupDirPath = dirPath);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apiKeyController.dispose();
    _timerSecondsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadApiKey() async {
    final key = await AppPreferences.getApiKey();
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
        _initApiKey = key ?? '';
        _apiKeyLoading = false;
      });
    }
  }

  Future<void> _pickBackupLocation() async {
    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      await _continueFolderPick();
      return;
    }
    // MANAGE_EXTERNAL_STORAGE always redirects to system settings.
    // Set the flag first; didChangeAppLifecycleState resumes the flow when
    // the user returns to the app (whether they granted or denied).
    _pendingFolderPick = true;
    await Permission.manageExternalStorage.request();
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
    await AppPreferences.setAiEnabled(_aiEnabled);
    await AppPreferences.setUnitsMetric(_unitsMetric);
    await AppPreferences.setTimerEnabled(_timerEnabled);
    await AppPreferences.setTimerDefaultSeconds(_timerDefaultSeconds);
    await AppPreferences.setTimerSound(_timerSound);
    await AppPreferences.setTimerHaptic(_timerHaptic);
    await AppPreferences.setTimerKeepAwake(_timerKeepAwake);
    await AppPreferences.setBackupEnabled(_backupEnabled);
    if (_backupDirPath != null) {
      await AppPreferences.setBackupDirectoryPath(_backupDirPath!);
    }
    await AppPreferences.setAutoBackupEnabled(_autoBackupEnabled);
    await AppPreferences.setBackupHour(_backupHour);
    await AppPreferences.setBackupMinute(_backupMinute);
    if (_backupEnabled && _autoBackupEnabled) {
      await BackupScheduler.schedule(_backupHour, _backupMinute);
    } else {
      await BackupScheduler.cancel();
    }
    final apiKey = _apiKeyController.text.trim();
    await AppPreferences.setApiKey(apiKey.isEmpty ? null : apiKey);
  }

  Future<bool> _onNavigateAway() async {
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
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => Navigator.pop(ctx, 'cancel'),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                  onPressed: () => Navigator.pop(ctx, 'dismiss'),
                  child: const Text('Dismiss'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
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
    if (result == 'dismiss') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [AppNavMenu(current: AppScreen.settings, onNavigateAway: _onNavigateAway)],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: FilledButton(
            onPressed: _apiKeyLoading
                ? null
                : () async {
                    await _save();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (_) => false,
                    );
                  },
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
            onChanged: (v) => setState(() => _unitsMetric = v),
          ),
          const SizedBox(height: 8),

          // ── AI Recommendations ────────────────────────────────────────────
          SwitchListTile(
            title: const Text('AI Recommendations'),
            subtitle: const Text(
                'Use AI to pre-fill set targets based on your history and profile.'),
            value: _aiEnabled,
            contentPadding: EdgeInsets.zero,
            onChanged: (v) => setState(() => _aiEnabled = v),
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
            onChanged: (v) => setState(() => _timerEnabled = v),
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
              onChanged: (v) {
                final seconds = int.tryParse(v.trim());
                if (seconds != null && seconds > 0) {
                  setState(() => _timerDefaultSeconds = seconds);
                }
              },
            ),
            const SizedBox(height: 8),
            const Text('Sound'),
            RadioGroup<TimerSound>(
              groupValue: _timerSound,
              onChanged: (v) => setState(() => _timerSound = v!),
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
              onChanged: (v) => setState(() => _timerHaptic = v),
            ),
            SwitchListTile(
              title: const Text('Keep screen awake'),
              subtitle: const Text('Prevent the screen from sleeping during a workout.'),
              value: _timerKeepAwake,
              contentPadding: EdgeInsets.zero,
              onChanged: (v) => setState(() => _timerKeepAwake = v),
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
                : (v) => setState(() => _backupEnabled = v),
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
                  : (v) => setState(() => _autoBackupEnabled = v),
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
