import 'dart:io' show exit;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../app_preferences.dart';
import '../../services/backup_service.dart';
import '../../services/saf_service.dart';
import '../../widgets/unsaved_changes_dialog.dart';

class BackupSettingsScreen extends StatefulWidget {
  const BackupSettingsScreen({super.key});

  @override
  State<BackupSettingsScreen> createState() => _BackupSettingsScreenState();
}

class _BackupSettingsScreenState extends State<BackupSettingsScreen> {
  bool _backupEnabled = false;
  bool _autoBackupEnabled = false;
  String? _backupDirPath;
  DateTime? _lastBackupTimestamp;
  bool _isBusy = false;
  String? _lastBackupError;
  bool _folderStale = false;

  late bool _initBackupEnabled;
  late bool _initAutoBackupEnabled;
  String? _initBackupDirPath;

  bool get _hasUnsavedChanges =>
      _backupEnabled != _initBackupEnabled ||
      _autoBackupEnabled != _initAutoBackupEnabled ||
      _backupDirPath != _initBackupDirPath;

  @override
  void initState() {
    super.initState();
    _backupEnabled = AppPreferences.getBackupEnabled();
    _autoBackupEnabled = AppPreferences.getAutoBackupEnabled();
    _backupDirPath = AppPreferences.getBackupDirectoryPath();
    _lastBackupTimestamp = AppPreferences.getLastBackupTimestamp();
    _lastBackupError = AppPreferences.getLastBackupError();

    _initBackupEnabled = _backupEnabled;
    _initAutoBackupEnabled = _autoBackupEnabled;
    _initBackupDirPath = _backupDirPath;

    _validateFolder();
  }

  Future<void> _validateFolder() async {
    final dir = _backupDirPath;
    if (dir == null || !_backupEnabled) return;
    final ok = await SafService.checkFolder(dir);
    if (!ok && mounted) setState(() => _folderStale = true);
  }

  Future<bool> _save() async {
    if (_backupEnabled && _backupDirPath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choose a backup folder before enabling backups.'),
          ),
        );
      }
      return false;
    }

    await AppPreferences.setBackupEnabled(_backupEnabled);
    if (_backupDirPath != null) {
      await AppPreferences.setBackupDirectoryPath(_backupDirPath!);
    }
    await AppPreferences.setAutoBackupEnabled(
      _backupEnabled && _autoBackupEnabled,
    );

    _autoBackupEnabled = _backupEnabled && _autoBackupEnabled;
    _initBackupEnabled = _backupEnabled;
    _initAutoBackupEnabled = _autoBackupEnabled;
    _initBackupDirPath = _backupDirPath;
    return true;
  }

  Future<void> _pickBackupLocation() async {
    final uri = await SafService.pickFolder();
    if (uri == null) return;
    await AppPreferences.setBackupDirectoryPath(uri);
    await AppPreferences.setLastBackupError(null);
    if (mounted) {
      setState(() {
        _backupDirPath = uri;
        _folderStale = false;
        _lastBackupError = null;
      });
    }
  }

  Future<void> _backupNow() async {
    setState(() => _isBusy = true);
    try {
      await BackupService.backup(_backupDirPath!);
      await AppPreferences.setLastBackupError(null);
      final ts = AppPreferences.getLastBackupTimestamp();
      if (mounted) {
        setState(() {
          _lastBackupTimestamp = ts;
          _lastBackupError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup complete.')),
        );
      }
    } catch (e) {
      await AppPreferences.setLastBackupError(e.toString());
      if (mounted) {
        setState(() => _lastBackupError = e.toString());
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
    final result = await showUnsavedChangesDialog(context);
    if (result == UnsavedChangesAction.save) {
      return _save();
    }
    return result == UnsavedChangesAction.discard;
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
                final saved = await _save();
                if (saved && context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_folderStale)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(Icons.warning_amber_rounded,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(
                      'Backup folder is no longer accessible',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    subtitle: Text(
                      'Please choose a new folder.',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    trailing: TextButton(
                      onPressed: _pickBackupLocation,
                      child: const Text('Choose'),
                    ),
                  ),
                ),
              ),
            if (_lastBackupError != null && !_folderStale)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(Icons.error_outline,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(
                      'Last backup failed',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                    subtitle: Text(
                      _lastBackupError!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            Card.outlined(
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable Backups'),
                    value: _backupEnabled,
                    onChanged: _isBusy
                        ? null
                        : (v) => setState(() {
                            _backupEnabled = v;
                            if (!v) _autoBackupEnabled = false;
                          }),
                  ),
                  if (_backupEnabled && _backupDirPath == null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Choose a folder before saving backup settings.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
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
                      title: const Text('Backup on workout finish'),
                      subtitle: const Text(
                          'Run a backup automatically each time you finish a workout.'),
                      value: _autoBackupEnabled,
                      onChanged: (_isBusy || _backupDirPath == null)
                          ? null
                          : (v) => setState(() => _autoBackupEnabled = v),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
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
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card.outlined(
              child: ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Restore from Backup'),
                subtitle: const Text(
                  'Select an existing backup ZIP. Enabling backups is not required.',
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: !_isBusy,
                onTap: _isBusy ? null : _restoreFromBackup,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
