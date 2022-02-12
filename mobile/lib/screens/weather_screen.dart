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
          appBar: AppBar(title: Text(GlobalData.weather?.cityName ?? "Pogoda")),
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
                        DetailedWeatherData(
                          weather: GlobalData.weather!.current,
                        )
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
