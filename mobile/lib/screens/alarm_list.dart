import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:flutter/material.dart';

class AlarmList extends StatefulWidget {
  final Alarm? selectedAlarm;

  const AlarmList({Key? key, this.selectedAlarm}) : super(key: key);

  @override
  _AlarmListState createState() => _AlarmListState();
}

class _AlarmListState extends State<AlarmList> {
  late List<Alarm> alarms;

  @override
  void initState() {
    super.initState();
    alarms = GlobalData.alarms;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Alarmy")),
        floatingActionButton: FloatingActionButton(
          onPressed: () => print("TODO: Add new alarm"),
          child: Icon(Icons.add),
        ),
        body: RefreshIndicator(
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                alarms = GlobalData.alarms;
              });
            },
            child: alarms.isNotEmpty
                ? ListView.builder(
                    itemCount: alarms.length,
                    itemBuilder: (BuildContext context, int index) {
                      Alarm e = alarms[index];
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: SizedBox(
                              height: 250,
                              child: AlarmCard(
                                  name: e.name,
                                  hour: e.hour,
                                  minute: e.minute,
                                  nextInvocation: e.nextInvocation,
                                  isActive: e.isActive,
                                  isSnoozeEnabled: e.isSnoozeEnabled,
                                  snoozeLength: e.snoozeLength,
                                  maxTotalSnoozeLength: e.maxTotalSnoozeLength,
                                  soundName: e.soundName,
                                  isGuardEnabled: e.isGuardEnabled,
                                  notes: e.notes)));
                    })
                : const Center(
                    child: Text("Brak alarmów!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }
}
