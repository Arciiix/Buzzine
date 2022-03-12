import 'dart:math';

import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/SleepCalculations.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/get_icon_by_offset.dart';
import 'package:flutter/material.dart';

class SleepCalculationsScreen extends StatefulWidget {
  final SleepCalculations initCalculations;

  const SleepCalculationsScreen({Key? key, required this.initCalculations})
      : super(key: key);

  @override
  State<SleepCalculationsScreen> createState() =>
      _SleepCalculationsScreenState();
}

class _SleepCalculationsScreenState extends State<SleepCalculationsScreen> {
  late SleepCalculations _calculations;
  late TrackingStats _trackingStats;

  Future<int?> displayChoiceDialog(List<String> choices) async {
    int? selectedOptionIndex = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wybierz opcję"),
          content: Container(
            height: 100,
            width: 100,
            child: Center(
                child: ListView.builder(
                    itemCount: choices.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ListTile(
                        title: Text(choices[index]),
                        onTap: () => Navigator.of(context).pop(index),
                      );
                    })),
          ),
        );
      },
    );

    return selectedOptionIndex;
  }

  Future<DateTime?> getTime(TimeOfDay initialTime) async {
    final TimeOfDay? timePickerResponse = await showTimePicker(
        context: context,
        initialTime: initialTime,
        cancelText: "Anuluj",
        confirmText: "Zatwierdź",
        helpText: "Wybierz czas",
        errorInvalidText: "Zły czas",
        hourLabelText: "Godzina",
        minuteLabelText: "Minuta");

    if (timePickerResponse != null) {
      DateTime now = DateTime.now();
      DateTime response = DateTime(now.year, now.month, now.day,
          timePickerResponse.hour, timePickerResponse.minute);

      if (now.isAfter(response)) {
        //If the time is before now, add a whole day (so it'll be tomorrow)
        response = response.add(const Duration(days: 1));
      }

      return response;
    }
  }

  Future<Duration?> selectDurationFromPicker(int initialTime) async {
    Duration? userSelection =
        await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TimeNumberPicker(
        maxDuration: 9999999, //TODO: Don't do 9999999
        minDuration: 0,
        initialTime: initialTime,
      ),
    ));
    return userSelection;
  }

  Future<void> handleSleepTimeSelect() async {
    DateTime? selectedTime = await getTime(TimeOfDay(
        hour: _calculations.goingToSleep.hour,
        minute: _calculations.goingToSleep.minute));

    if (selectedTime != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień długość snu", "Zmień godzinę budzenia"]);

      if (userChoice == null) return;

      _calculations.changeGoingToSleep(selectedTime, userChoice == 0);

      //Re-render
      setState(() {});
    }
  }

  Future<void> handleFallingAsleepTimeSelect() async {
    Duration? selectedDuration = await selectDurationFromPicker(
        _calculations.timeToFallAsleep.inSeconds);

    if (selectedDuration != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień godzinę pójścia spać", "Zmień godzinę budzenia"]);

      if (userChoice == null) return;

      _calculations.changeTimeToFallAsleep(selectedDuration, userChoice == 0);

      //Re-render
      setState(() {});
    }
  }

  Future<void> handleSleepDurationSelect() async {
    Duration? selectedDuration =
        await selectDurationFromPicker(_calculations.sleepDuration.inSeconds);

    if (selectedDuration != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień godzinę pójścia spać", "Zmień godzinę budzenia"]);

      if (userChoice == null) return;

      _calculations.changeSleepDuration(selectedDuration, userChoice == 0);

      //Re-render
      setState(() {});
    }
  }

  Future<void> handleAlarmTimeSelect() async {
    DateTime? selectedTime = await getTime(TimeOfDay(
        hour: _calculations.alarmTime.hour,
        minute: _calculations.alarmTime.minute));

    if (selectedTime != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień długość snu", "Zmień godzinę pójścia spać"]);

      if (userChoice == null) return;

      _calculations.changeAlarmTime(selectedTime, userChoice == 0);

      //Re-render
      setState(() {});
    }
  }

  @override
  void initState() {
    _calculations = widget.initCalculations;
    _trackingStats = GlobalData.trackingStats;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Obliczenia snu")),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ListTile(
              onTap: handleSleepTimeSelect,
              title: const Text(
                "Godzina pójścia spać",
              ),
              subtitle: Text(dateToTimeString(_calculations.goingToSleep,
                  excludeSeconds: true)),
            ),
            ListTile(
              onTap: handleFallingAsleepTimeSelect,
              title: const Text("Czas na zasnięcie"),
              subtitle: Text(
                  _calculations.timeToFallAsleep.inMinutes.toString() +
                      " m " +
                      _calculations.timeToFallAsleep.inSeconds
                          .remainder(60)
                          .toString() +
                      " s"),
            ),
            ListTile(
              onTap: handleSleepDurationSelect,
              title: const Text("Długość snu"),
              subtitle: Row(
                children: [
                  Text(durationToHHmm(_calculations.sleepDuration)),
                  Icon(
                      getIconByOffset(
                        (_calculations.sleepDuration.inSeconds -
                                _trackingStats
                                    .monthly.alarm.averageSleepDuration) /
                            max(
                                _trackingStats
                                    .monthly.alarm.averageSleepDuration,
                                1),
                      ),
                      size: 14),
                  Text(
                      (((_calculations.sleepDuration.inSeconds -
                                          _trackingStats.monthly.alarm
                                              .averageSleepDuration) /
                                      max(
                                          _trackingStats.monthly.alarm
                                              .averageSleepDuration,
                                          1)) *
                                  100)
                              .toStringAsFixed(0) +
                          "%",
                      style: const TextStyle(fontSize: 14))
                ],
              ),
            ),
            ListTile(
              onTap: handleAlarmTimeSelect,
              title: const Text("Godzina obudzenia się"),
              subtitle: Text(dateToTimeString(_calculations.alarmTime,
                  excludeSeconds: true)),
            ),
          ],
        ));
  }
}
