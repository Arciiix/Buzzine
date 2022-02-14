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
