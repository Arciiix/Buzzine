import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/weather_icons_mapping.dart';
import 'package:flutter/material.dart';

class HourlyWeather extends StatelessWidget {
  final Weather weather;
  final bool? darkMode;
  const HourlyWeather({Key? key, required this.weather, this.darkMode})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
                bottom: 15), //The icons in the font aren't centered
            child: Icon(
              getIconData(weather.weatherIcon),
              color: darkMode == true ? Colors.white : Colors.black,
              size: 30,
            ),
          ),
          Text(
              "${addZero(weather.timestamp.toLocal().hour)}:${addZero(weather.timestamp.toLocal().minute)}",
              style: TextStyle(
                fontSize: 20,
                color: darkMode == true ? Colors.white : Colors.black,
              )),
          Text("${weather.temperature}°C",
              style: TextStyle(
                fontSize: 15,
                color: darkMode == true ? Colors.white : Colors.black,
              ))
        ],
      ),
    );
  }
}
