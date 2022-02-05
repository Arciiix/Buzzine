import 'package:buzzine/components/weather_temperature_chart.dart';
import 'package:buzzine/components/weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({Key? key}) : super(key: key);

  @override
  _WeatherScreenState createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  void refreshWeatherData() async {
    await GlobalData.loadSettings();
    await GlobalData.getWeatherData();

    //Re-render the widget (update the data)
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
              fontSizeFactor: 1.2)),
      child: Scaffold(
          appBar:
              AppBar(title: Text(GlobalData?.weather?.cityName ?? "Pogoda")),
          body: Column(
            children: [
              Expanded(
                child: SafeArea(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Hero(
                            tag: "WEATHER_WIDGET",
                            child: WeatherWidget(
                                dontGetData: true,
                                backgroundColor:
                                    Theme.of(context).scaffoldBackgroundColor)),
                        WeatherTemperatureChart(),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Text("Szybkość wiatru"),
                                    Text(
                                        "${GlobalData.weather!.current.windSpeed.toString()} m/s"),
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
                                    Text("Ciśnienie"),
                                    Text(
                                        "${GlobalData.weather!.current.pressure.toString()} hPa"),
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
                                    Text("Wilgotność"),
                                    Text(
                                        "${GlobalData.weather!.current.humidity.toString()}%"),
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
                                    Text("Zachmurzenie"),
                                    Text(
                                        "${GlobalData.weather!.current.clouds.toString()}%"),
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
                                    Text("Godz. wschodu"),
                                    Text(
                                        "${addZero(GlobalData.weather!.current.sunrise!.hour)}:${addZero(GlobalData.weather!.current.sunrise!.minute)}"),
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
                                    Text("Godz. zachodu"),
                                    Text(
                                        "${addZero(GlobalData.weather!.current.sunset!.hour)}:${addZero(GlobalData.weather!.current.sunset!.minute)}"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "Dane z ${addZero(GlobalData.weather!.updatedAt.hour)}:${addZero(GlobalData.weather!.updatedAt.minute)}:${addZero(GlobalData.weather!.updatedAt.second)}"),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: refreshWeatherData,
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
