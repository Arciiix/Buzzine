import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';

class Alarm {
  String? id;
  String? name;
  int hour;
  int minute;
  DateTime? nextInvocation;
  bool isActive;

  bool? isSnoozeEnabled;
  int? maxTotalSnoozeDuration;

  Audio? sound;

  bool isGuardEnabled;

  bool? deleteAfterRinging;

  String? notes;

  bool? isRepeating;
  Repeat? repeat;

  Alarm(
      {this.id,
      this.name,
      required this.hour,
      required this.minute,
      this.nextInvocation,
      required this.isActive,
      this.isSnoozeEnabled,
      this.maxTotalSnoozeDuration,
      this.sound,
      required this.isGuardEnabled,
      this.deleteAfterRinging,
      this.notes,
      this.isRepeating,
      this.repeat});

  Map toMap() {
    return {
      'id': id,
      'name': name,
      'hour': hour,
      'minute': minute,
      'nextInvocation': nextInvocation,
      'isActive': isActive,
      'isSnoozeEnabled': isSnoozeEnabled,
      'maxTotalSnoozeDuration': maxTotalSnoozeDuration,
      'sound': sound?.toMap(),
      'isGuardEnabled': isGuardEnabled,
      'deleteAfterRinging': deleteAfterRinging,
      'notes': notes,
      'isRepeating': isRepeating,
      'repeat': (isRepeating ?? false) ? repeat?.toMap() : null,
    };
  }
}
