class TrackingStats {
  DateTime timestamp;
  TrackingStatsObject lifetime;
  TrackingStatsObject monthly;

  TrackingStats(
      {required this.timestamp, required this.lifetime, required this.monthly});
}

class TrackingStatsObject {
  int averageSleepDuration;
  int averageTimeAtBed;
  int averageAlarmWakeUpProcrastinationTime;
  int averageTimeBeforeGettingUp;

  TrackingStatsObject(
      {required this.averageSleepDuration,
      required this.averageTimeAtBed,
      required this.averageAlarmWakeUpProcrastinationTime,
      required this.averageTimeBeforeGettingUp});
}
