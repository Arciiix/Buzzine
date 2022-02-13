import 'package:buzzine/components/hourly_weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/utils/formatting.dart';
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
          child: WeatherWidgetDisplay(
            weather: GlobalData.weather!.current,
            hourlyWeather: GlobalData.weather!.hourly,
            backgroundColor: widget.backgroundColor,
          ));
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

class WeatherWidgetDisplay extends StatelessWidget {
  final Color? backgroundColor;
  final Weather weather;
  final List<Weather>? hourlyWeather;
  const WeatherWidgetDisplay(
      {Key? key,
      this.backgroundColor,
      required this.weather,
      this.hourlyWeather})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
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
                      color:
                          (backgroundColor ?? Colors.white).computeLuminance() >
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
                    Text("${weather.temperature}°C",
                        style: TextStyle(
                            color: (backgroundColor ?? Colors.white)
                                        .computeLuminance() >
                                    0.5
                                ? Colors.black
                                : Colors.white,
                            fontSize: 40)),
                    Text(weather.weatherDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: (backgroundColor ?? Colors.white)
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
                  children: hourlyWeather != null
                      ? hourlyWeather!
                          .map((e) => HourlyWeather(
                              weather: e,
                              darkMode: (backgroundColor ?? Colors.white)
                                      .computeLuminance() <
                                  0.5))
                          .toList()
                      : []))
        ],
      ),
    );
  }
}

class DetailedWeatherData extends StatefulWidget {
  final Weather weather;

  const DetailedWeatherData({Key? key, required this.weather})
      : super(key: key);

  @override
  _DetailedWeatherDataState createState() => _DetailedWeatherDataState();
}

class _DetailedWeatherDataState extends State<DetailedWeatherData> {
  @override
  Widget build(BuildContext context) {
    return Column(
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
                      "Szybkość wiatru",
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${widget.weather.windSpeed.toStringAsFixed(0)} m/s",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Container(height: 20, color: Colors.white, width: 2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Ciśnienie",
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${widget.weather.pressure.toStringAsFixed(0)} hPa",
                      textAlign: TextAlign.center,
                    ),
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
                      "Wilgotność",
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${widget.weather.humidity.toStringAsFixed(0)}%",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Container(height: 20, color: Colors.white, width: 2),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "Zachmurzenie",
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${widget.weather.clouds.toStringAsFixed(0)}%",
                      textAlign: TextAlign.center,
                    ),
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
            children: (widget.weather.sunrise != null &&
                    widget.weather.sunset != null)
                ? [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Godz. wschodu",
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "${addZero(widget.weather.sunrise!.toLocal().hour)}:${addZero(widget.weather.sunrise!.toLocal().minute)}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child:
                          Container(height: 20, color: Colors.white, width: 2),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            "Godz. zachodu",
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            "${addZero(widget.weather.sunset!.toLocal().hour)}:${addZero(widget.weather.sunset!.toLocal().minute)}",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ]
                : [],
          ),
        ),
      ],
    );
  }
}
