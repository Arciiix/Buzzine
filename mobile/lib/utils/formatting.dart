String addZero(num value) {
  return value.toString().padLeft(2, '0');
}

String secondsToHHmm(num? seconds) {
  if (seconds == null) return "";
  Duration tempDuration = Duration(milliseconds: (seconds * 1000).floor());
  return addZero(tempDuration.inMinutes) +
      ":" +
      addZero(tempDuration.inSeconds.remainder(60));
}

String secondsToNamedString(num? seconds) {
  if (seconds == null) return "";

  Duration tempDuration = Duration(milliseconds: (seconds * 1000).floor());

  int days = tempDuration.inDays;
  int hours = tempDuration.inHours.remainder(24);
  int minutes = tempDuration.inMinutes.remainder(60);

  String output = "";
  if (days > 0) {
    output += days.toString() + "d ";
  }
  if (hours > 0) {
    output += hours.toString() + "h ";
  }
  if (minutes > 0) {
    output += minutes.toString() + "m ";
  }

  return output;
}
