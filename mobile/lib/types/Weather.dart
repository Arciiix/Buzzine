import 'package:latlong2/latlong.dart';

class Weather {
  final DateTime timestamp;
  final double temperature;
  final double feelsLike;
  final double pressure;
  final double humidity;
  final double windSpeed;
  final double clouds;
  final DateTime? sunrise;
  final DateTime? sunset;
  final int weatherId;
  final String weatherTitle;
  final String weatherDescription;
  final String weatherIcon;
  final Uri weatherIconURL;

  Weather(
      {required this.timestamp,
      required this.temperature,
      required this.feelsLike,
      required this.pressure,
      required this.humidity,
      required this.windSpeed,
      required this.clouds,
      required this.weatherId,
      required this.weatherTitle,
      required this.weatherDescription,
      required this.weatherIcon,
      required this.weatherIconURL,
      this.sunrise,
      this.sunset});
}

class WeatherData {
  final Weather current;
  final List<Weather> hourly;
  final DateTime updatedAt = DateTime.now();
  final String? cityName;

  WeatherData({required this.current, required this.hourly, this.cityName});
}
