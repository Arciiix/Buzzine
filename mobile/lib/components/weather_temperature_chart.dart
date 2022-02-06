import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'dart:math';

class WeatherTemperatureChart extends StatelessWidget {
  const WeatherTemperatureChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 300,
        width: MediaQuery.of(context).size.width,
        child: charts.TimeSeriesChart(
          [
            charts.Series<Weather, DateTime>(
              id: 'temperature',
              colorFn: (_, __) => charts.MaterialPalette.white,
              domainFn: (Weather weather, _) => weather.timestamp.toLocal(),
              measureFn: (Weather weather, _) => weather.temperature,
              data: GlobalData.weather!.hourly,
            )..setAttribute(charts.rendererIdKey, "temperatureArea")
          ],
          customSeriesRenderers: [
            charts.LineRendererConfig(
                customRendererId: 'temperatureArea',
                includeArea: true,
                stacked: true),
          ],
          domainAxis: charts.DateTimeAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(
                labelStyle:
                    charts.TextStyleSpec(color: charts.MaterialPalette.white)),
            tickFormatterSpec: charts.BasicDateTimeTickFormatterSpec(
                (DateTime? val) => addZero(val!.hour)),
          ),
          animate: true,
          animationDuration: Duration(milliseconds: 500),
          primaryMeasureAxis: charts.NumericAxisSpec(
              tickProviderSpec:
                  charts.BasicNumericTickProviderSpec(zeroBound: false),
              tickFormatterSpec:
                  charts.BasicNumericTickFormatterSpec((num? val) => "$val°C"),
              renderSpec: charts.GridlineRendererSpec(
                  labelStyle: charts.TextStyleSpec(
                      color: charts.MaterialPalette.white))),
        ),
      ),
    );
  }
}
