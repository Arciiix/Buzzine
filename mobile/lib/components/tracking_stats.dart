import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class TrackingStatsWidget extends StatelessWidget {
  TrackingStatsService stats;

  TrackingStatsWidget({Key? key, required this.stats}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "TRACKINGstats",
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
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: stats.sleepDuration == null
                              ? [
                                  Text("-",
                                      style: const TextStyle(fontSize: 24))
                                ]
                              : [
                                  Text(
                                      secondsToHHmm(
                                        stats.sleepDuration!.value,
                                      ),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(stats.sleepDuration!.getIcon(true),
                                      size: 14),
                                  Text(stats.sleepDuration!.getOffset(true))
                                ]),
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
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: stats.timeAtBed == null
                              ? [
                                  Text("-",
                                      style: const TextStyle(fontSize: 24))
                                ]
                              : [
                                  Text(
                                      secondsToHHmm(
                                        stats.timeAtBed!.value,
                                      ),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(stats.timeAtBed!.getIcon(true),
                                      size: 14),
                                  Text(stats.timeAtBed!.getOffset(true))
                                ]),
                    ],
                  ),
                ),
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
                      Text("Przekładanie\nalarmów",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: stats.alarmWakeUpProcrastinationTime == null
                              ? [
                                  Text("-",
                                      style: const TextStyle(fontSize: 24))
                                ]
                              : [
                                  Text(
                                      secondsToHHmm(
                                        stats.alarmWakeUpProcrastinationTime!
                                            .value,
                                      ),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(
                                      stats.alarmWakeUpProcrastinationTime!
                                          .getIcon(true),
                                      size: 14),
                                  Text(stats.alarmWakeUpProcrastinationTime!
                                      .getOffset(true))
                                ]),
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
                      Text("Czas po\nobudzeniu się",
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: stats.timeBeforeGettingUp == null
                              ? [
                                  Text("-",
                                      style: const TextStyle(fontSize: 24))
                                ]
                              : [
                                  Text(
                                      secondsToHHmm(
                                        stats.timeBeforeGettingUp!.value,
                                      ),
                                      style: const TextStyle(fontSize: 24)),
                                  Icon(stats.timeBeforeGettingUp!.getIcon(true),
                                      size: 14),
                                  Text(stats.timeBeforeGettingUp!
                                      .getOffset(true))
                                ]),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
