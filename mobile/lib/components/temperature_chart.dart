import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class TemperatureChart extends StatelessWidget {
  final List<ChartData> chartData;
  final String id;

  const TemperatureChart({Key? key, required this.chartData, required this.id})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        height: 300,
        width: MediaQuery.of(context).size.width,
        child: charts.TimeSeriesChart(
          [
            charts.Series<ChartData, DateTime>(
              id: id,
              colorFn: (_, __) => charts.MaterialPalette.white,
              domainFn: (ChartData entity, _) => entity.timestamp,
              measureFn: (ChartData entity, _) => entity.value,
              data: chartData,
            )..setAttribute(charts.rendererIdKey, "${id}Area")
          ],
          customSeriesRenderers: [
            charts.LineRendererConfig(
                customRendererId: '${id}Area',
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

class ChartData {
  DateTime timestamp;
  num value;

  ChartData({required this.timestamp, required this.value});
}
