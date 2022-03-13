import 'dart:math';

import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/SleepCalculations.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/get_icon_by_offset.dart';
import 'package:flutter/material.dart';

class SleepCalculationsScreen extends StatefulWidget {
  final Function? onRefresh;
  final SleepCalculations initCalculations;

  const SleepCalculationsScreen(
      {Key? key, required this.initCalculations, this.onRefresh})
      : super(key: key);

  @override
  State<SleepCalculationsScreen> createState() =>
      _SleepCalculationsScreenState();
}

class _SleepCalculationsScreenState extends State<SleepCalculationsScreen> {
  late SleepCalculations _calculations;
  late TrackingStats _trackingStats;
  late List<SleepCalculationsComparison> _sleepComparison;

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
        hour: _calculations.goingToSleep.toLocal().hour,
        minute: _calculations.goingToSleep.toLocal().minute));

    if (selectedTime != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień długość snu", "Zmień godzinę budzenia"]);

      if (userChoice == null) return;

      _calculations.changeGoingToSleep(selectedTime, userChoice == 0);
      refreshComparison();

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
      refreshComparison();

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
      refreshComparison();

      //Re-render
      setState(() {});
    }
  }

  Future<void> handleAlarmTimeSelect() async {
    DateTime? selectedTime = await getTime(TimeOfDay(
        hour: _calculations.alarmTime.toLocal().hour,
        minute: _calculations.alarmTime.toLocal().minute));

    if (selectedTime != null) {
      int? userChoice = await displayChoiceDialog(
          ["Zmień długość snu", "Zmień godzinę pójścia spać"]);

      if (userChoice == null) return;

      _calculations.changeAlarmTime(selectedTime, userChoice == 0);
      refreshComparison();

      //Re-render
      setState(() {});
    }
  }

  Future<void> askToRecalculateDurationOnComparison() async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Resetuj długości snu"),
          content: Text(
              'Czy na pewno chcesz przywrócić długość snu w tabeli do domyślnych wartości?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Przywróć")),
          ],
        );
      },
    );

    if (confirmed == true) {
      refreshComparison();
      calculateDurationsToComparison();
    }
  }

  Future<void> changeSleepComparisonEntry(
      SleepCalculationsComparison comparison) async {
    int? userChoice =
        await displayChoiceDialog(["Zmień długość", "Zmień godzinę budzenia"]);

    if (userChoice == null) return;

    if (userChoice == 0) {
      Duration? selectedDuration =
          await selectDurationFromPicker(comparison.duration.inSeconds);

      if (selectedDuration != null) {
        setState(() {
          comparison.changeDuration(selectedDuration, _calculations);
        });
      }
    } else {
      DateTime? selectedTime = await getTime(TimeOfDay(
          hour: _calculations.alarmTime.toLocal().hour,
          minute: _calculations.alarmTime.toLocal().minute));

      if (selectedTime != null) {
        setState(() {
          comparison.changeAlarmTime(selectedTime, _calculations);
        });
      }
    }
  }

  Future<void> addAlarm() async {
    await _calculations.addAlarm(context);

    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  void refreshComparison() {
    _sleepComparison.forEach((e) => e.update(_calculations));
    //Re-render
    setState(() {});
  }

  void calculateDurationsToComparison() {
    //This amount of minutes will be added to the base duration
    List<int> durationDifferencesMinutes = [
      -180,
      -120,
      -90,
      -60,
      0,
      30,
      60,
      90,
      120,
      180
    ];

    setState(() {
      _sleepComparison = durationDifferencesMinutes
          .map((e) => SleepCalculationsComparison(
              initDuration:
                  Duration(minutes: _calculations.sleepDuration.inMinutes + e),
              calculations: _calculations))
          .toList();

      //Delete entries with negative duration
      _sleepComparison = _sleepComparison
          .where((SleepCalculationsComparison e) => e.duration.inSeconds > 0)
          .toList();
    });
  }

  @override
  void initState() {
    _calculations = widget.initCalculations;
    _trackingStats = GlobalData.trackingStats;

    calculateDurationsToComparison();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Obliczenia snu")),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.alarm_add),
          onPressed: addAlarm,
        ),
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
            SizedBox(height: 20),
            InkWell(
              onTap: askToRecalculateDurationOnComparison,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Długość snu",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text("Godzina obudzenia się",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 72),
                itemCount: _sleepComparison.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () =>
                        changeSleepComparisonEntry(_sleepComparison[index]),
                    title: Text(
                        durationToHHmm(_sleepComparison[index].duration)
                            .toString(),
                        style: TextStyle(
                          fontSize: 14,
                        )),
                    trailing: Text(
                        dateToTimeString(_sleepComparison[index].alarmTime,
                            excludeSeconds: true),
                        style: TextStyle(
                          fontSize: 14,
                        )),
                  );
                },
              ),
            ),
          ],
        ));
  }
}
