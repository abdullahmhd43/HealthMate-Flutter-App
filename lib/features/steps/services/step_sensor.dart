import 'dart:io' show Platform;

import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

/// Where step counts come from. An interface so tests can use a fake sensor.
abstract class StepSensor {
  /// Asks for the Android "Physical activity" permission. True if granted.
  Future<bool> requestPermission();

  /// Total steps since the phone last booted (the Android hardware counter).
  Stream<int> get stepStream;
}

/// The real phone step counter (`pedometer` package).
class PedometerSensor implements StepSensor {
  @override
  Future<bool> requestPermission() async {
    // iOS asks for "Motion & Fitness" (sensors); Android for "Physical activity".
    final permission =
        Platform.isIOS ? Permission.sensors : Permission.activityRecognition;
    final status = await permission.request();
    return status.isGranted;
  }

  @override
  Stream<int> get stepStream =>
      Pedometer.stepCountStream.map((event) => event.steps);
}
