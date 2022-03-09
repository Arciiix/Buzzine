import 'dart:math';

import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/utils/get_icon_by_offset.dart';
import 'package:flutter/material.dart';

class TrackingStats {
  DateTime timestamp;
  TrackingStatsDetails lifetime;
  TrackingStatsDetails monthly;

  TrackingStats(
      {required this.timestamp, required this.lifetime, required this.monthly});
}

class TrackingStatsDetails {
  TrackingStatsObject alarm;
  TrackingStatsObject nap;

  TrackingStatsDetails({required this.alarm, required this.nap});
}

class TrackingStatsObject {
  int averageSleepDuration;
  int averageTimeAtBed;
  int averageAlarmWakeUpProcrastinationTime;
  int averageTimeBeforeGettingUp;

  TrackingStatsObject(
      {required this.averageSleepDuration,
      required this.averageTimeAtBed,
      required this.averageAlarmWakeUpProcrastinationTime,
      required this.averageTimeBeforeGettingUp});
}

class TrackingStatsService {
  TrackingStats? statsObj;
  TrackingEntry? entry;

  TrackingValue? sleepDuration;
  TrackingValue? timeAtBed;
  TrackingValue? alarmWakeUpProcrastinationTime;
  TrackingValue? timeBeforeGettingUp;

  static TrackingStatsService of(TrackingEntry entry, TrackingStats stats) {
    TrackingStatsService service =
        TrackingStatsService(entry: entry, statsObj: stats);
    service.calculate();
    return service;
  }

  TrackingStatsService calculate() {
    if (entry!.wakeUpTime != null && entry!.sleepTime != null) {
      int sleepDurationVal =
          entry!.wakeUpTime!.difference(entry!.sleepTime!).inSeconds;

      if (entry!.isNap!) {
        sleepDuration = TrackingValue(
          value: sleepDurationVal,
          offsetMonthly:
              ((sleepDurationVal - statsObj!.monthly.nap.averageSleepDuration) /
                  max(statsObj!.monthly.nap.averageSleepDuration, 1) *
                  100),
          offsetLifetime: ((sleepDurationVal -
                  statsObj!.lifetime.nap.averageSleepDuration) /
              max(statsObj!.lifetime.nap.averageSleepDuration, 1) *
              100),
        );
      } else {
        sleepDuration = TrackingValue(
          value: sleepDurationVal,
          offsetMonthly: ((sleepDurationVal -
                  statsObj!.monthly.alarm.averageSleepDuration) /
              max(statsObj!.monthly.alarm.averageSleepDuration, 1) *
              100),
          offsetLifetime: ((sleepDurationVal -
                  statsObj!.lifetime.alarm.averageSleepDuration) /
              max(statsObj!.lifetime.alarm.averageSleepDuration, 1) *
              100),
        );
      }
    }

    if (entry!.sleepTime != null && entry!.bedTime != null) {
      int timeAtBedVal =
          entry!.sleepTime!.difference(entry!.bedTime!).inSeconds;

      if (entry!.isNap!) {
        timeAtBed = TrackingValue(
          value: timeAtBedVal,
          offsetMonthly:
              ((timeAtBedVal - statsObj!.monthly.nap.averageTimeAtBed) /
                  max(statsObj!.monthly.nap.averageTimeAtBed, 1) *
                  100),
          offsetLifetime:
              ((timeAtBedVal - statsObj!.lifetime.nap.averageTimeAtBed) /
                  max(statsObj!.lifetime.nap.averageTimeAtBed, 1) *
                  100),
        );
      } else {
        timeAtBed = TrackingValue(
          value: timeAtBedVal,
          offsetMonthly:
              ((timeAtBedVal - statsObj!.monthly.alarm.averageTimeAtBed) /
                  max(statsObj!.monthly.alarm.averageTimeAtBed, 1) *
                  100),
          offsetLifetime:
              ((timeAtBedVal - statsObj!.lifetime.alarm.averageTimeAtBed) /
                  max(statsObj!.lifetime.alarm.averageTimeAtBed, 1) *
                  100),
        );
      }
    }

    if (entry!.wakeUpTime != null && entry!.firstAlarmTime != null) {
      int alarmWakeUpProcrastinationVal =
          entry!.wakeUpTime!.difference(entry!.firstAlarmTime!).inSeconds;

      if (entry!.isNap!) {
        alarmWakeUpProcrastinationTime = TrackingValue(
          value: alarmWakeUpProcrastinationVal,
          offsetMonthly: ((alarmWakeUpProcrastinationVal -
                  statsObj!.monthly.nap.averageAlarmWakeUpProcrastinationTime) /
              max(statsObj!.monthly.nap.averageAlarmWakeUpProcrastinationTime,
                  1) *
              100),
          offsetLifetime: ((alarmWakeUpProcrastinationVal -
                  statsObj!
                      .lifetime.nap.averageAlarmWakeUpProcrastinationTime) /
              max(statsObj!.lifetime.nap.averageAlarmWakeUpProcrastinationTime,
                  1) *
              100),
        );
      } else {
        alarmWakeUpProcrastinationTime = TrackingValue(
          value: alarmWakeUpProcrastinationVal,
          offsetMonthly: ((alarmWakeUpProcrastinationVal -
                  statsObj!
                      .monthly.alarm.averageAlarmWakeUpProcrastinationTime) /
              max(statsObj!.monthly.alarm.averageAlarmWakeUpProcrastinationTime,
                  1) *
              100),
          offsetLifetime: ((alarmWakeUpProcrastinationVal -
                  statsObj!
                      .lifetime.alarm.averageAlarmWakeUpProcrastinationTime) /
              max(
                  statsObj!
                      .lifetime.alarm.averageAlarmWakeUpProcrastinationTime,
                  1) *
              100),
        );
      }
    }

    if (entry!.getUpTime != null && entry!.wakeUpTime != null) {
      int timeBeforeGettingUpVal =
          entry!.getUpTime!.difference(entry!.wakeUpTime!).inSeconds;

      if (entry!.isNap!) {
        timeBeforeGettingUp = TrackingValue(
          value: timeBeforeGettingUpVal,
          offsetMonthly: ((timeBeforeGettingUpVal -
                  statsObj!.monthly.nap.averageTimeBeforeGettingUp) /
              max(statsObj!.monthly.nap.averageTimeBeforeGettingUp, 1) *
              100),
          offsetLifetime: ((timeBeforeGettingUpVal -
                  statsObj!.lifetime.nap.averageTimeBeforeGettingUp) /
              max(statsObj!.lifetime.nap.averageTimeBeforeGettingUp, 1) *
              100),
        );
      } else {
        timeBeforeGettingUp = TrackingValue(
          value: timeBeforeGettingUpVal,
          offsetMonthly: ((timeBeforeGettingUpVal -
                  statsObj!.monthly.alarm.averageTimeBeforeGettingUp) /
              max(statsObj!.monthly.alarm.averageTimeBeforeGettingUp, 1) *
              100),
          offsetLifetime: ((timeBeforeGettingUpVal -
                  statsObj!.lifetime.alarm.averageTimeBeforeGettingUp) /
              max(statsObj!.lifetime.alarm.averageTimeBeforeGettingUp, 1) *
              100),
        );
      }
    }

    return this;
  }

  TrackingStatsService({this.entry, this.statsObj});
}

class TrackingValue {
  int value;
  double offsetMonthly;
  double offsetLifetime;

  IconData getIcon(bool monthly) {
    if (monthly) {
      return getIconByOffset(this.offsetMonthly / 100);
    } else {
      return getIconByOffset(this.offsetLifetime / 100);
    }
  }

  String getOffset(bool monthly) {
    if (monthly) {
      return this.offsetMonthly.toStringAsFixed(0) + "%";
    } else {
      return this.offsetLifetime.toStringAsFixed(0) + "%";
    }
  }

  TrackingValue(
      {required this.value,
      required this.offsetMonthly,
      required this.offsetLifetime});
}
