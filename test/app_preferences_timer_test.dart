import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_of_record/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  test('preserves the owner-confirmed imperial legacy value', () async {
    SharedPreferences.setMockInitialValues({
      'profile_weight_kg': 187.5,
      'settings_units_metric': true,
    });

    await AppPreferences.init();

    final preferences = await SharedPreferences.getInstance();
    expect(AppPreferences.getWeight(), 187.5);
    expect(preferences.getDouble('profile_weight_lbs'), 187.5);
    expect(preferences.containsKey('profile_weight_kg'), isFalse);
    expect(preferences.containsKey('settings_units_metric'), isFalse);
  });

  test('an existing pounds value wins over the legacy weight key', () async {
    SharedPreferences.setMockInitialValues({
      'profile_weight_kg': 187.5,
      'profile_weight_lbs': 190.0,
    });

    await AppPreferences.init();

    final preferences = await SharedPreferences.getInstance();
    expect(AppPreferences.getWeight(), 190.0);
    expect(preferences.containsKey('profile_weight_kg'), isFalse);
  });

  test('get-ready chimes are opt-in and persist when enabled', () async {
    expect(AppPreferences.getTimerGetReadyChimes(), isFalse);

    await AppPreferences.setTimerGetReadyChimes(true);

    expect(AppPreferences.getTimerGetReadyChimes(), isTrue);
  });

  test('active rest timer state can be restored and cleared', () async {
    final endsAt = DateTime.fromMillisecondsSinceEpoch(2000000000000);

    await AppPreferences.setActiveRestTimer(
      workoutId: 42,
      durationSeconds: 90,
      endsAt: endsAt,
    );

    final restored = AppPreferences.getActiveRestTimer();
    expect(restored?.workoutId, 42);
    expect(restored?.durationSeconds, 90);
    expect(restored?.endsAt, endsAt);

    await AppPreferences.clearActiveRestTimer();
    expect(AppPreferences.getActiveRestTimer(), isNull);
  });
}
