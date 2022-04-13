import 'dart:convert';
import 'package:buzzine/components/temperature_chart.dart';
import 'package:buzzine/types/API_exception.dart';
import 'package:buzzine/types/Constants.dart';
import 'package:buzzine/types/EmergencyStatus.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/types/PingResult.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/SleepAsAndroidIntegrationStatus.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:buzzine/types/TemperatureData.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/types/TrackingStats.dart';
import 'package:buzzine/types/Weather.dart';
import 'package:buzzine/types/YouTubeVideoInfo.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:latlong2/latlong.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
  static List<Alarm> alarms = [];
  static List<Alarm> upcomingAlarms = [];
  static List<RingingAlarmEntity> ringingAlarms = [];

  static List<Nap> naps = [];
  static List<Nap> upcomingNaps = [];
  static List<RingingAlarmEntity> ringingNaps = [];

  static List<Snooze> activeSnoozes = [];
  static List<Audio> audios = [];
  static late String qrCodeHash;
  static bool isLoading = true;
  static WeatherData? weather;
  static CurrentTemperatureData? currentTemperatureData;
  static PingResult? recentPing;

  static late String serverIP;
  static int audioPreviewDurationSeconds = 30;
  static LatLng? homeLocation;
  static int weatherHoursCount = 24;
  static RangeValues temperatureRange = RangeValues(19, 24);
  static Duration targetSleepDuration = Duration(hours: 7, minutes: 30);
  static Duration targetFallingAsleepTime = Duration(minutes: 15);

  static late SleepAsAndroidIntegrationStatus sleepAsAndroidIntegrationStatus;

  static late TrackingEntry latestTrackingEntry;
  static late TrackingStats trackingStats;

  static late Constants constants;
  static late EmergencyStatus emergencyStatus;
  static late String appVersion;
  static late String appBuildNumber;

  static late bool isLightModeEnabled;

  GlobalData() {
    getData();
  }

  static Future<void> getData({Function? onProgress}) async {
    isLoading = true;

    if (onProgress != null) onProgress("Ustawienia");
    await loadSettings();

    print("Fetching data...");
    if (onProgress != null) onProgress("Alarmy");
    await getAlarms();
    print("Got alarms");
    if (onProgress != null) onProgress("Nadchodzące alarmy");
    await getUpcomingAlarms();
    print("Got upcoming alarms");
    if (onProgress != null) onProgress("Aktywne alarmy");
    await getRingingAlarms();
    print("Got ringing alarms");
    if (onProgress != null) onProgress("Drzemki alarmów");
    await getActiveSnoozes();
    print("Got snoozes");
    if (onProgress != null) onProgress("Audio");
    await getAudios();
    print("Got audios");
    if (onProgress != null) onProgress("Hash kodu QR");
    await getQrCodeHash();
    print("Got hash");

    if (onProgress != null) onProgress("Wartości stałe");
    await getConstants();
    print("Got constants");
    if (onProgress != null) onProgress("Status systemu przeciwawaryjnego");
    await getEmergencyStatus();
    print("Got emergency status");
    if (onProgress != null) onProgress("Status integracji: Sleep as Android");
    await getSleepAsAndroidIntegrationStatus();
    print("Got Sleep as Android integration status");
    if (onProgress != null) onProgress("Dane najnowszego snu");
    await getLatestTrackingEntry();
    print("Got latest tracking entry data");
    if (onProgress != null) onProgress("Statystyki snu");
    await getTrackingStats();
    print("Got tracking stats");
    if (onProgress != null) onProgress("Wersja aplikacji");
    await getAppVersion();
    print("Got app version");

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
    temperatureRange = RangeValues(
        (_prefs.getDouble('TEMPERATURE_RANGE_START') ?? 19),
        _prefs.getDouble('TEMPERATURE_RANGE_END') ?? 24);

    targetSleepDuration = Duration(
        seconds: _prefs.getInt("SLEEP_DURATION") ?? (60 * 60 * 7.5).floor());
    targetFallingAsleepTime =
        Duration(seconds: _prefs.getInt("FALLING_ASLEEP_TIME") ?? 60 * 15);

    if (latitude != null && longitude != null) {
      homeLocation = LatLng(latitude, longitude);
    } else {
      homeLocation = null;
    }

    isLightModeEnabled = _prefs.getBool("IS_LIGHT_MODE_ENABLED") ?? false;
  }

  static Future<void> getAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getAllAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response']['alarms'];
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
                nextInvocation:
                    DateTime.tryParse(e['nextInvocationDate'] ?? ""),
                emergencyAlarmTimeoutSeconds: e['emergencyAlarmTimeoutSeconds'],
                isFavorite: e['isFavorite'] ?? false,
              ))
          .toList();
    }

    //Sort the alarms
    //By the invocation time
    GlobalData.alarms.sort((a, b) {
      if (a.nextInvocation != null && b.nextInvocation != null) {
        return a.nextInvocation!.compareTo(b.nextInvocation!);
      } else {
        return a.hour * 60 + a.minute - b.hour * 60 - b.minute;
      }
    });
    //Active ones first
    List<Alarm> activeAlarms =
        GlobalData.alarms.where((elem) => elem.isActive).toList();
    List<Alarm> inactiveAlarms =
        GlobalData.alarms.where((elem) => !elem.isActive).toList();
    //Favorite inactive alarms first
    inactiveAlarms.sort((a, b) => (a.isFavorite ?? false) ? 1 : -1);
    //Sort the active alarms by invocationDate
    activeAlarms.sort((a, b) => a.nextInvocation!.compareTo(b.nextInvocation!));

    GlobalData.alarms = [...activeAlarms, ...inactiveAlarms];

    //The same for naps
    List napsResponse = decodedResponse['response']['naps'];
    GlobalData.naps = napsResponse
        .map((e) => Nap(
              id: e['id'],
              hour: e['hour'],
              minute: e['minute'],
              second: e['second'],
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
              emergencyAlarmTimeoutSeconds: e['emergencyAlarmTimeoutSeconds'],
              invocationDate: DateTime.tryParse(e['invocationDate'] ?? ""),
              isFavorite: e['isFavorite'] ?? false,
            ))
        .toList();

    //Sort the naps
    //By length
    GlobalData.naps.sort((a, b) {
      if (a.nextInvocation != null && b.nextInvocation != null) {
        return a.nextInvocation!.compareTo(b.nextInvocation!);
      } else {
        return a.hour * 3600 +
            a.minute * 60 +
            a.second! -
            b.hour * 3600 -
            b.minute * 60 -
            b.second!;
      }
    });
    //Active ones first
    List<Nap> activeNaps =
        GlobalData.naps.where((elem) => elem.isActive).toList();
    List<Nap> inactiveNaps =
        GlobalData.naps.where((elem) => !elem.isActive).toList();
    //Favorite inactive naps first
    inactiveNaps.sort((a, b) => (a.isFavorite ?? false) ? 1 : -1);
    //Sort the active naps by invocationDate
    activeNaps.sort((a, b) => a.invocationDate!.compareTo(b.invocationDate!));

    GlobalData.naps = [...activeNaps, ...inactiveNaps];
  }

  static Future<void> getUpcomingAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getUpcomingAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania nadchodzących alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response']['alarms'];

      GlobalData.upcomingAlarms = alarmsResponse.map((e) {
        print(e['alarmId']);
        Alarm alarmObj = GlobalData.alarms
            .firstWhere((element) => element.id == e['alarmId']);
        alarmObj.nextInvocation = DateTime.tryParse(e['invocationDate']);
        return alarmObj;
      }).toList();

      GlobalData.upcomingAlarms.sort((a, b) =>
          a.nextInvocation != null && b.nextInvocation != null
              ? a.nextInvocation!.compareTo(b.nextInvocation!)
              : (a.hour * 60 + a.minute) - (b.hour * 60 + b.minute));

      //The same for naps
      List napsResponse = decodedResponse['response']['naps'];

      GlobalData.upcomingNaps = napsResponse.map((e) {
        Nap nap =
            GlobalData.naps.firstWhere((element) => element.id == e['napId']);
        return nap;
      }).toList();

      //If the date is null on the upcoming nap, it means it's probably invocated just right now
      GlobalData.upcomingNaps.sort((a, b) =>
          (a.invocationDate ?? DateTime.now())
              .compareTo((b.invocationDate ?? DateTime.now())));
    }
  }

  static Future<void> getRingingAlarms() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getRingingAlarms"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktywnych alarmów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List alarmsResponse = decodedResponse['response']['alarms'];
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

      //The same for naps
      List napsResponse = decodedResponse['response']['naps'];
      GlobalData.ringingNaps = napsResponse.map((e) {
        Nap? napEntity =
            GlobalData.naps.firstWhere((element) => element.id == e['id']);

        DateTime? maxDate;

        if (e['maxAlarmDate'] != null) {
          maxDate = DateTime.tryParse(e['maxAlarmDate']);
        }
        maxDate ??= DateTime.now()
            .add(Duration(seconds: napEntity.maxTotalSnoozeDuration ?? 300));

        RingingAlarmEntity ringingNap =
            RingingAlarmEntity(alarm: napEntity, maxDate: maxDate);

        return ringingNap;
      }).toList();
    }
  }

  static Future<List<Snooze>> getActiveSnoozes() async {
    var response = await http.get(Uri.parse("$serverIP/v1/getActiveSnoozes"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktywnych drzemek. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List snoozesResponse = [
        ...decodedResponse['response']['alarms'],
        ...decodedResponse['response']['naps']
      ];
      GlobalData.activeSnoozes = snoozesResponse.map((e) {
        Alarm alarmEntity = GlobalData.alarms.firstWhere(
            (element) => element.id == e['alarm']['id'],
            orElse: () => GlobalData.naps
                .firstWhere((element) => element.id == e['alarm']['id']));

        if (alarmEntity.id!.contains("NAP/")) {
          //Alarm is a nap
          alarmEntity.name = alarmEntity.name != null
              ? "[D] ${alarmEntity.name}"
              : "Drzemka bez nazwy";
        }

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
    var response = await http.get(Uri.parse("$serverIP/v1/audio/getSoundList"));
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
              friendlyName: e['friendlyName'],
              duration: e?['duration']))
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

    var response = await http.put(Uri.parse("$serverIP/v1/toggleAlarm"),
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

  static Future<void> addNap(Map napRequestBody, bool isEditing) async {
    var response = await http.post(
        Uri.parse("$serverIP/v1/${isEditing ? "updateNap" : "addNap"}"),
        body: json.encode(napRequestBody),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if ((response.statusCode != 201 && response.statusCode != 200) ||
        decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas tworzenia drzemki. Status code: ${response.statusCode}, response: ${response.body}");
    }

    //When we add a new nap, turn it on by default
    if (!isEditing) {
      await GlobalData.changeAlarmStatus(
          decodedResponse['response']['id'], true);
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
    var response = await http.delete(
        Uri.parse("$serverIP/v1/audio/deleteSound"),
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

    var response = await http.put(Uri.parse("$serverIP/v1/audio/tempMuteAudio"),
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
      Uri.parse("$serverIP/v1/audio/previewAudio")
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
    var response =
        await http.put(Uri.parse("$serverIP/v1/audio/stopAudioPreview"));
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

  static Future<CurrentTemperatureData> getCurrentTemperatureData() async {
    var response = await http
        .get(Uri.parse("$serverIP/v1/temperature/getCurrentTemperatureData"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania aktualnej temperatury. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var temperatureResponse = decodedResponse['response'];
      CurrentTemperatureData fetchedCurrentTemperatureData =
          CurrentTemperatureData(
              temperature: double.parse(
                  temperatureResponse['currentTemperature'].toStringAsFixed(2)),
              average: double.tryParse(
                  temperatureResponse?['average']?.toStringAsFixed(2) ?? ""),
              min: double.tryParse(
                  temperatureResponse?['min']?.toStringAsFixed(2) ?? ""),
              max: double.tryParse(
                  temperatureResponse?['max']?.toStringAsFixed(2) ?? ""),
              range: double.parse(
                  temperatureResponse?['range']?.toStringAsFixed(2) ?? ""),
              averageOffsetPercent: double.tryParse(
                  temperatureResponse?['averageOffsetPercent']?.toStringAsFixed(4) ??
                      ""),
              offsetPercent: double.parse(
                  temperatureResponse['offsetPercent'].toStringAsFixed(4)),
              temperatures: temperatureResponse['temperatures'].map<ChartData>((e) {
                return ChartData(
                    timestamp: DateTime.parse(e['timestamp']),
                    value: e['value']);
              }).toList());
      GlobalData.currentTemperatureData = fetchedCurrentTemperatureData;
    }

    return GlobalData.currentTemperatureData!;
  }

  static Future<TemperatureData?> getTemperatureDataForDate(
      DateTime date) async {
    Map<String, String> requestData = {
      'date': date.toLocal().toString(),
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/temperature/getHistoricalDailyTemperatureData")
          .replace(queryParameters: requestData),
    );

    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania historycznej temperatury. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var temperatureResponse = decodedResponse['response'];

      //Check if the temperature exists, for example check for the temperatures array
      if (temperatureResponse['temperatures'].length < 1) {
        return null;
      }

      TemperatureData fetchedTemperatureData = TemperatureData(
          average:
              double.parse(temperatureResponse['average'].toStringAsFixed(2)),
          min: double.parse(temperatureResponse['min'].toStringAsFixed(2)),
          max: double.parse(temperatureResponse['max'].toStringAsFixed(2)),
          range: double.parse(temperatureResponse['range'].toStringAsFixed(2)),
          averageOffsetPercent: double.parse(
              temperatureResponse['averageOffsetPercent'].toStringAsFixed(4)),
          temperatures: temperatureResponse['temperatures'].map<ChartData>((e) {
            return ChartData(
                timestamp: DateTime.parse(e['timestamp']), value: e['value']);
          }).toList());
      return fetchedTemperatureData;
    }
  }

  static Future<void> changeAudioName(String audioId, String newName) async {
    Map requestData = {'audioId': audioId, 'friendlyName': newName};

    var response = await http.put(Uri.parse("$serverIP/v1/audio/updateAudio"),
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
      Uri.parse("$serverIP/v1/audio/getYouTubeVideoInfo")
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

  static Future<void> previewAudioCut(
      String audioId, int start, int end) async {
    Map<String, String> requestData = {
      'audioId': audioId,
      'start': start.toString(),
      'end': end.toString()
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/audio/previewCut")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] != null) {
        throw APIException(
            "Błąd podczas podglądu przycinania audio $audioId. Status code: ${response.statusCode}, response: ${response.body}");
      }
    }
  }

  static Future<void> cutAudio(String audioId, int start, int end) async {
    Map requestData = {'audioId': audioId, 'start': start, 'end': end};

    var response = await http.put(Uri.parse("$serverIP/v1/audio/cutAudio"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas przycinania audio $audioId. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<String?> downloadYouTubeVideo(String videoURL) async {
    Map requestData = {'url': videoURL};

    var response = await http.post(
        Uri.parse("$serverIP/v1/audio/addYouTubeSound"),
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

  static Future<Constants> getConstants() async {
    var response = await http.get(
      Uri.parse("$serverIP/v1/getConstants"),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania wartości stałych. Status code: ${response.statusCode}, response: ${response.body}");
    }

    var responseData = decodedResponse['response'];
    GlobalData.constants =
        Constants(muteAfter: responseData['core']['MUTE_AFTER']);

    return GlobalData.constants;
  }

  static Future<EmergencyStatus> getEmergencyStatus() async {
    var response = await http.get(
      Uri.parse("$serverIP/v1/getEmergencyStatus"),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    // if (response.statusCode != 200 || decodedResponse['error'] == true) {
    //   throw APIException(
    //       "Błąd podczas pobierania statusu systemu przeciwawaryjnego. Status code: ${response.statusCode}, response: ${response.body}");
    // }

    GlobalData.emergencyStatus = EmergencyStatus(
        isEmergencyActive: decodedResponse['response']?['isActive'] ?? false,
        isEmergencyEnabled:
            decodedResponse['response']?['isProtectionTurnedOn'] ?? false,
        isEmergencyDeviceOn: decodedResponse['response']?['isRelayOn'] ?? false,
        error: decodedResponse['error']);

    return GlobalData.emergencyStatus;
  }

  static Future<void> toggleEmergency(bool isOn) async {
    Map requestData = {'isTurnedOn': isOn};

    var response = await http.put(
        Uri.parse("$serverIP/v1/emergency/toggleProtection"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isOn ? "włączania" : "wyłączania"} ochrony. Status code: ${response.statusCode}, response: ${response.body}");
    }

    await GlobalData.getEmergencyStatus();
    return;
  }

  static Future<void> toggleEmergencyDevice(bool isOn) async {
    Map requestData = {'isTurnedOn': isOn};

    var response = await http.put(
        Uri.parse("$serverIP/v1/emergency/toggleEmergency"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isOn ? "włączania" : "wyłączania"} urządzenia do ochrony. Status code: ${response.statusCode}, response: ${response.body}");
    }

    await GlobalData.getEmergencyStatus();
    return;
  }

  static Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    GlobalData.appVersion = packageInfo.version;
    GlobalData.appBuildNumber = packageInfo.buildNumber;
    return GlobalData.appVersion;
  }

  static Future<void> turnOffEmergency() async {
    var response =
        await http.put(Uri.parse("$serverIP/v1/cancelEmergencyAlarm"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas wyłączania systemu przeciwawaryjnego. Status code: ${response.statusCode}, response: ${response.body}");
    }
    GlobalData.emergencyStatus.isEmergencyActive = false;
    GlobalData.emergencyStatus.isEmergencyDeviceOn = false;
    return;
  }

  static Future<PingResult> ping() async {
    Map<String, String> requestData = {
      'timestamp': DateTime.now().toIso8601String(),
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/ping").replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (decodedResponse['response'] == null) {
      throw APIException(
          "Błąd podczas pingowania serwisów. Status code: ${response.statusCode}, response: ${response.body}; ");
    }
    var responseData = decodedResponse['response'];

    PingResult result = PingResult(
        error: decodedResponse['error'],
        api: ServicePing(
            success: responseData['api']['success'],
            delay: responseData['api']['delay'],
            uptime: responseData['api']['uptimeSeconds']),
        core: ServicePing(
            success: responseData['core']['success'],
            delay: responseData['core']['delay']),
        audio: ServicePing(
            success: responseData['audio']['success'],
            delay: responseData['audio']['delay']),
        adapter: ServicePing(
            success: responseData['adapter']['success'],
            delay: responseData['adapter']['delay']),
        tracking: ServicePing(
            success: responseData['tracking']['success'],
            delay: responseData['tracking']['delay']));

    if (result.error) {
      if (result.api.success && result.core.success && result.audio.success) {
        //Check if the error is caused by the adapter, and if so, return (because the app can start without it)
        GlobalData.recentPing = result;
        return result;
      }

      throw APIException(
          "Błąd podczas pingowania serwisów. ${result.toString()}");
    }
    GlobalData.recentPing = result;
    return result;
  }

  static Future<void> toggleNotifications(bool isTurnedOn, String token) async {
    Map requestData = {'isTurnedOn': isTurnedOn, 'token': token};

    var response = await http.put(
        Uri.parse("$serverIP/v1/notifications/toggleNotifications"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isTurnedOn ? "włączania" : "wyłączania"} powiadomień. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> sendTestNotification(String token) async {
    Map<String, String> requestData = {
      'token': token,
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/notifications/sendTestNotification")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas wysyłania testowego powiadomienia. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<bool> getNotificationsStatus(String token) async {
    Map<String, String> requestData = {
      'token': token,
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/notifications/checkIfTokenExists")
          .replace(queryParameters: requestData),
    );

    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if ((response.statusCode != 200 && response.statusCode != 404) ||
        decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania statusu powiadomień. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      return decodedResponse['response']['found'];
    }
  }

  static Future<SleepAsAndroidIntegrationStatus>
      getSleepAsAndroidIntegrationStatus() async {
    var response =
        await http.get(Uri.parse("$serverIP/v1/sleepasandroid/getStatus"));

    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania statusu integracji z Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var response = decodedResponse['response'];
      SleepAsAndroidIntegrationStatus _status = SleepAsAndroidIntegrationStatus(
          isActive: response['isActive'],
          emergencyAlarmTimeoutSeconds:
              response['emergencyAlarmTimeoutSeconds'],
          audio: Audio(
            audioId: response['associatedSound']['audioId'],
            filename: response['associatedSound']['filename'],
            friendlyName: response['associatedSound']['friendlyName'],
          ),
          delay: response['delay']);
      GlobalData.sleepAsAndroidIntegrationStatus = _status;
      return _status;
    }
  }

  static Future<void> toggleSleepAsAndroidIntegrationStatus(
      bool isActive) async {
    Map requestData = {'isActive': isActive};

    var response = await http.put(
        Uri.parse("$serverIP/v1/sleepasandroid/toggleStatus"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isActive ? "włączania" : "wyłączania"} integracji z Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> changeSleepAsAndroidIntegrationEmergencyAlarmTimeout(
      int emergencyAlarmTimeoutSeconds) async {
    Map requestData = {
      'emergencyAlarmTimeoutSeconds': emergencyAlarmTimeoutSeconds
    };

    var response = await http.put(
        Uri.parse(
            "$serverIP/v1/sleepasandroid/changeEmergencyAlarmTimeoutSeconds"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas zmieniania opóźnienia włączania dodatkowego urządzenia w integracji z Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> changeSleepAsAndroidIntegrationDelay(int delay) async {
    Map requestData = {'delay': delay};

    var response = await http.put(
        Uri.parse("$serverIP/v1/sleepasandroid/changeDelay"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas zmieniania opóźnienia włączania w integracji z Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> changeSleepAsAndroidIntegrationSound(
      String audioId) async {
    Map requestData = {'audioId': audioId};

    var response = await http.put(
        Uri.parse("$serverIP/v1/sleepasandroid/changeSound"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas zmieniania dźwięku integracji z Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> toggleSleepAsAndroidCurrentAlarm(bool isActive) async {
    Map requestData = {'isActive': isActive};

    var response = await http.put(
        Uri.parse("$serverIP/v1/sleepasandroid/toggleCurrentAlarm"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isActive ? "włączania" : "wyłączania"} bieżącego alarmu Sleep as Android. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<TrackingEntry> getLatestTrackingEntry() async {
    var response = await http.get(Uri.parse("$serverIP/v1/tracking/getLatest"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania najnowszego snu. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var entryData = decodedResponse['response'];
      TrackingEntry entry = TrackingEntry(
          date: DateTime.parse(entryData['date']),
          bedTime: DateTime.tryParse(entryData['bedTime'] ?? ""),
          sleepTime: DateTime.tryParse(entryData['sleepTime'] ?? ""),
          firstAlarmTime: DateTime.tryParse(entryData['firstAlarmTime'] ?? ""),
          wakeUpTime: DateTime.tryParse(entryData['wakeUpTime'] ?? ""),
          getUpTime: DateTime.tryParse(entryData['getUpTime'] ?? ""),
          alarmTimeFrom: DateTime.tryParse(entryData['alarmTimeFrom'] ?? ""),
          alarmTimeTo: DateTime.tryParse(entryData['alarmTimeTo'] ?? ""),
          rate: entryData['rate'],
          notes: entryData['notes'],
          isNap: DateTime.parse(entryData['date']).hour != 0 &&
              DateTime.parse(entryData['date']).minute != 0);

      List<TrackingVersionHistory>? versionHistory =
          await getTrackingVersionHistoryForDate(entry.date!);
      entry.versionHistory = versionHistory;

      GlobalData.latestTrackingEntry = entry;
      return entry;
    }
  }

  static Future<List<TrackingEntry>> getLastTrackingEntries(int count) async {
    var response = await http
        .get(Uri.parse("$serverIP/v1/tracking/getLastTrackingEntries/$count"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania ostatnich $count snów. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List entryData = decodedResponse['response'];
      List<TrackingEntry> entries = [];
      for (var e in entryData) {
        TrackingEntry entry = TrackingEntry(
            date: DateTime.parse(e['date']),
            bedTime: DateTime.tryParse(e['bedTime'] ?? ""),
            sleepTime: DateTime.tryParse(e['sleepTime'] ?? ""),
            firstAlarmTime: DateTime.tryParse(e['firstAlarmTime'] ?? ""),
            wakeUpTime: DateTime.tryParse(e['wakeUpTime'] ?? ""),
            getUpTime: DateTime.tryParse(e['getUpTime'] ?? ""),
            alarmTimeFrom: DateTime.tryParse(e['alarmTimeFrom'] ?? ""),
            alarmTimeTo: DateTime.tryParse(e['alarmTimeTo'] ?? ""),
            rate: e['rate'],
            notes: e['notes'],
            isNap: DateTime.parse(e['date']).hour != 0 &&
                DateTime.parse(e['date']).minute != 0);

        List<TrackingVersionHistory>? versionHistory =
            await getTrackingVersionHistoryForDate(entry.date!);
        entry.versionHistory = versionHistory;
        entries.add(entry);
      }

      return entries;
    }
  }

  static Future<List<TrackingVersionHistory>?> getTrackingVersionHistoryForDate(
      DateTime date) async {
    Map<String, String> requestData = {
      'date': date.toIso8601String(),
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/tracking/getVersionHistoryForDate")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania historii wersji dla daty ${dateToDateTimeString(date)}. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List versionHistory = decodedResponse['response'];
      return versionHistory.map((e) {
        return TrackingVersionHistory(
            timestamp: DateTime.parse(e['timestamp']),
            fieldName: TrackingFieldName.values.firstWhere((elem) =>
                elem.toString() == "TrackingFieldName." + e['fieldName']),
            value: e['value']);
      }).toList();
    }
  }

  static Future<List<TrackingEntry>> getTrackingEntriesForDay(
      DateTime day) async {
    Map<String, String> requestData = {
      'day': day.toIso8601String(),
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/tracking/getDataForDay")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania danych snu dla daty ${dateToDateTimeString(day)}. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      List entryData = decodedResponse['response'];
      List<TrackingEntry> entries = [];
      for (var e in entryData) {
        TrackingEntry entry = TrackingEntry(
            date: DateTime.parse(e['date']),
            bedTime: DateTime.tryParse(e['bedTime'] ?? ""),
            sleepTime: DateTime.tryParse(e['sleepTime'] ?? ""),
            firstAlarmTime: DateTime.tryParse(e['firstAlarmTime'] ?? ""),
            wakeUpTime: DateTime.tryParse(e['wakeUpTime'] ?? ""),
            getUpTime: DateTime.tryParse(e['getUpTime'] ?? ""),
            alarmTimeFrom: DateTime.tryParse(e['alarmTimeFrom'] ?? ""),
            alarmTimeTo: DateTime.tryParse(e['alarmTimeTo'] ?? ""),
            rate: e['rate'],
            notes: e['notes'],
            isNap: DateTime.parse(e['date']).hour != 0 &&
                DateTime.parse(e['date']).minute != 0);

        List<TrackingVersionHistory>? versionHistory =
            await getTrackingVersionHistoryForDate(entry.date!);
        entry.versionHistory = versionHistory;
        entries.add(entry);
      }

      return entries;
    }
  }

  static Future<void> updateTrackingEntry(
      DateTime date, Map updateObject) async {
    Map requestData = {
      'date': date.toIso8601String(),
      'updateObject': updateObject
    };

    var response = await http.put(
        Uri.parse("$serverIP/v1/tracking/updateDataForDate"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas aktualizowania danych snu. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> deleteTrackingEntry(DateTime date) async {
    var response = await http.delete(
        Uri.parse("$serverIP/v1/tracking/deleteEntry"),
        body: json.encode({'date': date.toIso8601String()}),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas usuwania snu z ${dateToDateTimeString(date)}. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<TrackingStats> getTrackingStats() async {
    var response =
        await http.get(Uri.parse("$serverIP/v1/tracking/stats/getStats"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas pobierania statystyk snu. Status code: ${response.statusCode}, response: ${response.body}");
    } else {
      var data = decodedResponse['response'];

      GlobalData.trackingStats = TrackingStats(
        timestamp: DateTime.parse(data['timestamp']),
        lifetime: TrackingStatsDetails(
            alarm: TrackingStatsObject(
                averageSleepDuration: data['lifetime']['alarm']
                    ['averageSleepDuration'],
                averageTimeAtBed: data['lifetime']['alarm']['averageTimeAtBed'],
                averageAlarmWakeUpProcrastinationTime: data['lifetime']['alarm']
                    ['averageAlarmWakeUpProcrastinationTime'],
                averageTimeBeforeGettingUp: data['lifetime']['alarm']
                    ['averageTimeBeforeGettingUp']),
            nap: TrackingStatsObject(
                averageSleepDuration: data['lifetime']['nap']
                    ['averageSleepDuration'],
                averageTimeAtBed: data['lifetime']['nap']['averageTimeAtBed'],
                averageAlarmWakeUpProcrastinationTime: data['lifetime']['nap']
                    ['averageAlarmWakeUpProcrastinationTime'],
                averageTimeBeforeGettingUp: data['lifetime']['nap']
                    ['averageTimeBeforeGettingUp'])),
        monthly: TrackingStatsDetails(
            alarm: TrackingStatsObject(
                averageSleepDuration: data['monthly']['alarm']
                    ['averageSleepDuration'],
                averageTimeAtBed: data['monthly']['alarm']['averageTimeAtBed'],
                averageAlarmWakeUpProcrastinationTime: data['monthly']['alarm']
                    ['averageAlarmWakeUpProcrastinationTime'],
                averageTimeBeforeGettingUp: data['monthly']['alarm']
                    ['averageTimeBeforeGettingUp']),
            nap: TrackingStatsObject(
                averageSleepDuration: data['monthly']['nap']
                    ['averageSleepDuration'],
                averageTimeAtBed: data['monthly']['nap']['averageTimeAtBed'],
                averageAlarmWakeUpProcrastinationTime: data['monthly']['nap']
                    ['averageAlarmWakeUpProcrastinationTime'],
                averageTimeBeforeGettingUp: data['monthly']['nap']
                    ['averageTimeBeforeGettingUp'])),
      );

      return GlobalData.trackingStats;
    }
  }

  static Future<TrackingStats> calculateTrackingStats() async {
    var response =
        await http.put(Uri.parse("$serverIP/v1/tracking/stats/calculateStats"));
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas obliczania statystyk snu. Status code: ${response.statusCode}, response: ${response.body}");
    }

    var data = decodedResponse['response'];

    GlobalData.trackingStats = TrackingStats(
      timestamp: DateTime.parse(data['timestamp']),
      lifetime: TrackingStatsDetails(
          alarm: TrackingStatsObject(
              averageSleepDuration: data['lifetime']['alarm']
                  ['averageSleepDuration'],
              averageTimeAtBed: data['lifetime']['alarm']['averageTimeAtBed'],
              averageAlarmWakeUpProcrastinationTime: data['lifetime']['alarm']
                  ['averageAlarmWakeUpProcrastinationTime'],
              averageTimeBeforeGettingUp: data['lifetime']['alarm']
                  ['averageTimeBeforeGettingUp']),
          nap: TrackingStatsObject(
              averageSleepDuration: data['lifetime']['nap']
                  ['averageSleepDuration'],
              averageTimeAtBed: data['lifetime']['nap']['averageTimeAtBed'],
              averageAlarmWakeUpProcrastinationTime: data['lifetime']['nap']
                  ['averageAlarmWakeUpProcrastinationTime'],
              averageTimeBeforeGettingUp: data['lifetime']['nap']
                  ['averageTimeBeforeGettingUp'])),
      monthly: TrackingStatsDetails(
          alarm: TrackingStatsObject(
              averageSleepDuration: data['monthly']['alarm']
                  ['averageSleepDuration'],
              averageTimeAtBed: data['monthly']['alarm']['averageTimeAtBed'],
              averageAlarmWakeUpProcrastinationTime: data['monthly']['alarm']
                  ['averageAlarmWakeUpProcrastinationTime'],
              averageTimeBeforeGettingUp: data['monthly']['alarm']
                  ['averageTimeBeforeGettingUp']),
          nap: TrackingStatsObject(
              averageSleepDuration: data['monthly']['nap']
                  ['averageSleepDuration'],
              averageTimeAtBed: data['monthly']['nap']['averageTimeAtBed'],
              averageAlarmWakeUpProcrastinationTime: data['monthly']['nap']
                  ['averageAlarmWakeUpProcrastinationTime'],
              averageTimeBeforeGettingUp: data['monthly']['nap']
                  ['averageTimeBeforeGettingUp'])),
    );
    return GlobalData.trackingStats;
  }

  static Future<void> addFadeEffects(
      String audioId, int fadeInDuration, int fadeOutDuration) async {
    Map requestData = {
      'audioId': audioId,
      'fadeInDuration': fadeInDuration,
      'fadeOutDuration': fadeOutDuration
    };

    var response = await http.put(
        Uri.parse("$serverIP/v1/audio/addAudioFadeEffect"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas dodawania efektów przejścia audio. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }

  static Future<void> previewFadeEffect(
      String audioId, int fadeInDuration, int fadeOutDuration) async {
    Map<String, String> requestData = {
      'audioId': audioId,
      'fadeInDuration': fadeInDuration.toString(),
      'fadeOutDuration': fadeOutDuration.toString()
    };

    var response = await http.get(
      Uri.parse("$serverIP/v1/audio/previewAudioFadeEffect")
          .replace(queryParameters: requestData),
    );
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      if (decodedResponse['errorCode'] != null) {
        throw APIException(
            "Błąd podczas podglądu efektów przejścia audio $audioId. Status code: ${response.statusCode}, response: ${response.body}");
      }
    }
  }

  static Future<void> toggleFavorite(String id, bool isFavorite) async {
    Map requestData = {
      'id': id,
      'isFavorite': isFavorite,
    };

    var response = await http.put(Uri.parse("$serverIP/v1/toggleFavorite"),
        body: json.encode(requestData),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas ${isFavorite ? "dodawania alarmu $id do ulubionych" : "usuwania alarmu $id z ulubionych"}. Status code: ${response.statusCode}, response: ${response.body}");
    }
  }
}
