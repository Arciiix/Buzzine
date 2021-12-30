import 'package:buzzine/types/Audio.dart';

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
      this.notes});
}
