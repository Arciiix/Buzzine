import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/carousel.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoaded = false;
  late List<Alarm> upcomingAlarms;

  void handleAlarmSelect(int? alarmIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => AlarmList(
              selectedAlarm:
                  alarmIndex != null ? upcomingAlarms[alarmIndex] : null)),
    );
  }

  @override
  void initState() {
    super.initState();

    GlobalData.getData().then((value) => {
          setState(() {
            _isLoaded = true;
            upcomingAlarms = GlobalData.upcomingAlarms;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Loading(showText: true);
    } else {
      return Scaffold(
          body: Padding(
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                  child: RefreshIndicator(
                      onRefresh: () async {
                        await GlobalData.getData();
                        setState(() {
                          upcomingAlarms = GlobalData.upcomingAlarms;
                        });
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("Buzzine",
                                    style: TextStyle(
                                        fontSize: 48, color: Colors.white))),
                            Padding(
                                padding: EdgeInsets.all(5),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text("⏰ Nadchodzące alarmy",
                                          style: TextStyle(
                                              fontSize: 24,
                                              color: Colors.white)),
                                      IconButton(
                                        icon: const Icon(Icons.refresh,
                                            color: Colors.white),
                                        onPressed: () => print(
                                            "TODO: Refresh the upcoming alarms"),
                                      )
                                    ])),
                            Carousel(
                                height: 250,
                                onSelect: handleAlarmSelect,
                                children: upcomingAlarms.map((e) {
                                  return AlarmCard(
                                      id: e.id ??
                                          "", //TODO: Make it in a better way
                                      name: e.name,
                                      hour: e.hour,
                                      minute: e.minute,
                                      nextInvocation: e.nextInvocation,
                                      isActive: e.isActive,
                                      isSnoozeEnabled: e.isSnoozeEnabled,
                                      maxTotalSnoozeLength:
                                          e.maxTotalSnoozeLength,
                                      sound: e.sound,
                                      isGuardEnabled: e.isGuardEnabled,
                                      notes: e.notes);
                                }).toList())
                          ],
                        ),
                      )))));
    }
  }
}
