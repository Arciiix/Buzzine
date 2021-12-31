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
  final int? maxTotalSnoozeLength;

  final Audio? sound;

  final bool isGuardEnabled;

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
      this.maxTotalSnoozeLength,
      this.sound,
      required this.isGuardEnabled,
      this.notes,
      this.isRepeating,
      this.repeat});
}