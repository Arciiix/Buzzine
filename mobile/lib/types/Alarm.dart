class Alarm {
  final String? name;
  final int hour;
  final int minute;
  final DateTime? nextInvocation;
  final bool isActive;

  final bool? isSnoozeEnabled;
  final int? snoozeLength;
  final int? maxTotalSnoozeLength;

  final String? soundName;

  final bool isGuardEnabled;

  final String? notes;

  Alarm(
      {this.name,
      required this.hour,
      required this.minute,
      this.nextInvocation,
      required this.isActive,
      this.isSnoozeEnabled,
      this.snoozeLength,
      this.maxTotalSnoozeLength,
      this.soundName,
      required this.isGuardEnabled,
      this.notes});
}
