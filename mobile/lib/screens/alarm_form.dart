import 'package:buzzine/components/multiple_select.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/utils/formatting.dart';
import "package:flutter/material.dart";
import 'package:shared_preferences/shared_preferences.dart';

class AlarmForm extends StatefulWidget {
  final Alarm? baseAlarm;
  const AlarmForm({Key? key, this.baseAlarm}) : super(key: key);

  @override
  _AlarmFormState createState() => _AlarmFormState();
}

class _AlarmFormState extends State<AlarmForm> {
  bool _isEditing = false;
  bool _isLoading = true;

  TextEditingController _nameController = TextEditingController();

  int _hour = TimeOfDay.now().hour;
  int _minute = TimeOfDay.now().minute;

  String remainingTime = "-";

  bool _isSnoozeEnabled = true;
  int? _maxTotalSnoozeDuration = 15;

  Audio? _sound;

  bool _isGuardEnabled = true;
  bool _deleteAfterRinging = false;

  TextEditingController _notesController = TextEditingController();

  bool _isRepeating = false;
  Repeat _repeat = Repeat();

  int _minTotalSnoozeDurationValue = 5;
  int _maxTotalSnoozeDurationValue = 60;

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
        id: widget.baseAlarm?.id,
        name: _nameController.text,
        hour: _hour,
        minute: _minute,
        isSnoozeEnabled: _isSnoozeEnabled,
        maxTotalSnoozeDuration: _maxTotalSnoozeDuration != null
            ? _maxTotalSnoozeDuration! * 60
            : null,
        sound: _sound,
        isGuardEnabled: _isGuardEnabled,
        deleteAfterRinging: _deleteAfterRinging,
        notes: _notesController.text,
        isRepeating: _isRepeating,
        repeat: _repeat,
        isActive: widget.baseAlarm?.isActive ?? true);

    Navigator.of(context).pop(returnedAlarm);
  }

  void calculateRemainingTime() {
    DateTime now = DateTime.now();
    DateTime nextInvocation =
        DateTime(now.year, now.month, now.day, _hour, _minute);

    if (now.isAfter(nextInvocation)) {
      //If alarm time is before now, add a whole day (so it'll be tomorrow)
      nextInvocation = nextInvocation.add(const Duration(days: 1));
    }

    Duration difference = nextInvocation.difference(DateTime.now());

    setState(() {
      remainingTime =
          "${addZero(difference.inHours)}:${addZero(difference.inMinutes.remainder(60))}";
    });
  }

  void chooseAudio() async {
    Audio? selectedAudio = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const AudioManager(
        selectAudio: true,
      ),
    ));

    if (selectedAudio != null) {
      setState(() {
        _sound = selectedAudio;
      });
    }
  }

  Future<void> fetchMinAndMaxTotalSnoozeDurationValue() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    int minTotalSnoozeDurationValue =
        _prefs.getInt("MIN_TOTAL_SNOOZE_TIME_VALUE") ?? 5;
    int maxTotalSnoozeDurationValue =
        _prefs.getInt("MAX_TOTAL_SNOOZE_TIME_VALUE") ?? 60;

    //If the min (or max) value of snooze is higher (lower) than the currently set one, change it to the current value - avoid getting an val < min (val > max) error
    setState(() {
      _minTotalSnoozeDurationValue =
          ((_maxTotalSnoozeDuration ?? minTotalSnoozeDurationValue) <
                  minTotalSnoozeDurationValue
              ? _maxTotalSnoozeDuration
              : minTotalSnoozeDurationValue)!;
      _maxTotalSnoozeDurationValue =
          ((_maxTotalSnoozeDuration ?? maxTotalSnoozeDurationValue) >
                  maxTotalSnoozeDurationValue
              ? _maxTotalSnoozeDuration
              : maxTotalSnoozeDurationValue)!;
    });
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
      _maxTotalSnoozeDuration =
          ((widget.baseAlarm?.maxTotalSnoozeDuration ?? 300) / 60).floor();
      _sound = widget.baseAlarm?.sound;
      _isGuardEnabled = widget.baseAlarm!.isGuardEnabled;
      _deleteAfterRinging = widget.baseAlarm!.deleteAfterRinging ?? false;
      _notesController.text = widget.baseAlarm?.notes ?? "";
      _isRepeating = widget.baseAlarm?.isRepeating ?? false;
      _repeat = widget.baseAlarm?.repeat ?? Repeat();
    }
    initVariables();
  }

  Future<void> initVariables() async {
    calculateRemainingTime();
    await fetchMinAndMaxTotalSnoozeDurationValue();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Loading();
    } else {
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
                              child: Text(
                                  "${addZero(_hour)}:${addZero(_minute)}",
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
                                  min: _minTotalSnoozeDurationValue.toDouble(),
                                  max: _maxTotalSnoozeDurationValue.toDouble(),
                                  onChanged: (double value) {
                                    setState(() {
                                      _maxTotalSnoozeDuration = value.toInt();
                                    });
                                  },
                                  value: _maxTotalSnoozeDuration?.toDouble() ??
                                      15.0,
                                ),
                                Text(
                                  "$_maxTotalSnoozeDuration min",
                                )
                              ]
                            : [],
                      ),
                      InkWell(
                          onTap: chooseAudio,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                    child: Row(
                                  children: [
                                    const Icon(Icons.music_note),
                                    Expanded(
                                        child: Text(
                                            _sound?.friendlyName ?? "Domyślna"))
                                  ],
                                )),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: chooseAudio,
                                )
                              ])),
                      Column(
                        children: [
                          InkWell(
                              onTap: () => setState(() {
                                    _isRepeating = !_isRepeating;
                                  }),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Powtarzaj"),
                                    Switch(
                                      value: _isRepeating,
                                      onChanged: (bool value) {
                                        setState(() {
                                          _isRepeating = value;
                                        });
                                      },
                                    )
                                  ])),
                          ...(_isRepeating
                              ? [
                                  InkWell(
                                      onTap: () async {
                                        List<String>? selectedDaysOfTheWeek =
                                            await showMultipleSelect(
                                                context,
                                                daysOfWeek,
                                                "Wybierz dni tygodnia",
                                                (_repeat.daysOfWeek ??
                                                        [
                                                          0,
                                                          ...List.generate(
                                                              6,
                                                              (index) =>
                                                                  index + 1)
                                                        ])
                                                    .map((e) => daysOfWeek[e])
                                                    .toList());
                                        if (selectedDaysOfTheWeek != null) {
                                          //Convert the text days names to an array of int (indexes)
                                          List<int>?
                                              selectedDaysOfTheWeekIndexes =
                                              selectedDaysOfTheWeek
                                                  .map((e) =>
                                                      daysOfWeek.indexOf(e))
                                                  .toList();
                                          //If all week days are selected
                                          if (selectedDaysOfTheWeekIndexes
                                                  .length ==
                                              7) {
                                            selectedDaysOfTheWeekIndexes = null;
                                          }
                                          setState(() {
                                            _repeat.daysOfWeek =
                                                selectedDaysOfTheWeekIndexes;
                                          });
                                        }
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              const Text("Dni tygodnia: "),
                                              Flexible(
                                                child: Text(
                                                    _repeat.daysOfWeek == null
                                                        ? "wszystkie"
                                                        : (_repeat.daysOfWeek ??
                                                                [])
                                                            .map((e) =>
                                                                daysOfWeek[e]
                                                                    .substring(
                                                                        0, 3))
                                                            .toList()
                                                            .join(', ')),
                                              )
                                            ],
                                          ))),
                                  InkWell(
                                      onTap: () async {
                                        List<String>? selectedDays =
                                            await showMultipleSelect(
                                                context,
                                                List.generate(31, (i) => i + 1)
                                                    .map((elem) =>
                                                        elem.toString())
                                                    .toList(),
                                                "Wybierz dni miesiąca",
                                                (_repeat.days ??
                                                        List.generate(
                                                            31,
                                                            (index) =>
                                                                index + 1))
                                                    .map((e) => e.toString())
                                                    .toList());

                                        //If all days are selected
                                        if (selectedDays?.length == 31) {
                                          selectedDays = null;
                                        }
                                        if (selectedDays != null) {
                                          setState(() {
                                            _repeat.days = selectedDays
                                                ?.map((e) => int.parse(e))
                                                .toList();
                                          });
                                        } else {
                                          setState(() {
                                            _repeat.days = null;
                                          });
                                        }
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              const Text("Dni miesiąca: "),
                                              Flexible(
                                                child: Text(_repeat.days == null
                                                    ? "wszystkie"
                                                    : (_repeat.days ?? [])
                                                        .toList()
                                                        .join(', ')),
                                              )
                                            ],
                                          ))),
                                  InkWell(
                                      onTap: () async {
                                        List<String>? selectedMonths =
                                            await showMultipleSelect(
                                                context,
                                                months,
                                                "Wybierz miesiące",
                                                (_repeat.months ??
                                                        [
                                                          0,
                                                          ...List.generate(
                                                              11,
                                                              (index) =>
                                                                  index + 1)
                                                        ])
                                                    .map((e) => months[e])
                                                    .toList());
                                        if (selectedMonths != null) {
                                          //Convert the text month names to an array of int (indexes)
                                          List<int>? selectedMonthsIndexes =
                                              selectedMonths
                                                  .map((e) => months.indexOf(e))
                                                  .toList();
                                          //If all months are selected
                                          if (selectedMonthsIndexes.length ==
                                              12) {
                                            selectedMonthsIndexes = null;
                                          }
                                          setState(() {
                                            _repeat.months =
                                                selectedMonthsIndexes;
                                          });
                                        }
                                      },
                                      child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            children: [
                                              const Text("Miesiące: "),
                                              Flexible(
                                                child: Text(_repeat.months ==
                                                        null
                                                    ? "wszystkie"
                                                    : (_repeat.months ?? [])
                                                        .map((e) => months[e]
                                                            .substring(0, 3))
                                                        .toList()
                                                        .join(', ')),
                                              )
                                            ],
                                          ))),
                                ]
                              : [])
                        ],
                      ),
                      InkWell(
                          onTap: () => setState(() {
                                _deleteAfterRinging = !_deleteAfterRinging;
                              }),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Usuń po zadzwonieniu"),
                                Switch(
                                  value: _deleteAfterRinging,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _deleteAfterRinging = value;
                                    });
                                  },
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
}
