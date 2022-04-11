import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';

class Nap extends Alarm {
  String? id;
  String? name;
  int hour;
  int minute;
  int? second;
  bool isActive;

  bool? isSnoozeEnabled;
  int? maxTotalSnoozeDuration;

  Audio? sound;

  bool isGuardEnabled;

  bool? deleteAfterRinging;

  String? notes;

  int? emergencyAlarmTimeoutSeconds;

  DateTime? invocationDate;

  bool? isFavorite;

  Nap(
      {this.id,
      this.name,
      required this.hour,
      required this.minute,
      required this.second,
      required this.isActive,
      this.isSnoozeEnabled,
      this.maxTotalSnoozeDuration,
      this.sound,
      required this.isGuardEnabled,
      this.deleteAfterRinging,
      this.notes,
      this.emergencyAlarmTimeoutSeconds,
      this.invocationDate,
      this.isFavorite})
      : super(
            id: id,
            name: name,
            hour: hour,
            minute: minute,
            second: second,
            isActive: isActive,
            isSnoozeEnabled: isSnoozeEnabled,
            maxTotalSnoozeDuration: maxTotalSnoozeDuration,
            sound: sound,
            isGuardEnabled: isGuardEnabled,
            deleteAfterRinging: deleteAfterRinging,
            notes: notes,
            emergencyAlarmTimeoutSeconds: emergencyAlarmTimeoutSeconds,
            isRepeating: false,
            isFavorite: isFavorite);

  @override
  Map toMap() {
    return {
      'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'second': second,
      'isActive': isActive,
      'isSnoozeEnabled': isSnoozeEnabled,
      'maxTotalSnoozeDuration': maxTotalSnoozeDuration,
      'sound': sound?.toMap(),
      'isGuardEnabled': isGuardEnabled,
      'deleteAfterRinging': deleteAfterRinging,
      'notes': notes,
      'emergencyAlarmTimeoutSeconds': emergencyAlarmTimeoutSeconds,
      'invocationDate': invocationDate,
      'isFavorite': isFavorite
    };
  }
}
