class TrackingStats {
  DateTime timestamp;
  TrackingStatsDetails lifetime;
  TrackingStatsDetails monthly;

  TrackingStats(
      {required this.timestamp, required this.lifetime, required this.monthly});
}

class TrackingStatsDetails {
  TrackingStatsObject alarm;
  TrackingStatsObject nap;

  TrackingStatsDetails({required this.alarm, required this.nap});
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
