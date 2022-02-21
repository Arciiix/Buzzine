import 'package:buzzine/types/Audio.dart';

class SleepAsAndroidIntegrationStatus {
  final bool isActive;
  final int emergencyAlarmTimeoutSeconds;
  final int delay;
  final Audio audio;

  SleepAsAndroidIntegrationStatus(
      {required this.isActive,
      required this.emergencyAlarmTimeoutSeconds,
      required this.delay,
      required this.audio});
}
