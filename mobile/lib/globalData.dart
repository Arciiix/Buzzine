import 'dart:convert';

import 'package:buzzine/types/API_exception.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
  static late List<Alarm> alarms;
  static late List<Alarm> upcomingAlarms;
  static late List<Audio> audios;
  static bool isLoading = true;

  static late String serverIP;

  GlobalData() {
    getData();
  }

  static Future<void> getData() async {
    isLoading = true;

    SharedPreferences _prefs = await SharedPreferences.getInstance();
    serverIP = _prefs.getString("API_SERVER_IP") ??
        "http://192.168.0.107:3333"; //DEV TODO: Change the default API server IP

    await getAlarms();
    await getUpcomingAlarms();
    await getAudios();

    isLoading = false;
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
              maxTotalSnoozeLength: e?['maxTotalSnoozeLength'],
              sound: Audio(
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
        return GlobalData.alarms
            .firstWhere((element) => element.id == e['alarmId']);
      }).toList();
    }

    return GlobalData.upcomingAlarms;
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
          .map((e) =>
              Audio(filename: e['filename'], friendlyName: e['friendlyName']))
          .toList();
    }

    GlobalData.audios
        .insert(0, Audio(filename: "default.mp3", friendlyName: "Domyślna"));

    return GlobalData.audios;
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
}
