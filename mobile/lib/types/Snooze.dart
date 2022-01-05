import 'package:buzzine/types/RingingAlarmEntity.dart';

class Snooze {
  String id;
  int length;
  DateTime startDate;
  DateTime invocationDate;
  RingingAlarmEntity ringingAlarmInstance;

  Snooze(
      {required this.id,
      required this.length,
      required this.startDate,
      required this.invocationDate,
      required this.ringingAlarmInstance});
}
