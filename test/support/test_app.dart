import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_of_record/app_preferences.dart';
import 'package:workout_of_record/theme.dart';

Future<void> initializeTestPreferences([
  Map<String, Object> values = const {},
]) async {
  SharedPreferences.setMockInitialValues(values);
  FlutterSecureStorage.setMockInitialValues({});
  await AppPreferences.init();
}

Widget buildTestApp({required Widget home, double textScale = 1}) {
  return MaterialApp(
    theme: AppTheme.dark(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}
