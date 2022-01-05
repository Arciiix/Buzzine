import 'dart:async';

import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/unlock_alarm.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class RingingAlarm extends StatefulWidget {
  const RingingAlarm({Key? key}) : super(key: key);

  @override
  _RingingAlarmState createState() => _RingingAlarmState();
}

class _RingingAlarmState extends State<RingingAlarm> {
  bool _isBlinkVisible = true;
  late Timer _blinkingTimer;
  DateTime now = DateTime.now();
  late DateTime? maxAlarmTime;
  late Duration remainingTime;

  @override
  void initState() {
    super.initState();

    maxAlarmTime = GlobalData.ringingAlarms.first.maxDate;
    remainingTime = Duration(
        seconds: maxAlarmTime?.difference(now).inSeconds ??
            GlobalData.ringingAlarms.first.alarm.maxTotalSnoozeDuration ??
            300);
    _blinkingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _isBlinkVisible = !_isBlinkVisible);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: const Key("RINGING_ALARM"),
        confirmDismiss: (DismissDirection direction) async {
          if (direction == DismissDirection.startToEnd) {
            //TODO: Check if snooze is enabled, then go to snooze length selection screen
            return false;
          } else {
            bool turnOff = await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Wyłącz alarm"),
                  content: const Text('Wyłączyć alarm?'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Anuluj"),
                    ),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text("Wyłącz")),
                  ],
                );
              },
            );
            if (turnOff) {
              //If any ringing alarm is protected, ask for the QR code

              List<Alarm>? protectedAlarm = GlobalData.ringingAlarms
                  .where((element) => element.alarm.isGuardEnabled)
                  .map((e) => e.alarm)
                  .toList();
              if (protectedAlarm.isNotEmpty) {
                bool? unlocked =
                    await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const UnlockAlarm(),
                ));
                if (unlocked != true) {
                  return false;
                }
              }
              await GlobalData.cancelAllAlarms();
              Navigator.of(context).pop();
            }
            return false;
          }
        },
        background: Scaffold(
            body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Container(
                color: Colors.blue,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width * 0.5,
                child: Row(children: const [
                  Icon(Icons.snooze, color: Colors.white),
                  Text("Drzemka", style: TextStyle(color: Colors.white))
                ])),
            Container(
                color: Colors.red,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width * 0.5,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: const [
                      Icon(Icons.delete, color: Colors.white),
                      Text("Usuń", style: TextStyle(color: Colors.white))
                    ])),
          ],
        )),
        child: Scaffold(
            backgroundColor: Colors.black,
            body: Row(children: [
              SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: 30,
                  child: const DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                              topRight: Radius.circular(5),
                              bottomRight: Radius.circular(5))))),
              Expanded(
                  child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedOpacity(
                      opacity: _isBlinkVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 100),
                      child: Column(
                        children: [
                          Text(
                              GlobalData.ringingAlarms.isNotEmpty
                                  ? addZero(GlobalData
                                          .ringingAlarms.last.alarm.hour) +
                                      ":" +
                                      addZero(GlobalData
                                          .ringingAlarms.last.alarm.minute)
                                  : "${addZero(now.hour)}:${addZero(now.minute)}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 72)),
                          Text(
                              "${addZero(now.day)}.${addZero(now.month)}.${now.year}",
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 24)),
                        ],
                      ),
                    ),
                    const Text("DEV WARNING: This screen isn't ready yet 👀",
                        style: TextStyle(color: Colors.yellow))
                  ],
                ),
              )),
              SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: 30,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(5),
                            bottomLeft: Radius.circular(5))),
                  )),
            ])));
  }

  @override
  void dispose() {
    _blinkingTimer.cancel();
    super.dispose();
  }
}
