import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/sleep_calculations_screen.dart';
import 'package:buzzine/types/SleepCalculations.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class SleepCalculationsWidget extends StatefulWidget {
  final Function? onRefresh;

  const SleepCalculationsWidget({Key? key, this.onRefresh}) : super(key: key);

  @override
  State<SleepCalculationsWidget> createState() =>
      _SleepCalculationsWidgetState();
}

class _SleepCalculationsWidgetState extends State<SleepCalculationsWidget> {
  late SleepCalculations _calculations;

  Future<void> addAlarm() async {
    await _calculations.addAlarm(context);

    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  Future<void> navigateToSleepCalculationsScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SleepCalculationsScreen(
              initCalculations: _calculations,
              onRefresh: () {
                if (widget.onRefresh != null) {
                  widget.onRefresh!();
                }
              },
            )));
  }

  @override
  Widget build(BuildContext context) {
    _calculations = SleepCalculations(
        targetDuration: GlobalData.targetSleepDuration,
        targetTimeToFallAsleep: GlobalData.targetFallingAsleepTime);

    return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: navigateToSleepCalculationsScreen,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alarm),
                      Text(
                          dateToTimeString(_calculations.alarmTime,
                              excludeSeconds: true),
                          style: const TextStyle(fontSize: 24)),
                    ],
                  ),
                  Text(
                      "Aby spa?? ${durationToHHmm(_calculations.sleepDuration)}"),
                  TextButton(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.add),
                        Text("Ustaw alarm"),
                      ],
                    ),
                    onPressed: addAlarm,
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
