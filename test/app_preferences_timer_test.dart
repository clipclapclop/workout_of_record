import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_of_record/app_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  test('get-ready chimes are opt-in and persist when enabled', () async {
    expect(AppPreferences.getTimerGetReadyChimes(), isFalse);

    await AppPreferences.setTimerGetReadyChimes(true);

    expect(AppPreferences.getTimerGetReadyChimes(), isTrue);
  });
}
