import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class SnoozeCard extends StatefulWidget {
  final String? name;
  final DateTime invocationDate;
  final DateTime maxAlarmTime;

  final int? maxTotalSnoozeDuration;

  final Audio? sound;

  final bool isGuardEnabled;
  final bool? deleteAfterRinging;

  final String? notes;

  final bool? isRepeating;
  final Repeat? repeat;

  const SnoozeCard({
    Key? key,
    this.name,
    required this.invocationDate,
    required this.maxAlarmTime,
    this.maxTotalSnoozeDuration,
    this.sound,
    required this.isGuardEnabled,
    this.deleteAfterRinging,
    this.notes,
    this.isRepeating,
    this.repeat,
  }) : super(key: key);

  @override
  _SnoozeCardState createState() => _SnoozeCardState();
}

class _SnoozeCardState extends State<SnoozeCard> {
  late String remainingTime;
  late int hour;
  late int minute;
  late int remainingSnoozeMinutes;

  @override
  void initState() {
    super.initState();

    Duration difference = widget.invocationDate.difference(DateTime.now());
    remainingTime =
        "${difference.inDays > 0 ? addZero(difference.inDays) + ":" : ""}${addZero(difference.inHours)}:${addZero(difference.inMinutes.remainder(60))}";

    hour = widget.invocationDate.toLocal().hour;
    minute = widget.invocationDate.toLocal().minute;

    remainingSnoozeMinutes =
        widget.maxAlarmTime.difference(widget.invocationDate).inMinutes;
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${addZero(hour)}:${addZero(minute)}",
                    style: const TextStyle(fontSize: 50)),
              ],
            ),
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
                    child: Text(
                        "Max. ${((widget.maxTotalSnoozeDuration ?? 0) / 60).floor()} min/pozostało $remainingSnoozeMinutes"))
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
