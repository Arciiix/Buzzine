import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/TemperatureData.dart';
import "package:flutter/material.dart";

class TemperatureWidget extends StatefulWidget {
  final bool? dontGetData;
  final Color? backgroundColor;
  const TemperatureWidget({Key? key, this.dontGetData, this.backgroundColor})
      : super(key: key);

  @override
  _TemperatureWidgetState createState() => _TemperatureWidgetState();
}

class _TemperatureWidgetState extends State<TemperatureWidget> {
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.dontGetData != true) {
      GlobalData.getCurrentTemperatureData().then((_) {
        if (mounted) {
          setState(() {
            isLoaded = true;
          });
        }
      });
    } else {
      setState(() {
        isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return Material(
          color: Colors.transparent,
          child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(5),
              ),
              padding: EdgeInsets.all(8),
              width: MediaQuery.of(context).size.width,
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Icon(
                        GlobalData.currentTemperatureData!
                            .getIconForTemperature(),
                        size: 68),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            "${GlobalData.currentTemperatureData!.temperature.toStringAsFixed(2)}°C",
                            style: const TextStyle(fontSize: 32)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                                getIconByOffset(GlobalData
                                        .currentTemperatureData!.offsetPercent *
                                    100),
                                size: 18),
                            Text(
                              "${(GlobalData.currentTemperatureData!.offsetPercent * 100).toStringAsFixed(2)}%",
                              style: const TextStyle(fontSize: 18),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                TemperatureStatsWidget(
                    temperatureData: GlobalData.currentTemperatureData!),
              ])));
    } else {
      return Material(
        color: Colors.transparent,
        child: Container(
            decoration: BoxDecoration(
              color: (widget.backgroundColor ?? Colors.white),
              borderRadius: BorderRadius.circular(5),
            ),
            padding: EdgeInsets.all(8),
            width: MediaQuery.of(context).size.width,
            child: Column(children: [
              CircularProgressIndicator(
                  color: (widget.backgroundColor ?? Colors.white)
                              .computeLuminance() >
                          0.5
                      ? Colors.black
                      : Colors.white),
              const SizedBox(height: 10),
              Text("Pobieranie...",
                  style: TextStyle(
                      fontSize: 30,
                      color: (widget.backgroundColor ?? Colors.white)
                                  .computeLuminance() >
                              0.5
                          ? Colors.black
                          : Colors.white)),
            ])),
      );
    }
  }
}

class TemperatureStatsWidget extends StatelessWidget {
  final TemperatureData temperatureData;
  const TemperatureStatsWidget({Key? key, required this.temperatureData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
        tag: "TEMPERATURE_STATS_WIDGET",
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Średnia",
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    "${temperatureData.average.toStringAsFixed(2)}°C",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 18)),
                                Icon(
                                    getIconByOffset(
                                        temperatureData.averageOffsetPercent *
                                            100),
                                    size: 14),
                                Text(
                                    "${(temperatureData.averageOffsetPercent * 100).toStringAsFixed(2)}%",
                                    style: const TextStyle(fontSize: 14))
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Container(
                            height: 20, color: Colors.white, width: 2),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Amplituda",
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text(
                                "${temperatureData.range.toStringAsFixed(2)}°C",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Min.",
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text("${temperatureData.min.toStringAsFixed(2)}°C",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Container(
                            height: 20, color: Colors.white, width: 2),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              "Max.",
                              textAlign: TextAlign.center,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 24),
                            ),
                            Text("${temperatureData.max.toStringAsFixed(2)}°C",
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}

IconData getIconByOffset(double offset) {
  if (offset < 0) {
    return Icons.arrow_downward;
  } else if (offset > 0) {
    return Icons.arrow_upward;
  } else {
    return Icons.import_export;
  }
}
