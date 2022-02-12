import 'package:buzzine/components/weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/weather_icons_mapping.dart';
import 'package:flutter/material.dart';

class HourlyWeather extends StatefulWidget {
  final Weather weather;
  final bool? darkMode;
  const HourlyWeather({Key? key, required this.weather, this.darkMode})
      : super(key: key);

  @override
  State<HourlyWeather> createState() => _HourlyWeatherState();
}

class _HourlyWeatherState extends State<HourlyWeather> {
  void navigateToDetailedData() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              "${GlobalData.weather!.cityName} - ${addZero(widget.weather.timestamp.toLocal().hour)}:${addZero(widget.weather.timestamp.toLocal().minute)} ${addZero(widget.weather.timestamp.toLocal().day)}.${addZero(widget.weather.timestamp.toLocal().month)}.${widget.weather.timestamp.toLocal().year}"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              WeatherWidgetDisplay(
                weather: widget.weather,
                backgroundColor: Theme.of(context).cardColor,
              ),
              DetailedWeatherData(weather: widget.weather)
            ],
          ),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: navigateToDetailedData,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 15), //The icons in the font aren't centered
              child: Icon(
                getIconData(widget.weather.weatherIcon),
                color: widget.darkMode == true ? Colors.white : Colors.black,
                size: 30,
              ),
            ),
            Text(
                "${addZero(widget.weather.timestamp.toLocal().hour)}:${addZero(widget.weather.timestamp.toLocal().minute)}",
                style: TextStyle(
                  fontSize: 20,
                  color: widget.darkMode == true ? Colors.white : Colors.black,
                )),
            Text("${widget.weather.temperature}°C",
                style: TextStyle(
                  fontSize: 15,
                  color: widget.darkMode == true ? Colors.white : Colors.black,
                ))
          ],
        ),
      ),
    );
  }
}
