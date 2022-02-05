import 'package:buzzine/components/hourly_weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/utils/weather_icons_mapping.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';

class WeatherWidget extends StatefulWidget {
  final bool? dontGetData;
  final Color? backgroundColor;
  const WeatherWidget({Key? key, this.dontGetData, this.backgroundColor})
      : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.dontGetData != true) {
      GlobalData.loadSettings().then((_) {
        GlobalData.getWeatherData().then((_) {
          setState(() {
            isLoaded = true;
          });
        });
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
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            bottom: 30), //The icons in the font aren't centered
                        child: Icon(
                          getIconData(GlobalData.weather!.current.weatherIcon),
                          color: (widget.backgroundColor ?? Colors.white)
                                      .computeLuminance() >
                                  0.5
                              ? Colors.black
                              : Colors.white,
                          size: 60,
                        ),
                      )),
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Text("${GlobalData.weather!.current.temperature}°C",
                            style: TextStyle(
                                color: (widget.backgroundColor ?? Colors.white)
                                            .computeLuminance() >
                                        0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 40)),
                        Text(GlobalData.weather!.current.weatherDescription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: (widget.backgroundColor ?? Colors.white)
                                            .computeLuminance() >
                                        0.5
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 25)),
                      ],
                    ),
                  ),
                ],
              ),
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                      children: GlobalData.weather!.hourly
                          .map((e) => HourlyWeather(
                              weather: e,
                              darkMode: (widget.backgroundColor ?? Colors.white)
                                      .computeLuminance() <
                                  0.5))
                          .toList()))
            ],
          ),
        ),
      );
    } else {
      return Material(
        child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
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
              const Text("Pobieranie...", style: TextStyle(fontSize: 30)),
            ])),
      );
    }
  }
}
