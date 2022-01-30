import 'dart:async';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/utils/formatting.dart';
import "package:flutter/material.dart";

class SnoozeAlarm extends StatefulWidget {
  final int leftSnooze;
  final RingingAlarmEntity alarmInstance;

  const SnoozeAlarm(
      {Key? key, required this.leftSnooze, required this.alarmInstance})
      : super(key: key);

  @override
  _SnoozeAlarmState createState() => _SnoozeAlarmState();
}

class _SnoozeAlarmState extends State<SnoozeAlarm> {
  late double _minSnoozeDurationValue;
  late double _maxSnoozeDurationValue;
  late Timer _remainingTimeTimer;
  late Duration selectedSnoozeDurationValue;

  Future<void> handleSnooze() async {
    Navigator.of(context).pop(selectedSnoozeDurationValue.inSeconds);
  }

  @override
  void initState() {
    super.initState();

    //I assume 5 seconds is the minimal duration
    if (widget.leftSnooze <= 5) {
      Navigator.of(context).pop(0);
    }

    //I subtract 10 seconds from the actual max snooze duration - the request needs some time, there could be an unexpected timeout etc.
    _maxSnoozeDurationValue = widget.leftSnooze.toDouble() - 10;
    _minSnoozeDurationValue = 10;
    selectedSnoozeDurationValue = Duration(
        seconds:
            (widget.leftSnooze > 300 ? 300 : widget.leftSnooze.toDouble() / 2)
                .toInt());

    _remainingTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _maxSnoozeDurationValue = _maxSnoozeDurationValue - 1;
        if (selectedSnoozeDurationValue.inSeconds > _maxSnoozeDurationValue) {
          selectedSnoozeDurationValue =
              Duration(seconds: selectedSnoozeDurationValue.inSeconds - 1);
        }
      });
      //I assume 15 seconds is the lowest total remaining time
      if (_maxSnoozeDurationValue <= 15) {
        setState(() {
          _remainingTimeTimer.cancel();
          _minSnoozeDurationValue = 0;
          selectedSnoozeDurationValue = Duration.zero;
        });
        Navigator.of(context).pop(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.dark(),
        child: Scaffold(
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.snooze),
              onPressed: handleSnooze,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Slider(
                      min: _minSnoozeDurationValue.toDouble(),
                      max: _maxSnoozeDurationValue.toDouble(),
                      onChanged: (double value) {
                        setState(() {
                          selectedSnoozeDurationValue =
                              Duration(seconds: value.toInt());
                        });
                      },
                      value: selectedSnoozeDurationValue.inSeconds.toDouble(),
                    ),
                    Text(
                        "${addZero(selectedSnoozeDurationValue.inMinutes)}:${addZero(selectedSnoozeDurationValue.inSeconds.remainder(60))}")
                  ],
                ),
              ),
            )));
  }

  @override
  void dispose() {
    _remainingTimeTimer.cancel();
    super.dispose();
  }
}
