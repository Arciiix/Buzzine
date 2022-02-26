import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/tracking_screen.dart';
import 'package:buzzine/screens/tracking_stats_screen.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/get_icon_by_offset.dart';
import 'package:flutter/material.dart';

class TrackingEntryWidget extends StatefulWidget {
  const TrackingEntryWidget({Key? key}) : super(key: key);

  @override
  _TrackingEntryWidgetState createState() => _TrackingEntryWidgetState();
}

class _TrackingEntryWidgetState extends State<TrackingEntryWidget> {
  bool _isLoaded = false;
  late TrackingEntry _currentEntry;
  late TrackingStats _stats;

  Future<void> getLatestEntry() async {
    TrackingEntry latestEntry = await GlobalData.getLatestTrackingEntry();
    setState(() {
      _currentEntry = latestEntry;
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

  @override
  void initState() {
    getLatestEntry().then((value) => setState(() => _isLoaded = true));
    _stats = GlobalData.trackingStats;
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.bed, size: 16),
                                    ),
                                    Text("W łóżku",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.bedtime, size: 16),
                                    ),
                                    Text("Pójście spać",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.alarm, size: 16),
                                    ),
                                    Text("Pierwszy budzik",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.timer, size: 16),
                                    ),
                                    Text("Obudzenie się",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.stop, size: 16),
                                    ),
                                    Text("Wstanie",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Padding(
                                      padding: EdgeInsets.all(2),
                                      child: Icon(Icons.star, size: 16),
                                    ),
                                    Text("Ocena",
                                        style: TextStyle(fontSize: 16))
                                  ],
                                ),
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
                      SizedBox(
                        height: 100,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.subject),
                                const Text("Notka",
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
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
                          child: Hero(
                            tag: "TRACKING_STATS",
                            child: Material(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9 *
                                                0.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(Icons.local_hotel,
                                                  size: 24),
                                            ),
                                            Text("Długość snu",
                                                style: TextStyle(fontSize: 16)),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: _currentEntry
                                                                .sleepTime ==
                                                            null ||
                                                        _currentEntry
                                                                .wakeUpTime ==
                                                            null
                                                    ? [
                                                        Text("-",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24))
                                                      ]
                                                    : [
                                                        Text(
                                                            durationToHHmm(
                                                              _currentEntry
                                                                  .wakeUpTime!
                                                                  .difference(
                                                                      _currentEntry
                                                                          .sleepTime!),
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24)),
                                                        Icon(
                                                            getIconByOffset(((_currentEntry
                                                                        .wakeUpTime!
                                                                        .difference(_currentEntry
                                                                            .sleepTime!)
                                                                        .inSeconds -
                                                                    _stats
                                                                        .monthly
                                                                        .averageSleepDuration) /
                                                                _stats.monthly
                                                                    .averageSleepDuration)),
                                                            size: 14),
                                                        Text((((_currentEntry.wakeUpTime!.difference(_currentEntry.sleepTime!).inSeconds -
                                                                            GlobalData
                                                                                .trackingStats.monthly.averageSleepDuration) /
                                                                        GlobalData
                                                                            .trackingStats
                                                                            .monthly
                                                                            .averageSleepDuration) *
                                                                    100)
                                                                .floor()
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "%")
                                                      ]),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9 *
                                                0.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(Icons.king_bed,
                                                  size: 24),
                                            ),
                                            Text("Czas w łóżku",
                                                style: TextStyle(fontSize: 16)),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: _currentEntry
                                                                .bedTime ==
                                                            null ||
                                                        _currentEntry
                                                                .sleepTime ==
                                                            null
                                                    ? [
                                                        Text("-",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24))
                                                      ]
                                                    : [
                                                        Text(
                                                            durationToHHmm(
                                                              _currentEntry
                                                                  .sleepTime!
                                                                  .difference(
                                                                      _currentEntry
                                                                          .bedTime!),
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24)),
                                                        Icon(
                                                            getIconByOffset(((_currentEntry
                                                                        .sleepTime!
                                                                        .difference(_currentEntry
                                                                            .bedTime!)
                                                                        .inSeconds -
                                                                    _stats
                                                                        .monthly
                                                                        .averageTimeAtBed) /
                                                                _stats.monthly
                                                                    .averageTimeAtBed)),
                                                            size: 14),
                                                        Text((((_currentEntry.sleepTime!.difference(_currentEntry.bedTime!).inSeconds -
                                                                            GlobalData
                                                                                .trackingStats.monthly.averageTimeAtBed) /
                                                                        GlobalData
                                                                            .trackingStats
                                                                            .monthly
                                                                            .averageTimeAtBed) *
                                                                    100)
                                                                .floor()
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "%")
                                                      ]),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9 *
                                                0.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(Icons.skip_next,
                                                  size: 24),
                                            ),
                                            Text(
                                              "Przekładanie\nalarmów",
                                              style: TextStyle(fontSize: 16),
                                              textAlign: TextAlign.center,
                                            ),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: _currentEntry
                                                                .firstAlarmTime ==
                                                            null ||
                                                        _currentEntry
                                                                .wakeUpTime ==
                                                            null
                                                    ? [
                                                        Text("-",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24))
                                                      ]
                                                    : [
                                                        Text(
                                                            durationToHHmm(
                                                              _currentEntry
                                                                  .wakeUpTime!
                                                                  .difference(
                                                                      _currentEntry
                                                                          .firstAlarmTime!),
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24)),
                                                        Icon(
                                                            getIconByOffset(((_currentEntry
                                                                        .wakeUpTime!
                                                                        .difference(_currentEntry
                                                                            .firstAlarmTime!)
                                                                        .inSeconds -
                                                                    _stats
                                                                        .monthly
                                                                        .averageAlarmWakeUpProcrastinationTime) /
                                                                _stats.monthly
                                                                    .averageAlarmWakeUpProcrastinationTime)),
                                                            size: 14),
                                                        Text((((_currentEntry.wakeUpTime!.difference(_currentEntry.firstAlarmTime!).inSeconds -
                                                                            GlobalData
                                                                                .trackingStats.monthly.averageAlarmWakeUpProcrastinationTime) /
                                                                        GlobalData
                                                                            .trackingStats
                                                                            .monthly
                                                                            .averageAlarmWakeUpProcrastinationTime) *
                                                                    100)
                                                                .floor()
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "%")
                                                      ]),
                                          ],
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.9 *
                                                0.4,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(Icons.smartphone,
                                                  size: 24),
                                            ),
                                            Text(
                                              "Czas po\nobudzeniu się",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: _currentEntry
                                                                .wakeUpTime ==
                                                            null ||
                                                        _currentEntry
                                                                .getUpTime ==
                                                            null
                                                    ? [
                                                        Text("-",
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24))
                                                      ]
                                                    : [
                                                        Text(
                                                            durationToHHmm(
                                                              _currentEntry
                                                                  .getUpTime!
                                                                  .difference(
                                                                      _currentEntry
                                                                          .wakeUpTime!),
                                                            ),
                                                            style:
                                                                const TextStyle(
                                                                    fontSize:
                                                                        24)),
                                                        Icon(
                                                            getIconByOffset(((_currentEntry
                                                                        .getUpTime!
                                                                        .difference(_currentEntry
                                                                            .wakeUpTime!)
                                                                        .inSeconds -
                                                                    _stats
                                                                        .monthly
                                                                        .averageTimeBeforeGettingUp) /
                                                                _stats.monthly
                                                                    .averageTimeBeforeGettingUp)),
                                                            size: 14),
                                                        Text((((_currentEntry.getUpTime!.difference(_currentEntry.wakeUpTime!).inSeconds -
                                                                            GlobalData
                                                                                .trackingStats.monthly.averageTimeBeforeGettingUp) /
                                                                        GlobalData
                                                                            .trackingStats
                                                                            .monthly
                                                                            .averageTimeBeforeGettingUp) *
                                                                    100)
                                                                .floor()
                                                                .toStringAsFixed(
                                                                    1) +
                                                            "%")
                                                      ]),
                                          ],
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
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
