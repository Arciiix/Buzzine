import 'package:flutter/material.dart';

String addZero(num value) {
  return value.toString().padLeft(2, '0');
}

String secondsTommss(num? seconds) {
  if (seconds == null) return "";
  Duration tempDuration = Duration(milliseconds: (seconds * 1000).floor());
  return addZero(tempDuration.inMinutes) +
      ":" +
      addZero(tempDuration.inSeconds.remainder(60));
}

String secondsToHHmm(num? seconds) {
  if (seconds == null) return "";
  Duration tempDuration = Duration(milliseconds: (seconds * 1000).floor());
  return addZero(tempDuration.inHours) +
      ":" +
      addZero(tempDuration.inMinutes.remainder(60));
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
  } else {
    output += "0m ";
  }

  return output;
}

String dateToDateString(DateTime date) {
  date = date.toLocal();
  return "${addZero(date.day)}.${addZero(date.month)}.${date.year}";
}

String dateToDateTimeString(DateTime date) {
  date = date.toLocal();
  return "${addZero(date.hour)}:${addZero(date.minute)} ${addZero(date.day)}.${addZero(date.month)}.${date.year}";
}

String dateToTimeString(DateTime date, {bool? excludeSeconds}) {
  date = date.toLocal();
  return "${addZero(date.hour)}:${addZero(date.minute)}${excludeSeconds == true ? "" : ":" + addZero(date.second)}";
}

String durationToHHmm(Duration duration) {
  return "${addZero(duration.inHours)}:${addZero(duration.inMinutes.remainder(60))}";
}

int getFirstDecimalPlaceOfNumber(double value) {
  return ((double.parse(value.toStringAsFixed(1)) -
              double.parse(value.toStringAsFixed(1)).floor()) *
          10)
      .floor();
}
