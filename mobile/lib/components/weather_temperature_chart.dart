import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class WeatherTemperatureChart extends StatelessWidget {
  const WeatherTemperatureChart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      width: MediaQuery.of(context).size.width,
      child: charts.BarChart(
        [
          charts.Series<Weather, String>(
            id: 'temperature',
            colorFn: (_, __) => charts.MaterialPalette.white,
            domainFn: (Weather weather, _) =>
                addZero(weather.timestamp.toLocal().hour),
            measureFn: (Weather weather, _) => weather.temperature,
            data: GlobalData.weather!.hourly,
          )
        ],
        domainAxis: charts.OrdinalAxisSpec(
            renderSpec: charts.SmallTickRendererSpec(
                labelStyle:
                    charts.TextStyleSpec(color: charts.MaterialPalette.white))),
        animate: true,
        animationDuration: Duration(milliseconds: 500),
        primaryMeasureAxis: charts.NumericAxisSpec(
            tickFormatterSpec:
                charts.BasicNumericTickFormatterSpec((num? val) => "$val°C"),
            renderSpec: charts.GridlineRendererSpec(
                labelStyle:
                    charts.TextStyleSpec(color: charts.MaterialPalette.white))),
      ),
    );
  }
}
