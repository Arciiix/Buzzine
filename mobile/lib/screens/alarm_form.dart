import 'package:buzzine/components/multiple_select.dart';
import 'package:buzzine/components/number_vertical_picker.dart';
import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/AlarmType.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/utils/formatting.dart';
import "package:flutter/material.dart";
import 'package:shared_preferences/shared_preferences.dart';

class AlarmForm extends StatefulWidget {
  final Alarm? baseAlarm;
  final AlarmType? alarmType;
  const AlarmForm({Key? key, this.baseAlarm, this.alarmType}) : super(key: key);

  @override
  _AlarmFormState createState() => _AlarmFormState();
}

class _AlarmFormState extends State<AlarmForm> {
  bool _isEditing = false;
  bool _isLoading = true;

  TextEditingController _nameController = TextEditingController();

  int _hour = TimeOfDay.now().hour;
  int _minute = TimeOfDay.now().minute;
  int? _second;

  String remainingTime = "-";

  bool _isSnoozeEnabled = true;
  int? _maxTotalSnoozeDuration = 15;

  Audio? _sound;

  bool _isGuardEnabled = true;
  bool _deleteAfterRinging = false;

  TextEditingController _notesController = TextEditingController();

  bool _isRepeating = false;
  Repeat _repeat = Repeat();
  int _emergencyAlarmTimeoutSeconds = 0;
  int _tempEmergencyAlarmTimeoutSeconds =
      GlobalData.constants.muteAfter < 60 ? 1 : 60;

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
      calculateRemainingTime(calculateTime: widget.alarmType == AlarmType.nap);
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
        emergencyAlarmTimeoutSeconds: _emergencyAlarmTimeoutSeconds,
        isActive: widget.baseAlarm?.isActive ?? true);

    if (widget.alarmType == AlarmType.nap) {
      returnedAlarm.second = _second!;
      returnedAlarm.isRepeating = false;
    }

    Navigator.of(context).pop(returnedAlarm);
  }

  void calculateRemainingTime({bool? calculateTime}) {
    DateTime now = DateTime.now();

    DateTime nextInvocation;
    if (calculateTime == true) {
      nextInvocation = DateTime.now()
          .add(Duration(hours: _hour, minutes: _minute, seconds: _second!));

      setState(() {
        remainingTime = dateToDateTimeString(nextInvocation);
      });
    } else {
      nextInvocation = DateTime(now.year, now.month, now.day, _hour, _minute);

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

  Future<Duration?> selectTimeManually(int min, int max, int init) async {
    Duration? userSelection =
        await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TimeNumberPicker(
        minDuration: min,
        maxDuration: max,
        initialTime: init,
      ),
    ));
    return userSelection;
  }

  Future<int?> selectValueManually(
      int min, int max, int init, String quantityName, String unit) async {
    int selectedValue = init;
    bool? change = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Zmień ${quantityName.toLowerCase()}"),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumberVerticalPicker(
                onChanged: (int val) => selectedValue = val,
                initValue: init,
                minValue: min,
                maxValue: max,
                propertyName: quantityName + " ($unit)",
              ),
              Text(unit)
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Zmień")),
          ],
        );
      },
    );

    return change == true ? selectedValue : null;
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
      _emergencyAlarmTimeoutSeconds =
          widget.baseAlarm?.emergencyAlarmTimeoutSeconds ?? 0;
      if (_emergencyAlarmTimeoutSeconds != 0) {
        _tempEmergencyAlarmTimeoutSeconds = _emergencyAlarmTimeoutSeconds;
      }
    }

    if (widget.alarmType == AlarmType.nap) {
      _hour = widget.baseAlarm?.hour ?? 0;
      _minute = widget.baseAlarm?.minute ?? 0;
      _second = widget.baseAlarm?.second ?? 0;
    }
    initVariables();
  }

  Future<void> initVariables() async {
    calculateRemainingTime(calculateTime: widget.alarmType == AlarmType.nap);
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
            title: Text(_isEditing
                ? "Edycja ${widget.alarmType == AlarmType.nap ? "drzemki" : "alarmu"}"
                : widget.alarmType == AlarmType.nap
                    ? "Nowa drzemka"
                    : "Nowy alarm"),
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: handleSave,
              )
            ],
          ),
          backgroundColor: Theme.of(context).cardColor,
          body: SingleChildScrollView(
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(hintText: "Nazwa"),
                      ),
                      if (widget.alarmType == AlarmType.nap)
                        InkWell(
                            onTap: () async {
                              Duration? selectedTime = await selectTimeManually(
                                  1,
                                  9999999,
                                  _hour * 3600 + _minute * 60 + _second!);
                              if (selectedTime != null) {
                                setState(() {
                                  _hour = selectedTime.inHours.remainder(60);
                                  _minute =
                                      selectedTime.inMinutes.remainder(60);
                                  _second =
                                      selectedTime.inSeconds.remainder(60);
                                });
                                calculateRemainingTime(calculateTime: true);
                              }
                            },
                            child: Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                    "${addZero(_hour)}:${addZero(_minute)}:${addZero(_second!)}",
                                    style: const TextStyle(fontSize: 52))))
                      else
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
                            builder: (_) => AlertDialog(
                                title: const Text("Różnica czasu"),
                                content: Text(widget.alarmType == AlarmType.nap
                                    ? "Data wywołania tej drzemki"
                                    : "Wartość ta, w formacie HH:mm, oznacza, za ile wywołany zostanie ten alarm."))),
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
                                InkWell(
                                  onTap: () async {
                                    int? selectedValue =
                                        await selectValueManually(
                                            _minTotalSnoozeDurationValue,
                                            _maxTotalSnoozeDurationValue,
                                            _maxTotalSnoozeDuration ?? 15,
                                            "Maksymalny łączny czas drzemek",
                                            "min");
                                    if (selectedValue != null) {
                                      setState(() {
                                        _maxTotalSnoozeDuration = selectedValue;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      "$_maxTotalSnoozeDuration min",
                                    ),
                                  ),
                                ),
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
                        children: widget.alarmType == AlarmType.nap
                            ? []
                            : [
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
                                              List<String>?
                                                  selectedDaysOfTheWeek =
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
                                                                        index +
                                                                        1)
                                                              ])
                                                          .map((e) =>
                                                              daysOfWeek[e])
                                                          .toList());
                                              if (selectedDaysOfTheWeek !=
                                                  null) {
                                                //Convert the text days names to an array of int (indexes)
                                                List<int>?
                                                    selectedDaysOfTheWeekIndexes =
                                                    selectedDaysOfTheWeek
                                                        .map((e) => daysOfWeek
                                                            .indexOf(e))
                                                        .toList();
                                                //If all week days are selected
                                                if (selectedDaysOfTheWeekIndexes
                                                        .length ==
                                                    7) {
                                                  selectedDaysOfTheWeekIndexes =
                                                      null;
                                                }
                                                setState(() {
                                                  _repeat.daysOfWeek =
                                                      selectedDaysOfTheWeekIndexes;
                                                });
                                              }
                                            },
                                            child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                        "Dni tygodnia: "),
                                                    Flexible(
                                                      child: Text(_repeat
                                                                  .daysOfWeek ==
                                                              null
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
                                                      List.generate(
                                                              31, (i) => i + 1)
                                                          .map((elem) =>
                                                              elem.toString())
                                                          .toList(),
                                                      "Wybierz dni miesiąca",
                                                      (_repeat.days ??
                                                              List.generate(
                                                                  31,
                                                                  (index) =>
                                                                      index +
                                                                      1))
                                                          .map((e) =>
                                                              e.toString())
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
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(
                                                  children: [
                                                    const Text(
                                                        "Dni miesiąca: "),
                                                    Flexible(
                                                      child: Text(
                                                          _repeat.days == null
                                                              ? "wszystkie"
                                                              : (_repeat.days ??
                                                                      [])
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
                                                                        index +
                                                                        1)
                                                              ])
                                                          .map((e) => months[e])
                                                          .toList());
                                              if (selectedMonths != null) {
                                                //Convert the text month names to an array of int (indexes)
                                                List<int>?
                                                    selectedMonthsIndexes =
                                                    selectedMonths
                                                        .map((e) =>
                                                            months.indexOf(e))
                                                        .toList();
                                                //If all months are selected
                                                if (selectedMonthsIndexes
                                                        .length ==
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
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Row(
                                                  children: [
                                                    const Text("Miesiące: "),
                                                    Flexible(
                                                      child: Text(_repeat
                                                                  .months ==
                                                              null
                                                          ? "wszystkie"
                                                          : (_repeat.months ??
                                                                  [])
                                                              .map((e) =>
                                                                  months[e]
                                                                      .substring(
                                                                          0, 3))
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
                      InkWell(
                          onTap: () => setState(() {
                                _emergencyAlarmTimeoutSeconds =
                                    _emergencyAlarmTimeoutSeconds == 0
                                        ? _tempEmergencyAlarmTimeoutSeconds
                                        : 0;
                              }),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text("Dodatkowy zapasowy alarm"),
                                Switch(
                                  value: _emergencyAlarmTimeoutSeconds != 0,
                                  onChanged: (bool value) {
                                    setState(() {
                                      _emergencyAlarmTimeoutSeconds =
                                          _emergencyAlarmTimeoutSeconds == 0
                                              ? _tempEmergencyAlarmTimeoutSeconds
                                              : 0;
                                    });
                                  },
                                )
                              ])),
                      Column(
                        children: _emergencyAlarmTimeoutSeconds != 0
                            ? [
                                Slider(
                                  min: 1,
                                  max: GlobalData.constants.muteAfter * 60 - 1,
                                  onChanged: (double value) {
                                    setState(() {
                                      _tempEmergencyAlarmTimeoutSeconds =
                                          value.floor();
                                      _emergencyAlarmTimeoutSeconds =
                                          value.floor();
                                    });
                                  },
                                  value: _tempEmergencyAlarmTimeoutSeconds
                                      .toDouble(),
                                ),
                                InkWell(
                                  onTap: () async {
                                    Duration? userSelection =
                                        await selectTimeManually(
                                            1,
                                            GlobalData.constants.muteAfter *
                                                    60 -
                                                1,
                                            _tempEmergencyAlarmTimeoutSeconds);
                                    if (userSelection != null) {
                                      setState(() {
                                        _tempEmergencyAlarmTimeoutSeconds =
                                            userSelection.inSeconds;
                                        _emergencyAlarmTimeoutSeconds =
                                            userSelection.inSeconds;
                                      });
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(addZero(
                                            (_tempEmergencyAlarmTimeoutSeconds /
                                                    60)
                                                .floor()) +
                                        ":" +
                                        addZero(
                                            _tempEmergencyAlarmTimeoutSeconds
                                                .remainder(60))),
                                  ),
                                )
                              ]
                            : [],
                      ),
                      TextFormField(
                        controller: _notesController,
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: "Notatki"),
                      ),
                    ],
                  ))));
    }
  }
}
