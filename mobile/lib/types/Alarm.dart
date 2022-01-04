import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';

class Alarm {
  final String? id;
  final String? name;
  final int hour;
  final int minute;
  final DateTime? nextInvocation;
  final bool isActive;

  final bool? isSnoozeEnabled;
  final int? maxTotalSnoozeDuration;

  final Audio? sound;

  final bool isGuardEnabled;

  final bool? deleteAfterRinging;

  final String? notes;

  final bool? isRepeating;
  final Repeat? repeat;

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
