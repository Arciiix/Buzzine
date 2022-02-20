import 'package:buzzine/types/Audio.dart';

class SleepAsAndroidIntegrationStatus {
  final bool isActive;
  final int emergencyAlarmTimeoutSeconds;
  final Audio audio;

  SleepAsAndroidIntegrationStatus(
      {required this.isActive,
      required this.emergencyAlarmTimeoutSeconds,
      required this.audio});
}
