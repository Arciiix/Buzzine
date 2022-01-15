import 'dart:convert';

import 'package:buzzine/types/API_exception.dart';
import 'package:buzzine/types/Repeat.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:http/http.dart' as http;
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GlobalData {
  static List<Alarm> alarms = [];
  static List<Alarm> upcomingAlarms = [];
  static List<RingingAlarmEntity> ringingAlarms = [];
  static List<Snooze> activeSnoozes = [];
  static List<Audio> audios = [];
  static late String qrCodeHash;
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
    await getRingingAlarms();
    await getActiveSnoozes();
    await getAudios();
    await getQrCodeHash();

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
              deleteAfterRinging: e?['deleteAfterRinging'] ?? false,
              maxTotalSnoozeDuration: e?['maxTotalSnoozeDuration'],
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
          .map((e) =>
              Audio(filename: e['filename'], friendlyName: e['friendlyName']))
          .toList();
    }

    GlobalData.audios
        .insert(0, Audio(filename: "default.mp3", friendlyName: "Domyślna"));

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

  static Future<void> deleteAudio(String filenameToDelete) async {
    var response = await http.delete(Uri.parse("$serverIP/v1/deleteSound"),
        body: json.encode({'filename': filenameToDelete}),
        headers: {"Content-Type": "application/json"});
    var decodedResponse = jsonDecode(utf8.decode(response.bodyBytes)) as Map;

    if (response.statusCode != 200 || decodedResponse['error'] == true) {
      throw APIException(
          "Błąd podczas usuwania audio $filenameToDelete. Status code: ${response.statusCode}, response: ${response.body}");
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
}
