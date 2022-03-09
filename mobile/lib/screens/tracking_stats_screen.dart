import 'dart:math';

import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/get_icon_by_offset.dart';
import 'package:flutter/material.dart';

class TrackingStatsScreen extends StatefulWidget {
  const TrackingStatsScreen({Key? key}) : super(key: key);

  @override
  _TrackingStatsScreenState createState() => _TrackingStatsScreenState();
}

class _TrackingStatsScreenState extends State<TrackingStatsScreen> {
  late TrackingStats _trackingStats;

  Future<void> refresh() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa pobieranie statystyk snu...");
      },
    );
    await GlobalData.calculateTrackingStats();
    TrackingStats stats = await GlobalData.getTrackingStats();
    Navigator.of(context).pop();

    setState(() {
      _trackingStats = stats;
    });
  }

  @override
  void initState() {
    this._trackingStats = GlobalData.trackingStats;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Statystyki snu")),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Alarmy", style: TextStyle(fontSize: 32)),
            const Text("Ten miesiąc", style: TextStyle(fontSize: 24)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Hero(
                tag: "TRACKING_STATS",
                child: Material(
                  color: Colors.transparent,
                  child: Column(
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
                                  child: Icon(Icons.local_hotel, size: 24),
                                ),
                                Text("Długość snu",
                                    style: TextStyle(fontSize: 16)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        durationToHHmm(Duration(
                                            seconds: _trackingStats.monthly
                                                .alarm.averageSleepDuration)),
                                        style: const TextStyle(fontSize: 24)),
                                    Icon(
                                        getIconByOffset(((GlobalData
                                                    .trackingStats
                                                    .monthly
                                                    .alarm
                                                    .averageSleepDuration -
                                                _trackingStats.lifetime.alarm
                                                    .averageSleepDuration) /
                                            max(
                                                _trackingStats.lifetime.alarm
                                                    .averageSleepDuration,
                                                1))),
                                        size: 14),
                                    Text((((_trackingStats.monthly.alarm
                                                            .averageSleepDuration -
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageSleepDuration) /
                                                    max(
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageSleepDuration,
                                                        1)) *
                                                100)
                                            .floor()
                                            .toStringAsFixed(0) +
                                        "%")
                                  ],
                                )
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
                                  child: Icon(Icons.king_bed, size: 24),
                                ),
                                Text("Czas w łóżku",
                                    style: TextStyle(fontSize: 16)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        durationToHHmm(Duration(
                                            seconds: _trackingStats.monthly
                                                .alarm.averageTimeAtBed)),
                                        style: const TextStyle(fontSize: 24)),
                                    Icon(
                                        getIconByOffset(((_trackingStats.monthly
                                                    .alarm.averageTimeAtBed -
                                                _trackingStats.lifetime.alarm
                                                    .averageTimeAtBed) /
                                            max(
                                                _trackingStats.lifetime.alarm
                                                    .averageTimeAtBed,
                                                1))),
                                        size: 14),
                                    Text((((_trackingStats.monthly.alarm
                                                            .averageTimeAtBed -
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageTimeAtBed) /
                                                    max(
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageTimeAtBed,
                                                        1)) *
                                                100)
                                            .floor()
                                            .toStringAsFixed(0) +
                                        "%")
                                  ],
                                )
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
                                  child: Icon(Icons.skip_next, size: 24),
                                ),
                                Text(
                                  "Przekładanie\nalarmów",
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        durationToHHmm(Duration(
                                            seconds: GlobalData
                                                .trackingStats
                                                .monthly
                                                .alarm
                                                .averageAlarmWakeUpProcrastinationTime)),
                                        style: const TextStyle(fontSize: 24)),
                                    Icon(
                                        getIconByOffset(((GlobalData
                                                    .trackingStats
                                                    .monthly
                                                    .alarm
                                                    .averageAlarmWakeUpProcrastinationTime -
                                                _trackingStats.lifetime.alarm
                                                    .averageAlarmWakeUpProcrastinationTime) /
                                            max(
                                                _trackingStats.lifetime.alarm
                                                    .averageAlarmWakeUpProcrastinationTime,
                                                1))),
                                        size: 14),
                                    Text((((_trackingStats.monthly.alarm
                                                            .averageAlarmWakeUpProcrastinationTime -
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageAlarmWakeUpProcrastinationTime) /
                                                    max(
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageAlarmWakeUpProcrastinationTime,
                                                        1)) *
                                                100)
                                            .floor()
                                            .toStringAsFixed(0) +
                                        "%")
                                  ],
                                )
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
                                  child: Icon(Icons.smartphone, size: 24),
                                ),
                                Text(
                                  "Czas po\nobudzeniu się",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        durationToHHmm(Duration(
                                            seconds: GlobalData
                                                .trackingStats
                                                .monthly
                                                .alarm
                                                .averageTimeBeforeGettingUp)),
                                        style: const TextStyle(fontSize: 24)),
                                    Icon(
                                        getIconByOffset(((GlobalData
                                                    .trackingStats
                                                    .monthly
                                                    .alarm
                                                    .averageTimeBeforeGettingUp -
                                                _trackingStats.lifetime.alarm
                                                    .averageTimeBeforeGettingUp) /
                                            max(
                                                _trackingStats.lifetime.alarm
                                                    .averageTimeBeforeGettingUp,
                                                1))),
                                        size: 14),
                                    Text((((_trackingStats.monthly.alarm
                                                            .averageTimeBeforeGettingUp -
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageTimeBeforeGettingUp) /
                                                    max(
                                                        _trackingStats
                                                            .lifetime
                                                            .alarm
                                                            .averageTimeBeforeGettingUp,
                                                        1)) *
                                                100)
                                            .floor()
                                            .toStringAsFixed(0) +
                                        "%")
                                  ],
                                )
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
            const Text("Zawsze", style: TextStyle(fontSize: 24)),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
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
                                  child: Icon(Icons.local_hotel, size: 24),
                                ),
                                Text("Długość snu",
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.alarm
                                            .averageSleepDuration)),
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
                                  child: Icon(Icons.king_bed, size: 24),
                                ),
                                Text("Czas w łóżku",
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats
                                            .lifetime.alarm.averageTimeAtBed)),
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
                                  child: Icon(Icons.skip_next, size: 24),
                                ),
                                Text(
                                  "Przekładanie\nalarmów",
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.alarm
                                            .averageAlarmWakeUpProcrastinationTime)),
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
                                  child: Icon(Icons.smartphone, size: 24),
                                ),
                                Text(
                                  "Czas po\nobudzeniu się",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.alarm
                                            .averageTimeBeforeGettingUp)),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                )),
            const Text("Inne", style: TextStyle(fontSize: 32)),
            const Text("Ten miesiąc", style: TextStyle(fontSize: 24)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9 * 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.local_hotel, size: 24),
                            ),
                            Text("Długość snu", style: TextStyle(fontSize: 16)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats
                                            .monthly.nap.averageSleepDuration)),
                                    style: const TextStyle(fontSize: 24)),
                                Icon(
                                    getIconByOffset(((GlobalData
                                                .trackingStats
                                                .monthly
                                                .nap
                                                .averageSleepDuration -
                                            _trackingStats.lifetime.nap
                                                .averageSleepDuration) /
                                        max(
                                            _trackingStats.lifetime.nap
                                                .averageSleepDuration,
                                            1))),
                                    size: 14),
                                Text((((_trackingStats.monthly.nap
                                                        .averageSleepDuration -
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageSleepDuration) /
                                                max(
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageSleepDuration,
                                                    1)) *
                                            100)
                                        .floor()
                                        .toStringAsFixed(0) +
                                    "%")
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9 * 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.king_bed, size: 24),
                            ),
                            Text("Czas w łóżku",
                                style: TextStyle(fontSize: 16)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats
                                            .monthly.nap.averageTimeAtBed)),
                                    style: const TextStyle(fontSize: 24)),
                                Icon(
                                    getIconByOffset(((_trackingStats
                                                .monthly.nap.averageTimeAtBed -
                                            _trackingStats.lifetime.nap
                                                .averageTimeAtBed) /
                                        max(
                                            _trackingStats
                                                .lifetime.nap.averageTimeAtBed,
                                            1))),
                                    size: 14),
                                Text((((_trackingStats.monthly.nap
                                                        .averageTimeAtBed -
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageTimeAtBed) /
                                                max(
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageTimeAtBed,
                                                    1)) *
                                            100)
                                        .floor()
                                        .toStringAsFixed(0) +
                                    "%")
                              ],
                            )
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
                        width: MediaQuery.of(context).size.width * 0.9 * 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.skip_next, size: 24),
                            ),
                            Text(
                              "Przekładanie\nalarmów",
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: GlobalData
                                            .trackingStats
                                            .monthly
                                            .nap
                                            .averageAlarmWakeUpProcrastinationTime)),
                                    style: const TextStyle(fontSize: 24)),
                                Icon(
                                    getIconByOffset(((GlobalData
                                                .trackingStats
                                                .monthly
                                                .nap
                                                .averageAlarmWakeUpProcrastinationTime -
                                            _trackingStats.lifetime.nap
                                                .averageAlarmWakeUpProcrastinationTime) /
                                        max(
                                            _trackingStats.lifetime.nap
                                                .averageAlarmWakeUpProcrastinationTime,
                                            1))),
                                    size: 14),
                                Text((((_trackingStats.monthly.nap
                                                        .averageAlarmWakeUpProcrastinationTime -
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageAlarmWakeUpProcrastinationTime) /
                                                max(
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageAlarmWakeUpProcrastinationTime,
                                                    1)) *
                                            100)
                                        .floor()
                                        .toStringAsFixed(0) +
                                    "%")
                              ],
                            )
                          ],
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9 * 0.4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.smartphone, size: 24),
                            ),
                            Text(
                              "Czas po\nobudzeniu się",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: GlobalData
                                            .trackingStats
                                            .monthly
                                            .nap
                                            .averageTimeBeforeGettingUp)),
                                    style: const TextStyle(fontSize: 24)),
                                Icon(
                                    getIconByOffset(((GlobalData
                                                .trackingStats
                                                .monthly
                                                .nap
                                                .averageTimeBeforeGettingUp -
                                            _trackingStats.lifetime.nap
                                                .averageTimeBeforeGettingUp) /
                                        max(
                                            _trackingStats.lifetime.nap
                                                .averageTimeBeforeGettingUp,
                                            1))),
                                    size: 14),
                                Text((((_trackingStats.monthly.nap
                                                        .averageTimeBeforeGettingUp -
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageTimeBeforeGettingUp) /
                                                max(
                                                    GlobalData
                                                        .trackingStats
                                                        .lifetime
                                                        .nap
                                                        .averageTimeBeforeGettingUp,
                                                    1)) *
                                            100)
                                        .floor()
                                        .toStringAsFixed(0) +
                                    "%")
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
            const Text("Zawsze", style: TextStyle(fontSize: 24)),
            Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
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
                                  child: Icon(Icons.local_hotel, size: 24),
                                ),
                                Text("Długość snu",
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.nap
                                            .averageSleepDuration)),
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
                                  child: Icon(Icons.king_bed, size: 24),
                                ),
                                Text("Czas w łóżku",
                                    style: TextStyle(fontSize: 16)),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats
                                            .lifetime.nap.averageTimeAtBed)),
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
                                  child: Icon(Icons.skip_next, size: 24),
                                ),
                                Text(
                                  "Przekładanie\nalarmów",
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.nap
                                            .averageAlarmWakeUpProcrastinationTime)),
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
                                  child: Icon(Icons.smartphone, size: 24),
                                ),
                                Text(
                                  "Czas po\nobudzeniu się",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                    durationToHHmm(Duration(
                                        seconds: _trackingStats.lifetime.nap
                                            .averageTimeBeforeGettingUp)),
                                    style: const TextStyle(fontSize: 24))
                              ],
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                )),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextButton(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [Icon(Icons.refresh), Text("Odśwież")],
                      ),
                      onPressed: () async => await refresh()),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
