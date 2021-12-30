import 'package:buzzine/types/Audio.dart';
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
  final int? maxTotalSnoozeLength;

  final Audio? sound;

  final bool isGuardEnabled;

  final String? notes;

  const AlarmCard(
      {Key? key,
      required this.id,
      this.name,
      required this.hour,
      required this.minute,
      required this.isActive,
      this.nextInvocation,
      this.isSnoozeEnabled,
      this.maxTotalSnoozeLength,
      this.sound,
      required this.isGuardEnabled,
      this.notes})
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
      Duration difference = widget.nextInvocation!.difference(DateTime.now());
      remainingTime =
          "${addZero(difference.inHours)}:${addZero(difference.inMinutes.remainder(60))}";
    } else {
      remainingTime = '-';
    }
  }

  void setIsActive(bool status) async {
    //DEV
    //TODO: Change the alarm status

    //If the change was successful, update the state
    setState(() {
      isActive = status;
    });
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
              Switch(onChanged: setIsActive, value: isActive),
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
                        ? "Max. ${widget.maxTotalSnoozeLength} min"
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
