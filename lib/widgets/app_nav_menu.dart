import 'package:flutter/material.dart';

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

    final navigator = Navigator.of(context);
    if (activeWorkoutId != null && screen == AppScreen.workout) {
      navigator.popUntil(
        (route) =>
            route.settings.name == WorkoutScreen.routeName || route.isFirst,
      );
      return;
    }

    final Widget dest = switch (screen) {
      AppScreen.workout => const HomeScreen(),
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
      AppScreen.chat => ChatScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.notes => NotesScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.profile => ProfileScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
      AppScreen.settings => SettingsScreen(
          activeWorkoutId: activeWorkoutId,
          activeWorkoutName: activeWorkoutName,
        ),
    };
    final route = MaterialPageRoute<void>(builder: (_) => dest);

    if (activeWorkoutId != null) {
      // Keep the live workout route mounted so in-memory session state, notably
      // the rest timer, survives visits to history and other app screens.
      navigator.popUntil(
        (route) =>
            route.settings.name == WorkoutScreen.routeName || route.isFirst,
      );
      navigator.push(route);
      return;
    }

    navigator.pushAndRemoveUntil(route, (_) => false);
  }
}
