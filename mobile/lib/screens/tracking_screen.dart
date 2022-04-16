import 'dart:math';
import 'package:buzzine/components/select_number_slider.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/components/sortable_list_view.dart';
import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/components/tracking_stats.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/screens/tracking_stats_screen.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool isTableModeOn = false;
  List<TrackingEntry> _allEntries = [];
  List<TrackingEntry> _allEntriesFiltered = [];

  bool displayAlarmsInTable = true;
  bool displayNapsInTable = true;

  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  Future<void> getDataForDay(DateTime day) async {
    List<TrackingEntry> data = await GlobalData.getTrackingEntriesForDay(day);

    setState(() {
      _entries = data;
      _selectedDate = day.toLocal();
    });
  }

  bool checkIfTheEntryWasNotRated(TrackingEntry entry) {
    //Check if the previous one was rated and wasn't earlier than 3 days ago
    return (entry.rate?.isNaN ?? true) &&
        (entry.date?.add(const Duration(days: 3)).isAfter(DateTime.now()) ??
            true);
  }

  Future<TrackingEntry?> getThePreviousLastTrackingEntry() async {
    //Get the last 2 tracking entries
    List<TrackingEntry> _fetchedEntries =
        await GlobalData.getLastTrackingEntries(2);

    return _fetchedEntries.length >= 2 ? _fetchedEntries[1] : null;
  }

  Future<void> updateEntry(
    DateTime date,
    Map dataToUpdate,
  ) async {
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
        initialDate: _selectedDate.isAfter(DateTime.now())
            ? DateTime.now()
            : _selectedDate,
        lastDate: DateTime.now().add(const Duration(days: 1)),
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

  Future<DateTime?> askForTime({DateTime? initialDate}) async {
    DateTime? datePickerResponse = await showDatePicker(
        context: context,
        initialDate: initialDate ??
            (_selectedDate.isAfter(DateTime.now())
                ? DateTime.now()
                : _selectedDate),
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

  Future<Duration?> askForLength(int min, int max, int init) async {
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

  Future<TrackingVersionHistory?> showVersionHistory(
      List<TrackingVersionHistory> history, TrackingDataType dataType) async {
    //Sort the history by timestamp
    history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

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
                      String text = "Brak";
                      if (history[index].value != null) {
                        switch (dataType) {
                          case TrackingDataType.timestamp:
                            text = dateToDateTimeString(
                                DateTime.parse(history[index].value));
                            break;
                          case TrackingDataType.number:
                            text = history[index].value.toString();
                            break;
                          case TrackingDataType.duration:
                            text =
                                secondsTommss(int.parse(history[index].value));
                            break;
                          case TrackingDataType.text:
                            text = history[index].value.toString();
                            break;
                        }
                      }

                      return ListTile(
                          title: Text(text),
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

  Future<void> addEntry() async {
    DateTime? date = await askForTime();

    if (date != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa tworzenie snu...");
        },
      );
      await updateEntry(date, {});
      Navigator.of(context).pop();
    }
  }

  Future<void> navigateToStatsScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingStatsScreen(),
    ));
  }

  Future<void> displayUnratedWarningDialog(DateTime previousEntryDate) async {
    bool? goToEntry = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Ostrzeżenie"),
          content: const Text(
              "Poprzedni sen nie został oceniony. Czy chcesz go ocenić teraz?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Przejdź"),
            ),
          ],
        );
      },
    );

    if (goToEntry == true) {
      getDataForDay(previousEntryDate);
    }
  }

  Future<void> toggleViewingMode() async {
    List<TrackingEntry> entries = await GlobalData.getAllTrackingEntries();

    entries.sort((a, b) => b.date!.compareTo(a.date!));

    setState(() {
      isTableModeOn = !isTableModeOn;
      _allEntries = entries;
      _allEntriesFiltered =
          filterAllEntries(entries, displayAlarmsInTable, displayNapsInTable);
    });
  }

  void changeTableFilteringSettings(bool displayAlarms, bool displayNaps) {
    setState(() {
      displayAlarmsInTable = displayAlarms;
      displayNapsInTable = displayNaps;
      _allEntriesFiltered =
          filterAllEntries(_allEntries, displayAlarms, displayNaps);
    });
  }

  List<TrackingEntry> filterAllEntries(
      List<TrackingEntry> allEntries, bool alarms, bool naps) {
    List<TrackingEntry> filteredEntries = [];

    allEntries.forEach((element) {
      if ((element.isNap ?? false) && naps) {
        filteredEntries.add(element);
      } else if (!(element.isNap ?? false) && alarms) {
        filteredEntries.add(element);
      }
    });

    return filteredEntries;
  }

  Future<void> copyCSVToClipboard(TrackingEntry entry) async {
    Map<String, String> csvData = {
      "Data": dateToDateString(entry.date!),
      "W łóżku": entry.bedTime != null ? dateToTimeString(entry.bedTime!) : "-",
      "Pójście spać":
          entry.sleepTime != null ? dateToTimeString(entry.sleepTime!) : "-",
      "Pierwszy budzik": entry.firstAlarmTime != null
          ? dateToTimeString(entry.firstAlarmTime!)
          : "-",
      "Obudzenie się":
          entry.wakeUpTime != null ? dateToTimeString(entry.wakeUpTime!) : "-",
      "Wstanie":
          entry.getUpTime != null ? dateToTimeString(entry.getUpTime!) : "-",
      "Początek alarmów": entry.alarmTimeFrom != null
          ? dateToTimeString(entry.alarmTimeFrom!)
          : "-",
      "Koniec alarmów": entry.alarmTimeTo != null
          ? dateToTimeString(entry.alarmTimeTo!)
          : "-",
      "Ocena": entry.rate != null ? entry.rate!.toString() : "-",
      "Czas na wyłączenie alarmów": entry.timeTakenToTurnOffTheAlarm != null
          ? secondsTommss(entry.timeTakenToTurnOffTheAlarm)
          : "-",
      "Notka": entry.notes?.toString() ?? ""
    };

    List<String>? result = await showDialog(
      context: context,
      builder: (context) {
        return SortableListView(
            items: csvData.keys.toList(), title: "Wybierz właściwości");
      },
    );

    if (result == null || result.length < 1) {
      return;
    }

    List<String> data = [];
    result.forEach((element) {
      data.add(csvData[element.toString()]!);
    });

    String exportedCSV = data.join(",");
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(result.join(",")),
              content: Text(exportedCSV),
              actions: [
                TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: result.join(",")));
                      showSnackbar(context, "Skopiowano do schowka");
                    },
                    child: const Text("Kopiuj nagłówek")),
                TextButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: exportedCSV));
                      showSnackbar(context, "Skopiowano do schowka");
                    },
                    child: const Text("Kopiuj")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));

    // await Clipboard.setData(ClipboardData(text: exportedCSV));
  }

  void showCSVCopyInfo() {
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Eksportowanie wierszu CSV"),
              content: Text(
                  "Funkcja eksportowania wiersza do formatu CSV, oddzielanego przecinkami, umożliwia łatwe impotowanie danych do arkusza kalkulacyjnego. Wystarczy wtedy użyć opcji Data -> Text to Columns (Excel) lub funkcji SPLIT (Google Sheets)."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
  }

  Future<void> refresh() async {
    await _refreshState.currentState?.show();
  }

  @override
  void initState() {
    getDataForDay(widget.initDate).then((value) {
      getThePreviousLastTrackingEntry().then((TrackingEntry? previousEntry) {
        if (previousEntry != null &&
            checkIfTheEntryWasNotRated(previousEntry)) {
          displayUnratedWarningDialog(previousEntry.date!);
        }
        setState(() => _isLoaded = true);
      });
    });

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
                actions: [
                  IconButton(
                    icon: Icon(isTableModeOn ? Icons.toc : Icons.table_chart),
                    onPressed: () => toggleViewingMode(),
                  )
                ],
              ),
              floatingActionButton: FloatingActionButton(
                  child: const Icon(Icons.add), onPressed: addEntry),
              body: RefreshIndicator(
                key: _refreshState,
                onRefresh: () async {
                  await getDataForDay(_selectedDate);
                },
                child: Column(
                  children: [
                    if (!isTableModeOn)
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
                              onLongPress: () => getDataForDay(DateTime.now()),
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
                    if (!isTableModeOn)
                      Expanded(
                        child: _entries.isNotEmpty
                            ? ListView.builder(
                                padding: const EdgeInsets.only(bottom: 72),
                                itemCount: _entries.length,
                                itemBuilder: (context, index) {
                                  TrackingStatsService _stats =
                                      TrackingStatsService.of(_entries[index],
                                          GlobalData.trackingStats);
                                  return Column(
                                    children: [
                                      InkWell(
                                        onLongPress: () async {
                                          bool? confirmDelete =
                                              await showDialog(
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
                                                      child:
                                                          const Text("Usuń")),
                                                ],
                                              );
                                            },
                                          );

                                          if (confirmDelete == true) {
                                            await deleteEntry(
                                                _entries[index].date!);
                                          }
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            "${_entries[index].date!.hour == 0 && _entries[index].date!.minute == 0 ? dateToDateString(_entries[index].date!) : dateToDateTimeString(_entries[index].date!)}",
                                            style:
                                                const TextStyle(fontSize: 24),
                                          ),
                                        ),
                                      ),
                                      ListTile(
                                        title: const Text("W łóżku"),
                                        onTap: () async {
                                          DateTime? selectedTime =
                                              await askForTime();
                                          if (selectedTime != null) {
                                            if (selectedTime.compareTo(
                                                    _entries[index].sleepTime ??
                                                        selectedTime) <=
                                                0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          bedTime: selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas w łóżku musi być wcześniejszy lub równy czasowi pójścia spać'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
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
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
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
                                            if (selectedTime.compareTo(
                                                        _entries[index]
                                                                .bedTime ??
                                                            selectedTime) >=
                                                    0 &&
                                                selectedTime.compareTo(
                                                        _entries[index]
                                                                .wakeUpTime ??
                                                            selectedTime) <=
                                                    0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          sleepTime:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas pójścia spać musi być wcześniejszy od czasu obudzenia oraz późniejszy niż czas w łóżku'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
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
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
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
                                              await askForTime(
                                                  initialDate: DateTime(
                                                      _selectedDate.year,
                                                      _selectedDate.month,
                                                      _selectedDate.day,
                                                      DateTime.now().hour,
                                                      DateTime.now().minute));

                                          if (selectedTime != null) {
                                            if (selectedTime.compareTo(
                                                        _entries[index]
                                                                .wakeUpTime ??
                                                            selectedTime) <=
                                                    0 &&
                                                selectedTime.compareTo(
                                                        _entries[index]
                                                                .sleepTime ??
                                                            selectedTime) >=
                                                    0 &&
                                                selectedTime.compareTo(_entries[
                                                                index]
                                                            .firstAlarmTime ??
                                                        selectedTime) >=
                                                    0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          firstAlarmTime:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas pierwszego alarmu musi być wcześniejszy lub równy czasowi obudzenia się oraz późniejszy od czasu pójścia spać i pierwszego budzika'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
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
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    firstAlarmTime:
                                                                        DateTime.parse(
                                                                            selectedHistoricalEntry.value))
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
                                            if (selectedTime.compareTo(
                                                        _entries[index]
                                                                .getUpTime ??
                                                            selectedTime) <=
                                                    0 &&
                                                selectedTime.compareTo(
                                                        _entries[index]
                                                                .sleepTime ??
                                                            selectedTime) >=
                                                    0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          wakeUpTime:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas obudzenia się musi być wcześniejszy od wstania oraz późniejszy od czasu pójścia spać'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
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
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    wakeUpTime:
                                                                        DateTime.parse(
                                                                            selectedHistoricalEntry.value))
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
                                            if (selectedTime.compareTo(
                                                    _entries[index]
                                                            .wakeUpTime ??
                                                        selectedTime) >=
                                                0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          getUpTime:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas wstania musi być późniejszy lub równy obudzeniu się'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
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
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
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
                                        title: const Text("Początek alarmów"),
                                        onTap: () async {
                                          DateTime? selectedTime =
                                              await askForTime(
                                                  initialDate: DateTime(
                                                      _selectedDate.year,
                                                      _selectedDate.month,
                                                      _selectedDate.day,
                                                      DateTime.now().hour,
                                                      DateTime.now().minute));

                                          if (selectedTime != null) {
                                            if (selectedTime.compareTo(
                                                    _entries[index]
                                                            .alarmTimeTo ??
                                                        selectedTime) <=
                                                0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          alarmTimeFrom:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas początku alarmów musi być wcześniejszy niż czas końca alarmów'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        },
                                        subtitle: Text(_entries[index]
                                                    .alarmTimeFrom ==
                                                null
                                            ? "-"
                                            : dateToTimeString(
                                                _entries[index].alarmTimeFrom!,
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
                                                                  .alarmTimeFrom)
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
                                                                          .alarmTimeFrom)
                                                                  .toList(),
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    alarmTimeFrom:
                                                                        DateTime.parse(
                                                                            selectedHistoricalEntry.value))
                                                                .toMapWithoutDate());
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                        title: const Text("Koniec alarmów"),
                                        onTap: () async {
                                          DateTime? selectedTime =
                                              await askForTime(
                                                  initialDate: DateTime(
                                                      _selectedDate.year,
                                                      _selectedDate.month,
                                                      _selectedDate.day,
                                                      DateTime.now().hour,
                                                      DateTime.now().minute));

                                          if (selectedTime != null) {
                                            if (selectedTime.compareTo(
                                                    _entries[index]
                                                            .alarmTimeFrom ??
                                                        selectedTime) >=
                                                0) {
                                              await updateEntry(
                                                  _entries[index].date!,
                                                  TrackingEntry(
                                                          alarmTimeTo:
                                                              selectedTime)
                                                      .toMapWithoutDate());
                                            } else {
                                              await showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Błąd"),
                                                    content: Text(
                                                        'Czas końca alarmów musi być późniejszy lub równy czasu początku alarmów'),
                                                    actions: <Widget>[
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                          child:
                                                              const Text("OK")),
                                                    ],
                                                  );
                                                },
                                              );
                                            }
                                          }
                                        },
                                        subtitle: Text(_entries[index]
                                                    .alarmTimeTo ==
                                                null
                                            ? "-"
                                            : dateToTimeString(
                                                _entries[index].alarmTimeTo!,
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
                                                                  .alarmTimeTo)
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
                                                                          .alarmTimeTo)
                                                                  .toList(),
                                                              TrackingDataType
                                                                  .timestamp);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    alarmTimeTo:
                                                                        DateTime.parse(
                                                                            selectedHistoricalEntry.value))
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
                                          int rate = _entries[index].rate ?? 1;
                                          bool? change = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title:
                                                    const Text("Wybierz ocenę"),
                                                content: SelectNumberSlider(
                                                  min: 1,
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
                                                      child: const Text(
                                                          "Wybierz")),
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
                                                              TrackingDataType
                                                                  .number);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    rate: int.tryParse(
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
                                        title: const Text(
                                            "Czas na wyłączanie alarmów"),
                                        onTap: () async {
                                          int timeTakenToTurnOffTheAlarm =
                                              _entries[index]
                                                      .timeTakenToTurnOffTheAlarm ??
                                                  0;
                                          Duration? selectedDuration =
                                              await askForLength(0, 9999999,
                                                  timeTakenToTurnOffTheAlarm); //TODO: Don't do 9999999
                                          if (selectedDuration != null) {
                                            await updateEntry(
                                                _entries[index].date!,
                                                TrackingEntry(
                                                        timeTakenToTurnOffTheAlarm:
                                                            selectedDuration
                                                                .inSeconds)
                                                    .toMapWithoutDate());
                                          }
                                        },
                                        subtitle: Text(
                                          _entries[index]
                                                      .timeTakenToTurnOffTheAlarm ==
                                                  null
                                              ? "-"
                                              : secondsTommss(_entries[index]
                                                  .timeTakenToTurnOffTheAlarm),
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
                                                                  .timeTakenToTurnOffTheAlarm)
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
                                                                          .timeTakenToTurnOffTheAlarm)
                                                                  .toList(),
                                                              TrackingDataType
                                                                  .duration);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    timeTakenToTurnOffTheAlarm:
                                                                        int.tryParse(
                                                                            selectedHistoricalEntry.value))
                                                                .toMapWithoutDate());
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      ListTile(
                                        title: const Text("Notka"),
                                        onTap: () async {
                                          TextEditingController
                                              _notesController =
                                              TextEditingController();
                                          _notesController.text =
                                              _entries[index].notes == null ||
                                                      _entries[index].notes ==
                                                          " "
                                                  ? ""
                                                  : _entries[index].notes!;
                                          bool? change = await showDialog(
                                            context: context,
                                            barrierDismissible: false,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text("Notka"),
                                                content: TextField(
                                                  controller: _notesController,
                                                  textCapitalization:
                                                      TextCapitalization
                                                          .sentences,
                                                  decoration: InputDecoration(
                                                      hintText: "Wpisz uwagi",
                                                      suffix: IconButton(
                                                        icon: const Icon(
                                                            Icons.clear),
                                                        onPressed: () =>
                                                            _notesController
                                                                .text = "",
                                                      )),
                                                  maxLines: null,
                                                  keyboardType:
                                                      TextInputType.multiline,
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
                                                          const Text("Zapisz")),
                                                ],
                                              );
                                            },
                                          );
                                          if (change == true) {
                                            await updateEntry(
                                                _entries[index].date!,
                                                TrackingEntry(
                                                        notes: _notesController
                                                                .text.isEmpty
                                                            ? " "
                                                            : _notesController
                                                                .text)
                                                    .toMapWithoutDate());
                                          }
                                        },
                                        subtitle: Text(
                                          _entries[index].notes == null ||
                                                  _entries[index].notes == " "
                                              ? "Brak"
                                              : _entries[index].notes!,
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
                                                                  .notes)
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
                                                                          .notes)
                                                                  .toList(),
                                                              TrackingDataType
                                                                  .text);

                                                      if (selectedHistoricalEntry !=
                                                          null) {
                                                        await updateEntry(
                                                            _entries[index]
                                                                .date!
                                                                .toLocal(),
                                                            TrackingEntry(
                                                                    notes: selectedHistoricalEntry
                                                                        .value)
                                                                .toMapWithoutDate());
                                                      }
                                                    }
                                                  : null,
                                            ),
                                          ],
                                        ),
                                      ),
                                      InkWell(
                                          onTap: navigateToStatsScreen,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: TrackingStatsWidget(
                                                  stats: _stats))),
                                      TextButton(
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.copy),
                                            Text(
                                                "Eksportuj wiersz CSV (Excel, Google Sheets)"),
                                          ],
                                        ),
                                        onPressed: () =>
                                            copyCSVToClipboard(_entries[index]),
                                        onLongPress: showCSVCopyInfo,
                                      )
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
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          InkWell(
                            onTap: () => changeTableFilteringSettings(
                                !displayAlarmsInTable, displayNapsInTable),
                            child: Row(
                              children: [
                                Checkbox(
                                    value: displayAlarmsInTable,
                                    onChanged: (value) =>
                                        changeTableFilteringSettings(
                                            value ?? true, displayNapsInTable)),
                                Text("Alarmy"),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => changeTableFilteringSettings(
                                displayAlarmsInTable, !displayNapsInTable),
                            child: Row(
                              children: [
                                Checkbox(
                                    value: displayNapsInTable,
                                    onChanged: (value) =>
                                        changeTableFilteringSettings(
                                            displayAlarmsInTable,
                                            value ?? true)),
                                Text("Drzemki"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    if (isTableModeOn)
                      Expanded(
                          child: _allEntriesFiltered.isNotEmpty
                              ? ListView(
                                  children: [
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                          columns: [
                                            DataColumn(
                                                label: const Text("Data")),
                                            DataColumn(
                                                label: const Text("W łóżku")),
                                            DataColumn(
                                                label:
                                                    const Text("Pójście spać")),
                                            DataColumn(
                                                label: const Text(
                                                    "Pierwszy budzik")),
                                            DataColumn(
                                                label: const Text(
                                                    "Obudzenie się")),
                                            DataColumn(
                                                label: const Text("Wstanie")),
                                            DataColumn(
                                                label: const Text(
                                                    "Początek alarmów")),
                                            DataColumn(
                                                label: const Text(
                                                    "Koniec alarmów")),
                                            DataColumn(
                                                label: const Text("Ocena")),
                                            DataColumn(
                                                label: const Text(
                                                    "Czas na wyłączenie alarmów")),
                                            DataColumn(
                                                label: const Text("Notka")),
                                          ],
                                          rows: _allEntriesFiltered.map((e) {
                                            return DataRow(
                                                onLongPress: () async {
                                                  await getDataForDay(e.date!);
                                                },
                                                selected: _selectedDate.day ==
                                                        e.date!.day &&
                                                    _selectedDate.month ==
                                                        e.date!.month &&
                                                    _selectedDate.year ==
                                                        e.date!.year,
                                                cells: [
                                                  DataCell(Text(
                                                    "${e.date!.hour == 0 && e.date!.minute == 0 ? dateToDateString(e.date!) : dateToDateTimeString(e.date!)}",
                                                  )),
                                                  DataCell(Text(
                                                    e.bedTime == null
                                                        ? "W łóżku\n-"
                                                        : "W łóżku\n" +
                                                            dateToTimeString(
                                                                e.bedTime!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.sleepTime == null
                                                        ? "Pójście spać\n-"
                                                        : "Pójście spać\n" +
                                                            dateToTimeString(
                                                                e.sleepTime!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.firstAlarmTime == null
                                                        ? "Pierwszy budzik\n-"
                                                        : "Pierwszy budzik\n" +
                                                            dateToTimeString(
                                                                e
                                                                    .firstAlarmTime!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.wakeUpTime == null
                                                        ? "Obudzenie się\n-"
                                                        : "Obudzenie się\n" +
                                                            dateToTimeString(
                                                                e.wakeUpTime!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.getUpTime == null
                                                        ? "Wstanie\n-"
                                                        : "Wstanie\n" +
                                                            dateToTimeString(
                                                                e.getUpTime!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.alarmTimeFrom == null
                                                        ? "Początek alarmów\n-"
                                                        : "Początek alarmów\n" +
                                                            dateToTimeString(
                                                                e
                                                                    .alarmTimeFrom!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.alarmTimeTo == null
                                                        ? "Koniec alarmów\n-"
                                                        : "Koniec alarmów\n" +
                                                            dateToTimeString(
                                                                e.alarmTimeTo!,
                                                                excludeSeconds:
                                                                    true),
                                                  )),
                                                  DataCell(Text(
                                                    e.rate == null
                                                        ? "Ocena\n-"
                                                        : "Ocena\n" +
                                                            e.rate.toString(),
                                                  )),
                                                  DataCell(Text(
                                                    e.timeTakenToTurnOffTheAlarm ==
                                                            null
                                                        ? "Czas na wyłączenie alarmów\n-"
                                                        : "Czas na wyłączenie alarmów\n" +
                                                            secondsTommss(e
                                                                .timeTakenToTurnOffTheAlarm),
                                                  )),
                                                  DataCell(Text(
                                                    e.notes == null
                                                        ? "Notka\n-"
                                                        : "Notka\n" +
                                                            e.notes.toString(),
                                                  )),
                                                ]);
                                          }).toList()),
                                    )
                                  ],
                                )
                              : Center(
                                  child: Text(
                                  "Nie znaleziono żadnego snu dla tej daty",
                                  style: const TextStyle(fontSize: 18),
                                  textAlign: TextAlign.center,
                                ))),
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
