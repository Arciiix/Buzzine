import 'dart:math';
import 'package:buzzine/components/select_number_slider.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class TrackingScreen extends StatefulWidget {
  final DateTime initDate;
  const TrackingScreen({Key? key, required this.initDate}) : super(key: key);

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isLoaded = false;
  late List<TrackingEntry> _entries;
  late DateTime _selectedDate;

  double leftIconOffset = 0;
  double rightIconOffset = 0;

  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  Future<void> getDataForDay(DateTime day) async {
    List<TrackingEntry> data = await GlobalData.getTrackingEntriesForDay(day);

    setState(() {
      _entries = data;
      _selectedDate = day;
    });
  }

  Future<void> updateEntry(DateTime date, Map dataToUpdate) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa aktualizacja danych snu...");
      },
    );
    dataToUpdate.removeWhere((key, value) => value == null);
    await GlobalData.updateTrackingEntry(date, dataToUpdate);
    Navigator.of(context).pop();
    await refresh();
  }

  Future<void> selectDate() async {
    DateTime? datePickerResponse = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        lastDate: DateTime.now(),
        cancelText: "Anuluj",
        confirmText: "Zatwierdź",
        helpText: "Wybierz datę",
        errorInvalidText: "Zła data",
        errorFormatText: "Zły format",
        fieldHintText: "Podaj datę",
        fieldLabelText: "Data",
        firstDate: DateTime(2022, 1, 1, 0, 0, 0));

    if (datePickerResponse != null) {
      await getDataForDay(datePickerResponse);
      await refresh();
    }
  }

  Future<DateTime?> askForTime() async {
    DateTime? datePickerResponse = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        lastDate: DateTime.now().add(const Duration(days: 1)),
        cancelText: "Anuluj",
        confirmText: "Zatwierdź",
        helpText: "Wybierz datę",
        errorInvalidText: "Zła data",
        errorFormatText: "Zły format",
        fieldHintText: "Podaj datę",
        fieldLabelText: "Data",
        firstDate: DateTime(2022, 1, 1, 0, 0, 0));

    if (datePickerResponse == null) {
      return null;
    } else {
      final TimeOfDay? timePickerResponse = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
              hour: DateTime.now().hour, minute: DateTime.now().minute),
          cancelText: "Anuluj",
          confirmText: "Zatwierdź",
          helpText: "Wybierz czas",
          errorInvalidText: "Zły czas",
          hourLabelText: "Godzina",
          minuteLabelText: "Minuta");

      if (timePickerResponse != null) {
        return DateTime(
            datePickerResponse.year,
            datePickerResponse.month,
            datePickerResponse.day,
            timePickerResponse.hour,
            timePickerResponse.minute);
      }
    }
  }

  Future<TrackingVersionHistory?> showVersionHistory(
      List<TrackingVersionHistory> history, bool isValueTimestamp) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Historia wersji"),
          content: Container(
            height: 300,
            width: 200,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                          title: Text(isValueTimestamp
                              ? dateToDateTimeString(
                                  DateTime.parse(history[index].value))
                              : DateTime.parse(history[index].value)
                                  .millisecondsSinceEpoch
                                  .toString()),
                          subtitle: Text(
                              dateToDateTimeString(history[index].timestamp)),
                          onTap: () =>
                              Navigator.of(context).pop(history[index]));
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
          ],
        );
      },
    );
  }

  void dateForward() async {
    if (_selectedDate
            .add(const Duration(days: 1))
            .compareTo(DateTime.now().add(const Duration(days: 1))) <=
        0) {
      getDataForDay(_selectedDate.add(const Duration(days: 1)));
    } else {
      showSnackbar(context, "Wybierz wcześniejszą datę");
    }
  }

  void dateBackward() async {
    getDataForDay(_selectedDate.subtract(const Duration(days: 1)));
  }

  Future<void> deleteEntry(DateTime date) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa usuwanie snu...");
      },
    );
    await GlobalData.deleteTrackingEntry(date);
    Navigator.of(context).pop();
    await refresh();
  }

  Future<void> refresh() async {
    await _refreshState.currentState!.show();
  }

  @override
  void initState() {
    getDataForDay(widget.initDate)
        .then((value) => setState(() => _isLoaded = true));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return Stack(children: [
        GestureDetector(
          onHorizontalDragEnd: (DragEndDetails details) {
            if ((details.primaryVelocity ?? 0) > 0) {
              dateBackward();
            }
            if ((details.primaryVelocity ?? 0) < 0) {
              dateForward();
            }
            setState(() {
              rightIconOffset = 0;
              leftIconOffset = 0;
            });
          },
          onHorizontalDragUpdate: (details) {
            setState(() {
              if (details.delta.dx * details.delta.distance * 5 > 0) {
                leftIconOffset =
                    min(details.delta.dx * details.delta.distance * 5, 20);
                rightIconOffset = 0;
              } else {
                rightIconOffset =
                    max(details.delta.dx * details.delta.distance * 5, 20);
                leftIconOffset = 0;
              }
            });
          },
          child: Scaffold(
              appBar: AppBar(
                title: Text("Sen"),
              ),
              floatingActionButton: _selectedDate.year != DateTime.now().year ||
                      _selectedDate.month != DateTime.now().month ||
                      _selectedDate.day != DateTime.now().day
                  ? FloatingActionButton(
                      child: const Icon(Icons.calendar_today),
                      onPressed: () async => getDataForDay(DateTime.now()))
                  : null,
              body: RefreshIndicator(
                key: _refreshState,
                onRefresh: () async {
                  await getDataForDay(_selectedDate);
                },
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Material(
                          child: IconButton(
                            icon: Icon(Icons.arrow_back,
                                color: Theme.of(context)
                                    .buttonTheme
                                    .colorScheme!
                                    .primary),
                            onPressed: dateBackward,
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: selectDate,
                            child: Text(dateToDateString(_selectedDate)),
                          ),
                        ),
                        Material(
                          child: IconButton(
                            icon: Icon(Icons.arrow_forward,
                                color: Theme.of(context)
                                    .buttonTheme
                                    .colorScheme!
                                    .primary),
                            onPressed: dateForward,
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: _entries.isNotEmpty
                          ? ListView.builder(
                              padding: const EdgeInsets.only(bottom: 72),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                return Column(
                                  children: [
                                    Dismissible(
                                      key: Key(_entries[index]
                                          .date!
                                          .toIso8601String()),
                                      background: Container(
                                        padding: const EdgeInsets.all(4),
                                        color: Colors.red,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.end,
                                          mainAxisSize: MainAxisSize.max,
                                          children: const [
                                            Icon(Icons.delete),
                                            Text("Usuń")
                                          ],
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss:
                                          (DismissDirection direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: const Text("Usuń sen"),
                                              content: Text(
                                                  'Czy na pewno chcesz usunąć sen z ${dateToDateTimeString(_entries[index].date!)}?'),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text("Anuluj"),
                                                ),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child: const Text("Usuń")),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (direction) async =>
                                          await deleteEntry(
                                              _entries[index].date!),
                                      child: Text(
                                        "${_entries[index].date!.hour == 0 && _entries[index].date!.minute == 0 ? dateToDateString(_entries[index].date!) : dateToDateTimeString(_entries[index].date!)}",
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("W łóżku"),
                                      onTap: () async {
                                        DateTime? selectedTime =
                                            await askForTime();
                                        if (selectedTime != null) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(
                                                      bedTime: selectedTime)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(
                                          _entries[index].bedTime == null
                                              ? "-"
                                              : dateToTimeString(
                                                  _entries[index].bedTime!,
                                                  excludeSeconds: true)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .bedTime)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .bedTime)
                                                                .toList(),
                                                            true);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  bedTime: DateTime.parse(
                                                                      selectedHistoricalEntry
                                                                          .value))
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("Pójście spać"),
                                      onTap: () async {
                                        DateTime? selectedTime =
                                            await askForTime();
                                        if (selectedTime != null) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(
                                                      sleepTime: selectedTime)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(
                                          _entries[index].sleepTime == null
                                              ? "-"
                                              : dateToTimeString(
                                                  _entries[index].sleepTime!,
                                                  excludeSeconds: true)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .sleepTime)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .sleepTime)
                                                                .toList(),
                                                            true);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  sleepTime: DateTime.parse(
                                                                      selectedHistoricalEntry
                                                                          .value))
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("Pierwszy budzik"),
                                      onTap: () async {
                                        DateTime? selectedTime =
                                            await askForTime();
                                        if (selectedTime != null) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(
                                                      firstAlarmTime:
                                                          selectedTime)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(_entries[index]
                                                  .firstAlarmTime ==
                                              null
                                          ? "-"
                                          : dateToTimeString(
                                              _entries[index].firstAlarmTime!,
                                              excludeSeconds: true)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .firstAlarmTime)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .firstAlarmTime)
                                                                .toList(),
                                                            true);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  firstAlarmTime:
                                                                      DateTime.parse(
                                                                          selectedHistoricalEntry
                                                                              .value))
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("Obudzenie się"),
                                      onTap: () async {
                                        DateTime? selectedTime =
                                            await askForTime();
                                        if (selectedTime != null) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(
                                                      wakeUpTime: selectedTime)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(
                                          _entries[index].wakeUpTime == null
                                              ? "-"
                                              : dateToTimeString(
                                                  _entries[index].wakeUpTime!,
                                                  excludeSeconds: true)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .wakeUpTime)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .wakeUpTime)
                                                                .toList(),
                                                            true);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  wakeUpTime: DateTime.parse(
                                                                      selectedHistoricalEntry
                                                                          .value))
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("Wstanie"),
                                      onTap: () async {
                                        DateTime? selectedTime =
                                            await askForTime();
                                        if (selectedTime != null) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(
                                                      getUpTime: selectedTime)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(
                                          _entries[index].getUpTime == null
                                              ? "-"
                                              : dateToTimeString(
                                                  _entries[index].getUpTime!,
                                                  excludeSeconds: true)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .getUpTime)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .getUpTime)
                                                                .toList(),
                                                            true);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  getUpTime: DateTime.parse(
                                                                      selectedHistoricalEntry
                                                                          .value))
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                    ListTile(
                                      title: const Text("Ocena"),
                                      onTap: () async {
                                        int rate = 0;
                                        bool? change = await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title:
                                                  const Text("Wybierz ocenę"),
                                              content: SelectNumberSlider(
                                                min: 0,
                                                max: 10,
                                                divisions: 10,
                                                init: rate,
                                                onSelect: (int val) =>
                                                    rate = val,
                                              ),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(context)
                                                          .pop(false),
                                                  child: const Text("Anuluj"),
                                                ),
                                                TextButton(
                                                    onPressed: () =>
                                                        Navigator.of(context)
                                                            .pop(true),
                                                    child:
                                                        const Text("Wybierz")),
                                              ],
                                            );
                                          },
                                        );
                                        if (change == true) {
                                          await updateEntry(
                                              _entries[index].date!,
                                              TrackingEntry(rate: rate)
                                                  .toMapWithoutDate());
                                        }
                                      },
                                      subtitle: Text(
                                        _entries[index].rate == null
                                            ? "-"
                                            : _entries[index].rate.toString(),
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.history),
                                            onPressed: _entries[index]
                                                        .versionHistory!
                                                        .where((e) =>
                                                            e.fieldName ==
                                                            TrackingFieldName
                                                                .rate)
                                                        .length >
                                                    0
                                                ? () async {
                                                    TrackingVersionHistory?
                                                        selectedHistoricalEntry =
                                                        await showVersionHistory(
                                                            _entries[index]
                                                                .versionHistory!
                                                                .where((e) =>
                                                                    e.fieldName ==
                                                                    TrackingFieldName
                                                                        .rate)
                                                                .toList(),
                                                            false);

                                                    if (selectedHistoricalEntry !=
                                                        null) {
                                                      await updateEntry(
                                                          _entries[index].date!,
                                                          TrackingEntry(
                                                                  rate: DateTime.parse(
                                                                          selectedHistoricalEntry
                                                                              .value)
                                                                      .millisecondsSinceEpoch
                                                                      .floor())
                                                              .toMapWithoutDate());
                                                    }
                                                  }
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            )
                          : Center(
                              child: Text(
                              "Nie znaleziono żadnego snu dla tej daty",
                              style: const TextStyle(fontSize: 18),
                              textAlign: TextAlign.center,
                            )),
                    ),
                  ],
                ),
              )),
        ),
        AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            left: leftIconOffset - 5,
            top: MediaQuery.of(context).size.height / 2,
            child: SizedBox(
              width: 50,
              height: 50,
              child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: leftIconOffset > 0 ? 1 : 0,
                  child: Icon(Icons.arrow_left, size: 50)),
            )),
        AnimatedPositioned(
            duration: const Duration(milliseconds: 100),
            right: rightIconOffset - 5,
            top: MediaQuery.of(context).size.height / 2,
            child: AnimatedOpacity(
                duration: const Duration(milliseconds: 100),
                opacity: rightIconOffset > 0 ? 1 : 0,
                child: Icon(Icons.arrow_right, size: 50)))
      ]);
    } else {
      return Loading();
    }
  }
}
