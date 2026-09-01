import 'package:flutter/material.dart';
import '../widgets/app_nav_menu.dart';
import 'settings/ai_settings_screen.dart';
import 'settings/backup_settings_screen.dart';
import 'settings/timer_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    this.activeWorkoutId,
    this.activeWorkoutName,
  });

  final int? activeWorkoutId;
  final String? activeWorkoutName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
        actions: [
          AppNavMenu(
            current: AppScreen.settings,
            activeWorkoutId: activeWorkoutId,
            activeWorkoutName: activeWorkoutName,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SettingsTile(
            icon: Icons.timer,
            title: 'Rest Timer',
            subtitle: 'Timer, sounds, and haptics',
            onTap: () => _push(context, const TimerSettingsScreen()),
          ),
          _SettingsTile(
            icon: Icons.auto_awesome,
            title: 'AI',
            subtitle: 'Recommendations, chat, and API settings',
            onTap: () => _push(context, const AiSettingsScreen()),
          ),
          _SettingsTile(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Automatic backups and data restore',
            onTap: () => _push(context, const BackupSettingsScreen()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
