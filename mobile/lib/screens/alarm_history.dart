import 'dart:math';

import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/AlarmType.dart';
import 'package:buzzine/types/HistoricalAlarm.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class AlarmHistoryScreen extends StatefulWidget {
  const AlarmHistoryScreen({Key? key}) : super(key: key);

  @override
  State<AlarmHistoryScreen> createState() => _AlarmHistoryScreenState();
}

class _AlarmHistoryScreenState extends State<AlarmHistoryScreen> {
  bool _isLoaded = false;
  late List<HistoricalAlarm> _alarms;
  late DateTime _selectedDate;

  DateTime _lastEntryDate =
      DateTime.fromMillisecondsSinceEpoch(0); //Used to build the ListView

  double leftIconOffset = 0;
  double rightIconOffset = 0;

  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  Future<List<HistoricalAlarm>> getAlarmHistory() async {
    List<HistoricalAlarm> alarmHistory = await GlobalData.getAlarmHistory();
    setState(() {
      _alarms = alarmHistory;
      _isLoaded = true;
    });
    return alarmHistory;
  }

  @override
  void initState() {
    getAlarmHistory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return Scaffold(
          appBar: AppBar(
            title: Text("Historia alarmów"),
          ),
          body: RefreshIndicator(
              key: _refreshState,
              onRefresh: () async {
                await getAlarmHistory();
              },
              child: _alarms.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.only(bottom: 72),
                      itemCount: _alarms.length,
                      itemBuilder: (context, index) {
                        List<Widget> widgetsToRender = [];
                        if (_alarms[index].invocationDate.month !=
                                _lastEntryDate.month ||
                            _alarms[index].invocationDate.year !=
                                _lastEntryDate.year) {
                          widgetsToRender.add(Text(
                            dateToDateString(_alarms[index].invocationDate)
                                .substring(3),
                            style: const TextStyle(fontSize: 32),
                          ));
                        }
                        if (_alarms[index].invocationDate.day !=
                                _lastEntryDate.day ||
                            _alarms[index].invocationDate.month !=
                                _lastEntryDate.month ||
                            _alarms[index].invocationDate.year !=
                                _lastEntryDate.year) {
                          widgetsToRender.add(Text(
                            dateToDateString(_alarms[index].invocationDate),
                            style: const TextStyle(fontSize: 24),
                          ));
                        }

                        widgetsToRender.add(ListTile(
                          title: Text(dateToDateTimeString(
                              _alarms[index].invocationDate)),
                          trailing: _alarms[index].id.contains("NAP/")
                              ? Icon(Icons.snooze)
                              : Icon(Icons.alarm),
                          subtitle: Text((_alarms[index].name ?? "Bez nazwy") +
                              "\n" +
                              (_alarms[index].notes != null
                                  ? _alarms[index].notes!.toString() + "\n"
                                  : "") +
                              "[ID: ${_alarms[index].id}]"),
                          isThreeLine: true,
                        ));

                        _lastEntryDate = _alarms[index].invocationDate;

                        return Column(children: widgetsToRender);
                      },
                    )
                  : Center(
                      child: Text(
                      "Nie znaleziono żadnego alarmu dla tej daty",
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ))));
    } else {
      return Loading();
    }
  }
}
