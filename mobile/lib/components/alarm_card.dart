import 'dart:async';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/AlarmType.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class AlarmCard extends StatefulWidget {
  final String id;
  final String? name;
  final int hour;
  final int minute;
  final int? second;
  final DateTime? nextInvocation;
  final bool isActive;

  final bool? isSnoozeEnabled;
  final int? maxTotalSnoozeDuration;

  final Audio? sound;

  final bool isGuardEnabled;
  final bool? deleteAfterRinging;

  final String? notes;

  final bool? isRepeating;
  final Repeat? repeat;
  final int? emergencyAlarmTimeoutSeconds;

  final bool? hideSwitch;

  final Function? refresh;

  final AlarmType? alarmType;

  const AlarmCard(
      {Key? key,
      required this.id,
      this.name,
      required this.hour,
      required this.minute,
      this.second,
      required this.isActive,
      this.nextInvocation,
      this.isSnoozeEnabled,
      this.maxTotalSnoozeDuration,
      this.sound,
      required this.isGuardEnabled,
      this.deleteAfterRinging,
      this.notes,
      this.isRepeating,
      this.repeat,
      this.emergencyAlarmTimeoutSeconds,
      this.hideSwitch,
      this.refresh,
      this.alarmType})
      : super(key: key);

  @override
  _AlarmCardState createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  late String timeDetailsTextContent;
  late String timeTextContent;
  late bool isActive;
  Timer? _updateRemainingTimeTimer;

  @override
  void initState() {
    super.initState();

    isActive = widget.isActive;
    if (widget.nextInvocation != null) {
      timeDetailsTextContent = calculateDateTimeDifference(
          widget.nextInvocation!,
          includeSeconds: widget.alarmType == AlarmType.nap);
    } else {
      timeDetailsTextContent = '-';
    }

    if (widget.alarmType == AlarmType.nap) {
      timeTextContent =
          "${addZero(widget.hour)}:${addZero(widget.minute)}:${addZero(widget.second!)}";
    } else {
      timeTextContent = "${addZero(widget.hour)}:${addZero(widget.minute)}";
    }

    if (widget.nextInvocation != null) {
      setTimer();
    }
  }

  void setTimer() {
    setState(() {
      _updateRemainingTimeTimer =
          Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          timeDetailsTextContent = widget.nextInvocation != null
              ? calculateDateTimeDifference(widget.nextInvocation!,
                  includeSeconds: widget.alarmType == AlarmType.nap)
              : "-";
        });
      });
    });
  }

  String calculateDateTimeDifference(DateTime nextInvocation,
      {bool? includeSeconds}) {
    Duration difference = nextInvocation.difference(DateTime.now());
    if (difference.inSeconds < 0) {
      //It means that the alarm has already invoked
      return "-";
    }
    String timeDetailsTextContent =
        "${difference.inDays > 0 ? addZero(difference.inDays) + ":" : ""}${addZero(difference.inHours.remainder(24))}:${addZero(difference.inMinutes.remainder(60))}${includeSeconds == true ? ":" + addZero(difference.inSeconds.remainder(60)) : ""}";

    return timeDetailsTextContent;
  }

  void setIsActive(bool status) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa zmiana statusu alarmu...");
      },
    );
    _updateRemainingTimeTimer?.cancel();
    await GlobalData.changeAlarmStatus(widget.id, status);
    Navigator.of(context).pop();
    setState(() {
      isActive = status;
      if (isActive && widget.nextInvocation != null) {
        //Calculate the remaining time from the initial value - because the alarm recreates
        timeDetailsTextContent = calculateDateTimeDifference(
            widget.nextInvocation!,
            includeSeconds: widget.alarmType == AlarmType.nap);
        setTimer();
      } else if (!isActive) {
        timeDetailsTextContent = "-";
      }
    });
    if (widget.refresh != null) {
      widget.refresh!();
    }
  }

  void askToCancelNextInvocation() async {
    DateTime? nextInvocationLocal = widget.nextInvocation?.toLocal();
    String? nextInvocationString;
    if (nextInvocationLocal != null) {
      nextInvocationString =
          "${addZero(nextInvocationLocal.day)}.${addZero(nextInvocationLocal.month)}.${nextInvocationLocal.year} ${addZero(nextInvocationLocal.hour)}:${addZero(nextInvocationLocal.minute)}";
    }
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wyłącz następne wywołanie alarmu"),
          content: Text(
              'Czy na pewno chcesz wyłączyć następne wywołanie tego alarmu?${nextInvocationString != null ? "\nAlarm zadzwoniłby $nextInvocationString" : ""}'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wygeneruj")),
          ],
        );
      },
    );

    //It could be either null, so I check it by ==
    if (confirmed == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa anulowanie następnego wywołania...");
        },
      );
      DateTime? nextInvocation =
          await GlobalData.cancelNextInvocation(widget.id);
      Navigator.of(context).pop();
      if (nextInvocation != null) {
        setState(() {
          timeDetailsTextContent = calculateDateTimeDifference(nextInvocation);
        });
      }
    }
  }

  void showInvocationDateAlertDialog() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Drzemka"),
              content: Text(
                  "Ta drzemka zadzwoni: ${dateToDateTimeString(widget.nextInvocation!.toLocal())}"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
                child: Text(
              widget.name ??
                  (widget.alarmType == AlarmType.nap
                      ? "Drzemka bez nazwy"
                      : "Alarm bez nazwy"),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            )),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(timeTextContent, style: const TextStyle(fontSize: 44)),
                ],
              ),
              if (widget.hideSwitch != true)
                GestureDetector(
                    onLongPress: () async {
                      if (widget.isRepeating == true && widget.isActive) {
                        askToCancelNextInvocation();
                      }
                    },
                    child: Switch(onChanged: setIsActive, value: isActive)),
            ]),
            InkWell(
              onTap: widget.alarmType == AlarmType.nap &&
                      widget.nextInvocation != null
                  ? showInvocationDateAlertDialog
                  : null,
              child: Row(
                children: [
                  const Icon(Icons.schedule),
                  Padding(
                      padding: const EdgeInsets.all(5),
                      child: Text(timeDetailsTextContent))
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.snooze),
                Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(widget.isSnoozeEnabled == true
                        ? "Max. ${((widget.maxTotalSnoozeDuration ?? 0) / 60).floor()} min"
                        : "Wyłączona"))
              ],
            ),
            Row(
              children: [
                const Icon(Icons.music_note),
                Flexible(
                    child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Text(
                          widget.sound?.friendlyName ?? "Domyślna",
                          overflow: TextOverflow.ellipsis,
                        )))
              ],
            ),
            Row(children: [
              Icon(widget.isGuardEnabled ? Icons.lock : Icons.lock_open),
              Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                      "Ochrona ${widget.isGuardEnabled ? "włączona" : "wyłączona"}"))
            ]),
            Column(
                children: widget.isRepeating == true
                    ? [
                        Row(children: const [
                          Icon(Icons.repeat),
                          Text("Powtarzanie")
                        ]),
                        Row(children: [
                          const Text("Dni tygodnia: "),
                          Flexible(
                              child: Text(
                            widget.repeat!.daysOfWeek == null
                                ? "wszystkie"
                                : (widget.repeat!.daysOfWeek ?? [])
                                    .map((e) => daysOfWeek[e].substring(0, 3))
                                    .toList()
                                    .join(', '),
                            overflow: TextOverflow.ellipsis,
                          ))
                        ]),
                        Row(children: [
                          const Text("Dni miesiąca: "),
                          Flexible(
                            child: Text(
                              widget.repeat!.days == null
                                  ? "wszystkie"
                                  : (widget.repeat!.days ?? [])
                                      .toList()
                                      .join(', '),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ]),
                        Row(children: [
                          const Text("Miesiące: "),
                          Flexible(
                            child: Text(
                              widget.repeat!.months == null
                                  ? "wszystkie"
                                  : (widget.repeat!.months ?? [])
                                      .map((e) => months[e].substring(0, 3))
                                      .toList()
                                      .join(', '),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ]),
                        const SizedBox(height: 10)
                      ]
                    : [
                        Row(
                            children: widget.deleteAfterRinging == true
                                ? const [
                                    SizedBox(
                                        width:
                                            2.5), //Flutter, for some reason, adds extra blank space on the left side of the icon.
                                    Icon(Icons.auto_delete),
                                    Text("Jednorazowy")
                                  ]
                                : const [
                                    Icon(Icons.repeat_one),
                                    Text("Ręczny")
                                  ]),
                      ]),
            Row(
              children: [
                Icon(Icons.verified_user),
                Flexible(
                    child: Text(
                  "Zapasowy alarm: ${widget.emergencyAlarmTimeoutSeconds != null && widget.emergencyAlarmTimeoutSeconds != 0 ? addZero((widget.emergencyAlarmTimeoutSeconds! / 60).floor()) + ":" + addZero(widget.emergencyAlarmTimeoutSeconds!.remainder(60)) : "tylko ochrona"}",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.subject),
                Flexible(
                    child: Text(
                  widget.notes ?? "Brak",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                )),
              ],
            ),
          ],
        ));
  }

  @override
  void dispose() {
    _updateRemainingTimeTimer?.cancel();
    super.dispose();
  }
}
