import 'package:flutter/material.dart';

import '../app_preferences.dart';
import '../screens/chat_screen.dart';
import '../screens/history_screen.dart';
import '../screens/home_screen.dart';
import '../screens/meso_template_list_screen.dart';
import '../screens/movements_screen.dart';
import '../screens/notes_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/workout_screen.dart';

enum AppScreen { workout, exercises, mesoTemplates, history, chat, notes, profile, settings }

class AppNavMenu extends StatelessWidget {
  const AppNavMenu({
    super.key,
    required this.current,
    this.activeWorkoutId,
    this.activeWorkoutName,
    this.onNavigateAway,
  });

  final AppScreen current;
  final int? activeWorkoutId;
  final String? activeWorkoutName;
  final Future<bool> Function()? onNavigateAway;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<AppScreen>(
      onSelected: (screen) => _navigate(context, screen),
      itemBuilder: (_) => [
        if (current != AppScreen.workout)
          const PopupMenuItem(
            value: AppScreen.workout,
            child: Text('Workout'),
          ),
        if (current != AppScreen.exercises)
          const PopupMenuItem(
            value: AppScreen.exercises,
            child: Text('Exercises'),
          ),
        if (current != AppScreen.mesoTemplates)
          const PopupMenuItem(
            value: AppScreen.mesoTemplates,
            child: Text('Meso Templates'),
          ),
        if (current != AppScreen.history)
          const PopupMenuItem(
            value: AppScreen.history,
            child: Text('History'),
          ),
        if (current != AppScreen.chat)
          const PopupMenuItem(
            value: AppScreen.chat,
            child: Text('AI Chat'),
          ),
        if (current != AppScreen.notes)
          const PopupMenuItem(
            value: AppScreen.notes,
            child: Text('Notes'),
          ),
        if (current != AppScreen.profile)
          const PopupMenuItem(
            value: AppScreen.profile,
            child: Text('Profile'),
          ),
        if (current != AppScreen.settings)
          const PopupMenuItem(
            value: AppScreen.settings,
            child: Text('Settings'),
          ),
      ],
    );
  }

  void _navigate(BuildContext context, AppScreen screen) async {
    if (onNavigateAway != null) {
      final ok = await onNavigateAway!();
      if (!ok) return;
    }
    if (!context.mounted) return;
    final Widget dest = switch (screen) {
      AppScreen.workout => activeWorkoutId != null
          ? WorkoutScreen(
              completedWorkoutId: activeWorkoutId!,
              workoutName: activeWorkoutName!,
              mesocycleId: AppPreferences.getCurrentMesocycleId()!,
            )
          : const HomeScreen(),
      AppScreen.exercises => MovementsScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.mesoTemplates => MesoTemplateListScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.history => HistoryScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.chat => const ChatScreen(),
      AppScreen.notes => const NotesScreen(),
      AppScreen.profile => const ProfileScreen(),
      AppScreen.settings => const SettingsScreen(),
    };
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => dest),
      (_) => false,
    );
  }
}
