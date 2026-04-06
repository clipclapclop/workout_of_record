import 'dart:io' show exit;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app_preferences.dart';
import '../../services/backup_scheduler.dart';
import '../../services/backup_service.dart';
import '../../services/saf_service.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _backupEnabled = false;
  bool _autoBackupEnabled = false;
  int _backupHour = 2;
  int _backupMinute = 0;
  String? _backupDirPath;
  DateTime? _lastBackupTimestamp;
  bool _isBusy = false;

  late bool _initBackupEnabled;
  late bool _initAutoBackupEnabled;
  late int _initBackupHour;
  late int _initBackupMinute;
  String? _initBackupDirPath;

  bool get _hasUnsavedChanges =>
      _backupEnabled != _initBackupEnabled ||
      _autoBackupEnabled != _initAutoBackupEnabled ||
      _backupHour != _initBackupHour ||
      _backupMinute != _initBackupMinute ||
      _backupDirPath != _initBackupDirPath;

  @override
  void initState() {
    super.initState();
    _backupEnabled = AppPreferences.getBackupEnabled();
    _autoBackupEnabled = AppPreferences.getAutoBackupEnabled();
    _backupHour = AppPreferences.getBackupHour();
    _backupMinute = AppPreferences.getBackupMinute();
    _backupDirPath = AppPreferences.getBackupDirectoryPath();
    _lastBackupTimestamp = AppPreferences.getLastBackupTimestamp();

    _initBackupEnabled = _backupEnabled;
    _initAutoBackupEnabled = _autoBackupEnabled;
    _initBackupHour = _backupHour;
    _initBackupMinute = _backupMinute;
    _initBackupDirPath = _backupDirPath;
  }

  Future<void> _save() async {
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

    _initBackupEnabled = _backupEnabled;
    _initAutoBackupEnabled = _autoBackupEnabled;
    _initBackupHour = _backupHour;
    _initBackupMinute = _backupMinute;
    _initBackupDirPath = _backupDirPath;
  }

  Future<void> _pickBackupLocation() async {
    final uri = await SafService.pickFolder();
    if (uri == null) return;
    await AppPreferences.setBackupDirectoryPath(uri);
    if (mounted) setState(() => _backupDirPath = uri);
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
                onPressed: () => exit(0),
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
        appBar: AppBar(title: const Text('Backup & Restore')),
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
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Backups'),
                    value: _backupEnabled,
                    onChanged: _isBusy
                        ? null
                        : (v) => setState(() => _backupEnabled = v),
                  ),
                  if (_backupEnabled) ...[
                    const Divider(height: 1),
                    ListTile(
                      title: Text(
                        _backupDirPath ?? 'No backup location set',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: _lastBackupTimestamp != null
                          ? Text(
                              'Last backup: ${_formatTimestamp(_lastBackupTimestamp!)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                      trailing: TextButton(
                        onPressed: _isBusy ? null : _pickBackupLocation,
                        child: const Text('Choose folder'),
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Automatic Backups'),
                      subtitle: const Text(
                          'Run a backup daily at the scheduled time.'),
                      value: _autoBackupEnabled,
                      onChanged: _isBusy
                          ? null
                          : (v) => setState(() => _autoBackupEnabled = v),
                    ),
                    ListTile(
                      title: Text(
                        'Backup time: ${TimeOfDay(hour: _backupHour, minute: _backupMinute).format(context)}',
                      ),
                      trailing: TextButton(
                        onPressed: _isBusy
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay(
                                      hour: _backupHour,
                                      minute: _backupMinute),
                                );
                                if (picked == null || !mounted) return;
                                setState(() {
                                  _backupHour = picked.hour;
                                  _backupMinute = picked.minute;
                                });
                              },
                        child: const Text('Change'),
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (_isBusy || _backupDirPath == null)
                                  ? null
                                  : _backupNow,
                              child: _isBusy
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Text('Back Up Now'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  _isBusy ? null : _restoreFromBackup,
                              child: const Text('Restore'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
