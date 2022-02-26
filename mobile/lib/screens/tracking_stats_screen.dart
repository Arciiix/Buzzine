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
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                          width: MediaQuery.of(context).size.width * 0.9 * 0.4,
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
                                          seconds: _trackingStats
                                              .monthly.averageSleepDuration)),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(
                                      getIconByOffset(((GlobalData
                                                  .trackingStats
                                                  .monthly
                                                  .averageSleepDuration -
                                              _trackingStats.lifetime
                                                  .averageSleepDuration) /
                                          _trackingStats
                                              .lifetime.averageSleepDuration)),
                                      size: 14),
                                  Text((((_trackingStats.monthly
                                                          .averageSleepDuration -
                                                      GlobalData
                                                          .trackingStats
                                                          .lifetime
                                                          .averageSleepDuration) /
                                                  GlobalData
                                                      .trackingStats
                                                      .lifetime
                                                      .averageSleepDuration) *
                                              100)
                                          .floor()
                                          .toStringAsFixed(1) +
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
                                              .monthly.averageTimeAtBed)),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(
                                      getIconByOffset(((_trackingStats
                                                  .monthly.averageTimeAtBed -
                                              _trackingStats
                                                  .lifetime.averageTimeAtBed) /
                                          _trackingStats
                                              .lifetime.averageTimeAtBed)),
                                      size: 14),
                                  Text((((_trackingStats.monthly
                                                          .averageTimeAtBed -
                                                      GlobalData
                                                          .trackingStats
                                                          .lifetime
                                                          .averageTimeAtBed) /
                                                  GlobalData
                                                      .trackingStats
                                                      .lifetime
                                                      .averageTimeAtBed) *
                                              100)
                                          .floor()
                                          .toStringAsFixed(1) +
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
                                              .averageAlarmWakeUpProcrastinationTime)),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(
                                      getIconByOffset(((GlobalData
                                                  .trackingStats
                                                  .monthly
                                                  .averageAlarmWakeUpProcrastinationTime -
                                              _trackingStats.lifetime
                                                  .averageAlarmWakeUpProcrastinationTime) /
                                          _trackingStats.lifetime
                                              .averageAlarmWakeUpProcrastinationTime)),
                                      size: 14),
                                  Text((((_trackingStats.monthly
                                                          .averageAlarmWakeUpProcrastinationTime -
                                                      GlobalData
                                                          .trackingStats
                                                          .lifetime
                                                          .averageAlarmWakeUpProcrastinationTime) /
                                                  GlobalData
                                                      .trackingStats
                                                      .lifetime
                                                      .averageAlarmWakeUpProcrastinationTime) *
                                              100)
                                          .floor()
                                          .toStringAsFixed(1) +
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
                                              .averageTimeBeforeGettingUp)),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(
                                      getIconByOffset(((GlobalData
                                                  .trackingStats
                                                  .monthly
                                                  .averageTimeBeforeGettingUp -
                                              _trackingStats.lifetime
                                                  .averageTimeBeforeGettingUp) /
                                          _trackingStats.lifetime
                                              .averageTimeBeforeGettingUp)),
                                      size: 14),
                                  Text((((_trackingStats.monthly
                                                          .averageTimeBeforeGettingUp -
                                                      GlobalData
                                                          .trackingStats
                                                          .lifetime
                                                          .averageTimeBeforeGettingUp) /
                                                  GlobalData
                                                      .trackingStats
                                                      .lifetime
                                                      .averageTimeBeforeGettingUp) *
                                              100)
                                          .floor()
                                          .toStringAsFixed(1) +
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
                          width: MediaQuery.of(context).size.width * 0.9 * 0.4,
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
                                      seconds: _trackingStats
                                          .lifetime.averageSleepDuration)),
                                  style: const TextStyle(fontSize: 24))
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
                              Text(
                                  durationToHHmm(Duration(
                                      seconds: _trackingStats
                                          .lifetime.averageTimeAtBed)),
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
                              Text(
                                  durationToHHmm(Duration(
                                      seconds: _trackingStats.lifetime
                                          .averageAlarmWakeUpProcrastinationTime)),
                                  style: const TextStyle(fontSize: 24))
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
                              Text(
                                  durationToHHmm(Duration(
                                      seconds: _trackingStats.lifetime
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
    );
  }
}
