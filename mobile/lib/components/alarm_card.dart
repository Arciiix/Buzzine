import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class AlarmCard extends StatefulWidget {
  final String id;
  final String? name;
  final int hour;
  final int minute;
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

  final bool? hideSwitch;

  final Function? refresh;

  const AlarmCard(
      {Key? key,
      required this.id,
      this.name,
      required this.hour,
      required this.minute,
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
      this.hideSwitch,
      this.refresh})
      : super(key: key);

  @override
  _AlarmCardState createState() => _AlarmCardState();
}

class _AlarmCardState extends State<AlarmCard> {
  late String remainingTime;
  late bool isActive;

  @override
  void initState() {
    super.initState();

    isActive = widget.isActive;
    if (widget.nextInvocation != null) {
      remainingTime = calculateDateTimeDifference(widget.nextInvocation!);
    } else {
      remainingTime = '-';
    }
  }

  String calculateDateTimeDifference(DateTime nextInvocation) {
    Duration difference = nextInvocation.difference(DateTime.now());
    if (difference.inSeconds < 0) {
      //It means that the alarm has already invoked
      return "-";
    }
    String remainingTime =
        "${difference.inDays > 0 ? addZero(difference.inDays) + ":" : ""}${addZero(difference.inHours.remainder(24))}:${addZero(difference.inMinutes.remainder(60))}";

    return remainingTime;
  }

  void setIsActive(bool status) async {
    await GlobalData.changeAlarmStatus(widget.id, status);
    setState(() {
      isActive = status;
      if (isActive && widget.nextInvocation != null) {
        //Calculate the remaining time from the initial value - because the alarm recreates
        remainingTime = calculateDateTimeDifference(widget.nextInvocation!);
      } else if (!isActive) {
        remainingTime = "-";
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
      DateTime? nextInvocation =
          await GlobalData.cancelNextInvocation(widget.id);
      if (nextInvocation != null) {
        setState(() {
          remainingTime = calculateDateTimeDifference(nextInvocation);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
                child: Text(
              widget.name ?? "Alarm bez nazwy",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18),
            )),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${addZero(widget.hour)}:${addZero(widget.minute)}",
                      style: const TextStyle(fontSize: 50)),
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
            Row(
              children: [
                const Icon(Icons.schedule),
                Padding(
                    padding: const EdgeInsets.all(5),
                    child: Text(remainingTime))
              ],
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
              const Icon(Icons.verified_user),
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
                const Icon(Icons.subject),
                Flexible(
                    child: Text(
                  widget.notes ?? "Brak",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                )),
              ],
            ),
          ],
        ));
  }
}
