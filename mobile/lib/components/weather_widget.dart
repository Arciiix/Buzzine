import 'package:buzzine/components/hourly_weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/utils/weather_icons_mapping.dart';
import "package:flutter/material.dart";
import 'package:flutter/rendering.dart';

class WeatherWidget extends StatefulWidget {
  const WeatherWidget({Key? key}) : super(key: key);

  @override
  _WeatherWidgetState createState() => _WeatherWidgetState();
}

class _WeatherWidgetState extends State<WeatherWidget> {
  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    GlobalData.loadSettings().then((_) {
      GlobalData.getWeatherData().then((_) {
        setState(() {
          isLoaded = true;
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoaded) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
                        color: Colors.black,
                        size: 60,
                      ),
                    )),
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      Text("${GlobalData.weather!.current.temperature}°C",
                          style: const TextStyle(
                              color: Colors.black, fontSize: 40)),
                      Text(GlobalData.weather!.current.weatherDescription,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 25)),
                    ],
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    children: GlobalData.weather!.hourly
                        .map((e) => HourlyWeather(weather: e))
                        .toList()))
          ],
        ),
      );
    } else {
      return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
          ),
          padding: EdgeInsets.all(8),
          width: MediaQuery.of(context).size.width,
          child: Column(children: const [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 10),
            Text("Pobieranie...", style: TextStyle(fontSize: 30)),
          ]));
    }
  }
}
