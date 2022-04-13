import 'package:buzzine/components/tracking_stats.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/tracking_screen.dart';
import 'package:buzzine/screens/tracking_stats_screen.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class TrackingEntryWidget extends StatefulWidget {
  const TrackingEntryWidget({Key? key}) : super(key: key);

  @override
  TrackingEntryWidgetState createState() => TrackingEntryWidgetState();
}

class TrackingEntryWidgetState extends State<TrackingEntryWidget> {
  bool _isLoaded = false;
  late TrackingEntry _currentEntry;
  late TrackingStatsService _stats;

  Future<void> getLatestEntry() async {
    TrackingEntry latestEntry = await GlobalData.getLatestTrackingEntry();
    setState(() {
      _currentEntry = latestEntry;
      _stats = TrackingStatsService.of(latestEntry, GlobalData.trackingStats);
    });
  }

  Future<void> navigateToTrackingScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingScreen(
        initDate: _currentEntry.date!,
      ),
    ));

    setState(() {
      _isLoaded = false;
    });
    await getLatestEntry();
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> navigateToStatsScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingStatsScreen(),
    ));

    setState(() => _isLoaded = false);
    await getLatestEntry();
    TrackingStats stats = await GlobalData.getTrackingStats();
    setState(() {
      _isLoaded = true;
      _stats:
      stats;
    });
  }

  Future<void> refresh() async {
    setState(() {
      _isLoaded = false;
    });
    await getLatestEntry();
    setState(() {
      _isLoaded = true;
      _stats = TrackingStatsService.of(_currentEntry, GlobalData.trackingStats);
    });
  }

  @override
  void initState() {
    getLatestEntry().then((value) => setState(() {
          _isLoaded = true;
          _stats =
              TrackingStatsService.of(_currentEntry, GlobalData.trackingStats);
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: navigateToTrackingScreen,
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(5),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.bed, size: 24),
                                ),
                                Text("W łóżku",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.bedTime == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.bedTime!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.bedtime, size: 24),
                                ),
                                Text("Pójście spać",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.sleepTime == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.sleepTime!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.alarm, size: 24),
                                ),
                                Text("Pierwszy budzik",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.firstAlarmTime == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.firstAlarmTime!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.timer, size: 24),
                                ),
                                Text("Obudzenie się",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.wakeUpTime == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.wakeUpTime!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.stop, size: 24),
                                ),
                                Text("Wstanie",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.getUpTime == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.getUpTime!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.star, size: 24),
                                ),
                                Text("Ocena",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                if (_currentEntry.rate == null)
                                  const Text("-",
                                      style: TextStyle(fontSize: 24))
                                else
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: SizedBox(
                                            width: 100,
                                            child: LinearProgressIndicator(
                                                value:
                                                    _currentEntry.rate! / 10)),
                                      ),
                                      Text(_currentEntry.rate!.toString())
                                    ],
                                  ),
                              ],
                            ),
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.first_page, size: 24),
                                ),
                                Text("Początek alarmów",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.alarmTimeFrom == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.alarmTimeFrom!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ),
                          SizedBox(
                            width:
                                MediaQuery.of(context).size.width * 0.9 * 0.4,
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(Icons.last_page, size: 24),
                                ),
                                Text("Koniec alarmów",
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.center),
                                Text(
                                    _currentEntry.alarmTimeTo == null
                                        ? "-"
                                        : dateToTimeString(
                                            _currentEntry.alarmTimeTo!,
                                            excludeSeconds: true),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(Icons.timer, size: 24),
                              ),
                              Text("Czas na wyłączanie alarmów",
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center),
                              Text("mm:ss",
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                  _currentEntry.timeTakenToTurnOffTheAlarm ==
                                          null
                                      ? "-"
                                      : secondsTommss(_currentEntry
                                          .timeTakenToTurnOffTheAlarm),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.subject),
                            const Text("Notka",
                                style: TextStyle(fontSize: 16),
                                textAlign: TextAlign.center),
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _currentEntry.notes == null ||
                                        _currentEntry.notes == " "
                                    ? [
                                        const Text("-",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 24)),
                                      ]
                                    : [
                                        Flexible(
                                            child: Text(
                                          _currentEntry.notes!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ))
                                      ]),
                          ],
                        ),
                      ),
                      InkWell(
                          onTap: navigateToStatsScreen,
                          child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TrackingStatsWidget(stats: _stats))),
                      Text(_currentEntry.date!.hour == 0 &&
                              _currentEntry.date!.minute == 0
                          ? dateToDateString(_currentEntry.date!)
                          : dateToDateTimeString(_currentEntry.date!))
                    ],
                  ),
                )),
          ));
    } else {
      return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            child: Column(
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                Text("Ładowanie...", style: TextStyle(fontSize: 24))
              ],
            ),
          ));
    }
  }
}
