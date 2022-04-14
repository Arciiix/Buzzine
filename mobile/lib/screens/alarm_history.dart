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
                  ? Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 72),
                        itemCount: _alarms.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(dateToDateTimeString(
                                _alarms[index].invocationDate)),
                            trailing: _alarms[index].id.contains("NAP/")
                                ? Icon(Icons.snooze)
                                : Icon(Icons.alarm),
                            subtitle: Text(
                                (_alarms[index].name ?? "Bez nazwy") +
                                    "\n" +
                                    (_alarms[index].notes ?? "")),
                            isThreeLine: true,
                          );
                        },
                      ),
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
