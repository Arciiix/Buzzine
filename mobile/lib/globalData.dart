import 'dart:convert';

import 'package:buzzine/types/API_exception.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/types/YouTubeVideoInfo.dart';
import 'package:http/http.dart' as http;
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
  static List<Alarm> alarms = [];
  static List<Alarm> upcomingAlarms = [];
  static List<RingingAlarmEntity> ringingAlarms = [];
  static List<Snooze> activeSnoozes = [];
  static List<Audio> audios = [];
  static late String qrCodeHash;
  static bool isLoading = true;
  static WeatherData? weather;

  static late String serverIP;
  static int audioPreviewDurationSeconds = 30;
  static LatLng? homeLocation;
  static int weatherHoursCount = 24;

  GlobalData() {
    getData();
  }

  static Future<void> getData() async {
    isLoading = true;

    await loadSettings();

    await getAlarms();
    await getUpcomingAlarms();
    await getRingingAlarms();
    await getActiveSnoozes();
    await getAudios();
    await getQrCodeHash();

    isLoading = false;
  }

  static Future<void> loadSettings() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    serverIP = _prefs.getString("API_SERVER_IP") ??
        "http://192.168.0.107:1111"; //DEV TODO: Change the default API server IP
    audioPreviewDurationSeconds =
        _prefs.getInt("AUDIO_PREVIEW_DURATION_SECONDS") ?? 30;

    double? latitude = _prefs.getDouble("HOME_LATITUDE");
    double? longitude = _prefs.getDouble("HOME_LONGITUDE");

    weatherHoursCount = _prefs.getInt("WEATHER_HOURS_COUNT") ?? 24;

    if (latitude != null && longitude != null) {
      homeLocation = LatLng(latitude, longitude);
    } else {
      homeLocation = null;
    }
  }

  static Future<List<Alarm>> getAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getAllAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response'];
      GlobalData.alarms = alarmsResponse
          .map((e) => Alarm(
              id: e['id'],
              hour: e['hour'],
              minute: e['minute'],
              isActive: e?['isActive'] ?? false,
              isGuardEnabled: e?['isGuardEnabled'] ?? false,
              isSnoozeEnabled: e?['isSnoozeEnabled'] ?? false,
              deleteAfterRinging: e?['deleteAfterRinging'] ?? false,
              maxTotalSnoozeDuration: e?['maxTotalSnoozeDuration'],
              sound: Audio(
                  audioId: e['sound']['audioId'],
                  filename: e['sound']['filename'],
                  friendlyName:
                      e['sound']['friendlyName'] ?? e['sound']['filename']),
              name: e['name'],
              notes: e['notes'],
              isRepeating: e['repeat'] != null,
              repeat: e['repeat'] != null
                  ? Repeat(
                      daysOfWeek: e['repeat']['dayOfWeek']?.cast<int>(),
                      days: e['repeat']['date']?.cast<int>(),
                      months: e['repeat']['month']?.cast<int>(),
                    )
                  : null,
              nextInvocation: DateTime.tryParse(e['nextInvocationDate'] ?? "")))
          .toList();
    }

    //Sort the alarms
    //By the invocation time
    GlobalData.alarms
        .sort((a, b) => a.hour * 60 + a.minute - b.hour * 60 - b.minute);
    //Active ones first
    List<Alarm> activeAlarms =
        GlobalData.alarms.where((elem) => elem.isActive).toList();
    List<Alarm> inactiveAlarms =
        GlobalData.alarms.where((elem) => !elem.isActive).toList();

    GlobalData.alarms = [...activeAlarms, ...inactiveAlarms];

    return GlobalData.alarms;
  }

  static Future<List<Alarm>> getUpcomingAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getUpcomingAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania nadchodzących alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response'];

      GlobalData.upcomingAlarms = alarmsResponse.map((e) {
        Alarm alarmObj = GlobalData.alarms
            .firstWhere((element) => element.id == e['alarmId']);
        alarmObj.nextInvocation = DateTime.tryParse(e['invocationDate']);
        return alarmObj;
      }).toList();

      GlobalData.upcomingAlarms.sort((a, b) =>
          a.nextInvocation != null && b.nextInvocation != null
              ? a.nextInvocation!.compareTo(b.nextInvocation!)
              : (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));
    }

    return GlobalData.upcomingAlarms;
  }

  static Future<List<RingingAlarmEntity>> getRingingAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getRingingAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktywnych alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response'];
      GlobalData.ringingAlarms = alarmsResponse.map((e) {
        Alarm? alarmEntity =
            GlobalData.alarms.firstWhere((element) => element.id == e['id']);

        DateTime? maxDate;

        if (e['maxAlarmDate'] != null) {
          maxDate = DateTime.tryParse(e['maxAlarmDate']);
        }
        maxDate ??= DateTime.now()
            .add(Duration(seconds: alarmEntity.maxTotalSnoozeDuration ?? 300));

        RingingAlarmEntity ringingAlarm =
            RingingAlarmEntity(alarm: alarmEntity, maxDate: maxDate);

        return ringingAlarm;
      }).toList();
    }

    return GlobalData.ringingAlarms;
  }

  static Future<List<Snooze>> getActiveSnoozes() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getActiveSnoozes"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktywnych drzemek. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List snoozesResponse = decodedResponse['response'];
      GlobalData.activeSnoozes = snoozesResponse.map((e) {
        Alarm? alarmEntity = GlobalData.alarms
            .firstWhere((element) => element.id == e['alarm']['id']);

        DateTime? maxDate;

        if (e['alarm']['maxAlarmDate'] != null) {
          maxDate = DateTime.tryParse(e['alarm']['maxAlarmDate']);
        }
        maxDate ??= DateTime.now()
            .add(Duration(seconds: alarmEntity.maxTotalSnoozeDuration ?? 300));

        RingingAlarmEntity ringingAlarm =
            RingingAlarmEntity(alarm: alarmEntity, maxDate: maxDate);

        Snooze snoozeObj = Snooze(
          id: e['snooze']['id'],
          startDate:
              DateTime.tryParse(e['snooze']?['startDate']) ?? DateTime.now(),
          invocationDate:
              DateTime.tryParse(e['snooze']?['invocationDate']) ?? maxDate,
          length: e['snooze']['length'],
          ringingAlarmInstance: ringingAlarm,
        );

        return snoozeObj;
      }).toList();
    }

    return GlobalData.activeSnoozes;
  }

  static Future<List<Audio>> getAudios() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getSoundList"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania audio. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List audiosResponse = decodedResponse['data'];
      GlobalData.audios = audiosResponse
          .map((e) => Audio(
              audioId: e['audioId'],
              filename: e['filename'],
              friendlyName: e['friendlyName']))
          .toList();
    }

    return GlobalData.audios;
  }

  static Future<String> getQrCodeHash() async {
    var response =
        await http.get(Uri.parse("$serverIP/v1/guard/getCurrentQRCodeHash"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktualnego hashu kodu QR. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      GlobalData.qrCodeHash = decodedResponse['currentHash'];
    }

    return GlobalData.qrCodeHash;
  }

  static Future<void> changeAlarmStatus(String id, bool status) async {
    Map requestData = {'id': id, 'status': status};

    var response = await http.put(Uri.parse("$serverIP/v1/toogleAlarm"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas włączania/wyłączania alarmu. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> addAlarm(Map alarmRequestBody, bool isEditing) async {
    var response = await http.post(
        Uri.parse("$serverIP/v1/${isEditing ? "updateAlarm" : "addAlarm"}"),
        body: json.encode(alarmRequestBody),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if ((response.statusCode != 201 && response.statusCode != 200) ||
        decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas tworzenia alarmu. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> deleteAlarm(String alarmId) async {
    var response = await http.delete(Uri.parse("$serverIP/v1/deleteAlarm"),
        body: json.encode({'id': alarmId}),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas usuwania alarmu $alarmId. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> deleteAudio(String idToDelete) async {
    var response = await http.delete(Uri.parse("$serverIP/v1/deleteSound"),
        body: json.encode({'audioId': idToDelete}),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas usuwania audio $idToDelete. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<String> generateQRCode() async {
    var response =
        await http.post(Uri.parse("$serverIP/v1/guard/generateQRCode"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas generowania kodu QR. Status code: ${response.statusCode}, response: ${response.body}");
    }
    GlobalData.qrCodeHash = decodedResponse['generatedHash'];
    return GlobalData.qrCodeHash;
  }

  static Future<void> cancelAllAlarms() async {
    var response = await http.put(Uri.parse("$serverIP/v1/cancelAllAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas wyłączania wszystkich alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    }
    GlobalData.ringingAlarms = [];
    return;
  }

  static Future<bool> snoozeAlarm(String alarmId, int snoozeDuration) async {
    Map requestData = {'id': alarmId, 'snoozeDuration': snoozeDuration};

    var response = await http.put(Uri.parse("$serverIP/v1/snoozeAlarm"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas włączania drzemki. Status code: ${response.statusCode}, response: ${response.body}");
    }

    return decodedResponse['response']['didSnooze'] ?? false;
  }

  //Returns true if the audio has been muted successfully, and false if user has already muted it
  static Future<bool> muteAudio(int duration) async {
    Map requestData = {'duration': duration};

    var response = await http.put(Uri.parse("$serverIP/v1/tempMuteAudio"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] != 'ALREADY_USED') {
        throw APIException(
            "Błąd podczas wyciszania audio. Status code: ${response.statusCode}, response: ${response.body}");
      }
      return false;
    }
    return true;
  }

  //Cancel the next invocation of a repeating alarm. Returns the next invocation date
  static Future<DateTime?> cancelNextInvocation(String repeatingAlarmId) async {
    Map requestData = {'id': repeatingAlarmId};

    var response = await http.put(
        Uri.parse("$serverIP/v1/cancelNextInvocation"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] != null) {
        throw APIException(
            "Błąd podczas wyłączania następnego wywołania alarmu. Status code: ${response.statusCode}, response: ${response.body}");
      }
      return null;
    }

    await GlobalData.getUpcomingAlarms();
    return DateTime.tryParse(
        decodedResponse['response']?['nextInvocationDate']);
  }

  static Future<bool> previewAudio(String audioId) async {
    Map<String, String> requestData = {
      'audioId': audioId,
      'duration': audioPreviewDurationSeconds.toString()
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/previewAudio")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] != null) {
        throw APIException(
            "Błąd podczas podglądu audio $audioId. Status code: ${response.statusCode}, response: ${response.body}");
      }
      return false;
    }

    return true;
  }

  static Future<void> stopAudioPreview() async {
    var response = await http.put(Uri.parse("$serverIP/v1/stopAudioPreview"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas wyłączania podglądu audio. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<WeatherData?> getWeatherData() async {
    if (homeLocation == null) {
      await loadSettings();
      if (homeLocation == null) {
        weather = null;
        return null;
      }
    }

    Map<String, String> requestData = {
      'latitude': homeLocation!.latitude.toString(),
      'longitude': homeLocation!.longitude.toString(),
      'hoursCount': weatherHoursCount.toString(),
      'getCityName': "true"
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/weather/getFullWeather")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania pogody. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var weatherResponse = decodedResponse['response'];
      var current = weatherResponse['current'];
      List hourly = weatherResponse['hourly'];
      WeatherData weatherInstance = WeatherData(
          current: Weather(
            timestamp: DateTime.parse(current['timestamp']),
            temperature: double.parse(current['temperature'].toString()),
            feelsLike: double.parse(current['feelsLike'].toString()),
            pressure: double.parse(current['pressure'].toString()),
            humidity: double.parse(current['humidity'].toString()),
            windSpeed: double.parse(current['windSpeed'].toString()),
            clouds: double.parse(current['clouds'].toString()),
            weatherId: int.parse(current['weatherId'].toString()),
            weatherTitle: current['weatherTitle'],
            weatherDescription: current['weatherDescription'],
            weatherIcon: current['weatherIcon'],
            weatherIconURL: Uri.parse(current['weatherIconURL']),
            sunrise: DateTime.parse(current['sunrise']),
            sunset: DateTime.parse(current['sunset']),
          ),
          hourly: hourly
              .map((e) => Weather(
                    timestamp: DateTime.parse(e['timestamp']),
                    temperature: double.parse(e['temperature'].toString()),
                    feelsLike: double.parse(e['feelsLike'].toString()),
                    pressure: double.parse(e['pressure'].toString()),
                    humidity: double.parse(e['humidity'].toString()),
                    windSpeed: double.parse(e['windSpeed'].toString()),
                    clouds: double.parse(e['clouds'].toString()),
                    weatherId: int.parse(e['weatherId'].toString()),
                    weatherTitle: e['weatherTitle'],
                    weatherDescription: e['weatherDescription'],
                    weatherIcon: e['weatherIcon'],
                    weatherIconURL: Uri.parse(e['weatherIconURL']),
                  ))
              .toList(),
          cityName: weatherResponse?['cityName']);

      GlobalData.weather = weatherInstance;
    }

    return GlobalData.weather;
  }

  static Future<void> changeAudioName(String audioId, String newName) async {
    Map requestData = {'audioId': audioId, 'friendlyName': newName};

    var response = await http.put(Uri.parse("$serverIP/v1/updateAudio"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas aktualizacji audio. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<YouTubeVideoInfo?> getYouTubeVideoInfo(String videoURL) async {
    Map<String, String> requestData = {
      'videoURL': videoURL,
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/getYouTubeVideoInfo")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode == 200 && decodedResponse['error'] == false) {
      var videoInfo = decodedResponse['response'];
      if (videoInfo == null) return null;
      return YouTubeVideoInfo(
          channel: YouTubeChannelInfo(
              name: videoInfo['channel']['name'],
              id: videoInfo['channel']?['id'],
              isVerified: videoInfo['channel']?['isVerified'],
              username: videoInfo['channel']?['username'],
              url: Uri.tryParse(videoInfo['channel']?['url'])),
          description: videoInfo['description'],
          length: Duration(seconds: int.parse(videoInfo['lengthSeconds'])),
          thumbnailURL: videoInfo['thumbnail']['url'],
          title: videoInfo['title'],
          uploadDate: DateTime.tryParse(videoInfo?['uploadDate']),
          url: videoInfo?['url']);
    }
    return null;
  }

  static Future<String?> downloadYouTubeVideo(String videoURL) async {
    Map requestData = {'url': videoURL};

    var response = await http.post(Uri.parse("$serverIP/v1/addYouTubeSound"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 201 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] == 'ALREADY_EXISTS') {
        return "to audio już istnieje";
      } else if (decodedResponse['errorCode'] == 'WRONG_URL') {
        return "zły URL";
      } else if (decodedResponse['errorCode'] == 'YOUTUBE_ERROR') {
        return "błąd YouTube. Prawdopodobnie zły adres URL lub stara wersja ytdl-core";
      } else {
        throw APIException(
            "Błąd podczas pobierania audio z YouTube. Status code: ${response.statusCode}, response: ${response.body}");
      }
    }
  }
}
