class TrackingEntry {
  DateTime? date;
  DateTime? bedTime;
  DateTime? sleepTime;
  DateTime? firstAlarmTime;
  DateTime? wakeUpTime;
  DateTime? getUpTime;
  int? rate;

  List<TrackingVersionHistory>? versionHistory;

  Map toMapWithoutDate() {
    return {
      'bedTime': bedTime?.toIso8601String(),
      'sleepTime': sleepTime?.toIso8601String(),
      'firstAlarmTime': firstAlarmTime?.toIso8601String(),
      'wakeUpTime': wakeUpTime?.toIso8601String(),
      'getUpTime': getUpTime?.toIso8601String(),
      'rate': rate
    };
  }

  TrackingEntry(
      {this.date,
      this.bedTime,
      this.sleepTime,
      this.firstAlarmTime,
      this.wakeUpTime,
      this.getUpTime,
      this.rate,
      this.versionHistory});
}

class TrackingVersionHistory {
  DateTime timestamp;
  TrackingFieldName fieldName;
  dynamic value;

  TrackingVersionHistory(
      {required this.timestamp, required this.fieldName, required this.value});
}

enum TrackingFieldName {
  bedTime,
  sleepTime,
  firstAlarmTime,
  wakeUpTime,
  getUpTime,
  rate
}
