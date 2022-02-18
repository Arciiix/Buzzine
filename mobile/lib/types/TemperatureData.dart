import 'package:buzzine/components/temperature_chart.dart';
import 'package:buzzine/globalData.dart';
import 'package:flutter/material.dart';

class TemperatureData {
  double? average;
  double? min;
  double? max;
  double? range;
  double? averageOffsetPercent;
  List<ChartData> temperatures;

  TemperatureData(
      {this.average,
      this.min,
      this.max,
      this.range,
      this.averageOffsetPercent,
      required this.temperatures});
}

class CurrentTemperatureData extends TemperatureData {
  double temperature;
  double offsetPercent;
  DateTime timestamp = DateTime.now();

  IconData getIconForTemperature() {
    if (this.temperature > GlobalData.temperatureRange.end) {
      return Icons.whatshot;
    } else if (this.temperature < GlobalData.temperatureRange.start) {
      return Icons.ac_unit;
    } else {
      return Icons.thermostat;
    }
  }

  CurrentTemperatureData(
      {required this.temperature,
      required this.offsetPercent,
      double? average,
      double? min,
      double? max,
      double? range,
      double? averageOffsetPercent,
      required List<ChartData> temperatures})
      : super(
            average: average,
            min: min,
            max: max,
            range: range,
            averageOffsetPercent: averageOffsetPercent,
            temperatures: temperatures);
}
