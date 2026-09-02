import 'package:flutter/material.dart';

import '../db/app_database.dart';

/// Mutable UI state for a single completed set row.
/// Owned by WorkoutScreen and passed by reference to SetWidget.
class SetUiState {
  SetUiState({
    required this.isChecked,
    required this.isSkipped,
    String reps = '',
    String weight = '',
    String distance = '',
    String time = '',
  })  : repsCtrl = TextEditingController(text: reps),
        weightCtrl = TextEditingController(text: weight),
        distanceCtrl = TextEditingController(text: distance),
        timeCtrl = TextEditingController(text: time);

  final TextEditingController repsCtrl;
  final TextEditingController weightCtrl;
  final TextEditingController distanceCtrl;
  final TextEditingController timeCtrl;
  bool isChecked;
  bool isSkipped;

  bool canCheck(Movement m) {
    if (m.isRequiredReps) {
      final v = int.tryParse(repsCtrl.text.trim());
      if (v == null || v < 1) return false;
    }
    if (m.isRequiredWeight) {
      final v = double.tryParse(weightCtrl.text.trim());
      if (v == null || !v.isFinite) return false;
    }
    if (m.isRequiredDistance) {
      final v = double.tryParse(distanceCtrl.text.trim());
      if (v == null || !v.isFinite || v <= 0) return false;
    }
    if (m.isRequiredTime) {
      final v = double.tryParse(timeCtrl.text.trim());
      if (v == null || !v.isFinite || v <= 0) return false;
    }
    return true;
  }

  void dispose() {
    repsCtrl.dispose();
    weightCtrl.dispose();
    distanceCtrl.dispose();
    timeCtrl.dispose();
  }
}
