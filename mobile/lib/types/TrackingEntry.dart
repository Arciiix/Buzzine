class TrackingEntry {
  DateTime? date;
  DateTime? bedTime;
  DateTime? sleepTime;
  DateTime? firstAlarmTime;
  DateTime? wakeUpTime;
  DateTime? getUpTime;
  DateTime? alarmTimeFrom;
  DateTime? alarmTimeTo;
  int? rate;
  int? timeTakenToTurnOffTheAlarm;
  String? notes;
  bool? isNap;

  List<TrackingVersionHistory>? versionHistory;

  Map toMapWithoutDate() {
    return {
      'bedTime': bedTime?.toIso8601String(),
      'sleepTime': sleepTime?.toIso8601String(),
      'firstAlarmTime': firstAlarmTime?.toIso8601String(),
      'wakeUpTime': wakeUpTime?.toIso8601String(),
      'getUpTime': getUpTime?.toIso8601String(),
      'alarmTimeFrom': alarmTimeFrom?.toIso8601String(),
      'alarmTimeTo': alarmTimeTo?.toIso8601String(),
      'rate': rate,
      'timeTakenToTurnOffTheAlarm': timeTakenToTurnOffTheAlarm,
      'notes': notes
    };
  }

  TrackingEntry(
      {this.date,
      this.bedTime,
      this.sleepTime,
      this.firstAlarmTime,
      this.wakeUpTime,
      this.getUpTime,
      this.alarmTimeFrom,
      this.alarmTimeTo,
      this.rate,
      this.timeTakenToTurnOffTheAlarm,
      this.notes,
      this.versionHistory,
      this.isNap});
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
  alarmTimeFrom,
  alarmTimeTo,
  rate,
  timeTakenToTurnOffTheAlarm,
  notes
}
enum TrackingDataType { timestamp, number, duration, text }
