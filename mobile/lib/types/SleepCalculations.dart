import 'package:flutter/material.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_form.dart';
import 'package:buzzine/types/Alarm.dart';

class SleepCalculations {
  late DateTime _goingToSleep;
  late Duration _timeToFallAsleep;
  late Duration _sleepDuration;
  late DateTime _alarmTime;

  //Outside the class, the only thing allowed is to read the variables
  DateTime get goingToSleep => _goingToSleep;
  Duration get timeToFallAsleep => _timeToFallAsleep;
  Duration get sleepDuration => _sleepDuration;
  DateTime get alarmTime => _alarmTime;

  void changeGoingToSleep(DateTime newValue, bool changeSleepDuration) {
    _goingToSleep = newValue;

    if (_goingToSleep.isAfter(_alarmTime)) {
      //If, for some reason, the time is after the alarm time, make it one day earlier
      _goingToSleep = _goingToSleep.subtract(const Duration(days: 1));
    }

    //To change the going to sleep time, sleep duration or alarm time must be changed
    if (changeSleepDuration) {
      _sleepDuration =
          _goingToSleep.add(_timeToFallAsleep).difference(_alarmTime).abs();
    } else {
      _alarmTime = _goingToSleep.add(_timeToFallAsleep).add(_sleepDuration);
    }
  }

  void changeTimeToFallAsleep(Duration newValue, bool changeGoingToSleep) {
    _timeToFallAsleep = newValue;

    //To change time to fall asleep, going to sleep hour or alarm time (or the duration, but assume user wants it to be the same) must be changed
    if (changeGoingToSleep) {
      _goingToSleep =
          _alarmTime.subtract(_sleepDuration).subtract(_timeToFallAsleep);
    } else {
      _alarmTime = _goingToSleep.add(_timeToFallAsleep).add(_sleepDuration);
    }
  }

  void changeSleepDuration(Duration newValue, bool changeGoingToSleep) {
    _sleepDuration = newValue;

    //To change the sleep duration, alarm time or going to sleep time must be changed
    if (changeGoingToSleep) {
      _goingToSleep =
          _alarmTime.subtract(_sleepDuration).subtract(_timeToFallAsleep);
    } else {
      _alarmTime = _goingToSleep.add(_timeToFallAsleep).add(_sleepDuration);
    }
  }

  void changeAlarmTime(DateTime newValue, bool changeDuration) {
    _alarmTime = newValue;

    if (_alarmTime.isBefore(_goingToSleep)) {
      //If, for some reason, the time is before the going to sleep time, make it one day later
      _alarmTime = _alarmTime.add(const Duration(days: 1));
    }

    //To change the alarm time, the going to sleep time or the sleep duration must be changed
    if (changeDuration) {
      _sleepDuration =
          _goingToSleep.add(_timeToFallAsleep).difference(_alarmTime).abs();
    } else {
      _goingToSleep =
          _alarmTime.subtract(_sleepDuration).subtract(_timeToFallAsleep);
    }
  }

  Future<void> addAlarm(context) async {
    Alarm? alarm = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AlarmForm(
        overrideTime: TimeOfDay(hour: alarmTime.hour, minute: alarmTime.minute),
      ),
    ));

    if (alarm != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa tworzenie alarmu...");
        },
      );
      await GlobalData.addAlarm(alarm.toMap(), false);
      Navigator.of(context).pop();
    }
  }

  SleepCalculations(
      {required Duration targetDuration,
      required Duration targetTimeToFallAsleep}) {
    _sleepDuration = targetDuration;
    _timeToFallAsleep = targetTimeToFallAsleep;
    _goingToSleep = DateTime.now();
    _alarmTime = DateTime.now().add(_timeToFallAsleep).add(_sleepDuration);
  }
}
