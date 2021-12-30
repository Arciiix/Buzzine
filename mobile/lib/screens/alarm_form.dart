import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/utils/formatting.dart';
import "package:flutter/material.dart";

class AlarmForm extends StatefulWidget {
  final Alarm? baseAlarm;
  const AlarmForm({Key? key, this.baseAlarm}) : super(key: key);

  @override
  _AlarmFormState createState() => _AlarmFormState();
}

class _AlarmFormState extends State<AlarmForm> {
  bool _isEditing = false;

  TextEditingController _nameController = TextEditingController();

  int _hour = TimeOfDay.now().hour;
  int _minute = TimeOfDay.now().minute;

  String remainingTime = "-";

  bool _isSnoozeEnabled = true;
  int? _maxTotalSnoozeLength = 15;

  Audio? _sound;

  bool _isGuardEnabled = true;

  TextEditingController _notesController = TextEditingController();

  void getTime() async {
    final TimeOfDay? timePickerResponse = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: _hour, minute: _minute),
        cancelText: "Anuluj",
        confirmText: "Zatwierdź",
        helpText: "Wybierz czas",
        errorInvalidText: "Zły czas",
        hourLabelText: "Godzina",
        minuteLabelText: "Minuta");

    if (timePickerResponse != null) {
      setState(() {
        _hour = timePickerResponse.hour;
        _minute = timePickerResponse.minute;
      });
      calculateRemainingTime();
    }
  }

  void handleSave() {
    Alarm returnedAlarm = Alarm(
        name: _nameController.text,
        hour: _hour,
        minute: _minute,
        isSnoozeEnabled: _isSnoozeEnabled,
        maxTotalSnoozeLength: _maxTotalSnoozeLength,
        sound: _sound,
        isGuardEnabled: _isGuardEnabled,
        notes: _notesController.text,
        isActive: widget.baseAlarm?.isActive ?? true);

    Navigator.of(context).pop(returnedAlarm);
  }

  void calculateRemainingTime() {
    DateTime now = DateTime.now();
    DateTime nextInvocation =
        DateTime(now.year, now.month, now.day, _hour, _minute);

    if (now.compareTo(nextInvocation) <= 0) {
      //If alarm time is before now, add a whole day (so it'll be tomorrow)
      nextInvocation.add(const Duration(days: 1));
    }

    Duration difference = nextInvocation.difference(DateTime.now());

    setState(() {
      remainingTime =
          "${addZero(difference.inHours)}:${addZero(difference.inMinutes.remainder(60))}";
    });
  }

  void chooseAudio() async {
    //DEV
    print("TODO: Choose audio");
  }

  @override
  void initState() {
    super.initState();
    if (widget.baseAlarm != null) {
      _isEditing = true;
      _nameController.text = widget.baseAlarm?.name ?? "";
      _hour = widget.baseAlarm!.hour;
      _minute = widget.baseAlarm!.minute;
      _isSnoozeEnabled = widget.baseAlarm?.isSnoozeEnabled ?? false;
      _maxTotalSnoozeLength = widget.baseAlarm?.maxTotalSnoozeLength ?? 15;
      _sound = widget.baseAlarm?.sound;
      _isGuardEnabled = widget.baseAlarm!.isGuardEnabled;
      _notesController.text = widget.baseAlarm?.notes ?? "";
    }
    calculateRemainingTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? "Edycja alarmu" : "Nowy alarm"),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: handleSave,
            )
          ],
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
            child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(hintText: "Nazwa"),
                    ),
                    InkWell(
                        onTap: getTime,
                        child: Padding(
                            padding: EdgeInsets.all(8),
                            child: Text("${addZero(_hour)}:${addZero(_minute)}",
                                style: const TextStyle(fontSize: 52)))),
                    InkWell(
                      onTap: () => showDialog(
                          context: context,
                          builder: (_) => const AlertDialog(
                              title: Text("Różnica czasu"),
                              content: Text(
                                  "Wartość ta, w formacie HH:mm, oznacza, za ile wywołany zostanie ten alarm."))),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule),
                          Padding(
                              padding: const EdgeInsets.all(5),
                              child: Text(remainingTime))
                        ],
                      ),
                    ),
                    InkWell(
                        onTap: () {
                          setState(() {
                            _isGuardEnabled = !_isGuardEnabled;
                          });
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(_isGuardEnabled
                                      ? Icons.verified_user
                                      : Icons.privacy_tip),
                                  const Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text("Ochrona"))
                                ],
                              ),
                              Switch(
                                value: _isGuardEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isGuardEnabled = value;
                                  });
                                },
                              )
                            ])),
                    InkWell(
                        onTap: () {
                          setState(() {
                            _isSnoozeEnabled = !_isSnoozeEnabled;
                          });
                        },
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.snooze),
                                  Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text("Drzemki"))
                                ],
                              ),
                              Switch(
                                value: _isSnoozeEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _isSnoozeEnabled = value;
                                  });
                                },
                              )
                            ])),
                    Column(
                      children: _isSnoozeEnabled
                          ? [
                              Container(
                                  width: double.infinity,
                                  child: const Text(
                                    "Maksymalny łączny czas drzemek",
                                  )),
                              Slider(
                                min: 5,
                                max: 30,
                                onChanged: (double value) {
                                  setState(() {
                                    _maxTotalSnoozeLength = value.toInt();
                                  });
                                },
                                value:
                                    _maxTotalSnoozeLength?.toDouble() ?? 15.0,
                              ),
                              Text(
                                "$_maxTotalSnoozeLength min",
                              )
                            ]
                          : [],
                    ),
                    InkWell(
                        onTap: chooseAudio,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.music_note),
                                  Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Text(
                                          _sound?.friendlyName ?? "Domyślna"))
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: chooseAudio,
                              )
                            ])),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: "Notatki"),
                    ),
                  ],
                ))));
  }
}
