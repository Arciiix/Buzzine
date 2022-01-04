import 'package:buzzine/types/Alarm.dart';

class RingingAlarmEntity {
  final DateTime? maxDate;
  final Alarm alarm;

  RingingAlarmEntity({this.maxDate, required this.alarm});
}
