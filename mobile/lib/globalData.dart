import 'package:buzzine/types/Alarm.dart';

class GlobalData {
  static late List<Alarm> alarms;
  static late List<Alarm> upcomingAlarms;
  static bool isLoading = true;

  GlobalData() {
    getData();
  }

  static Future<List<Alarm>> getData() async {
    isLoading = true;

    //TODO: Fetch the alarms from the API
    await Future.delayed(Duration(seconds: 1));

    alarms = [
      Alarm(
        hour: 20,
        minute: 00,
        isActive: true,
        isGuardEnabled: true,
        isSnoozeEnabled: true,
        snoozeLength: 5,
        maxTotalSnoozeLength: 15,
        soundName: "testowy.mp3",
        name: "testowyAlarm",
        notes: "To jest testowy alarm",
        nextInvocation: DateTime(2021, 12, 30, 20, 00),
      ),
      Alarm(
        hour: 21,
        minute: 10,
        isActive: false,
        isGuardEnabled: false,
        isSnoozeEnabled: false,
        name: "testowyAlarm2",
        notes: "To jest testowy alarm numer 2",
      ),
      Alarm(
        hour: 11,
        minute: 12,
        isGuardEnabled: false,
        isActive: false,
      ),
      Alarm(
        hour: 12,
        minute: 10,
        isGuardEnabled: true,
        isActive: false,
      ),
    ];

    upcomingAlarms = [
      Alarm(
        hour: 20,
        minute: 00,
        isActive: true,
        isGuardEnabled: true,
        isSnoozeEnabled: true,
        snoozeLength: 5,
        maxTotalSnoozeLength: 15,
        soundName: "testowy.mp3",
        name: "testowyAlarm",
        notes: "To jest testowy alarm",
        nextInvocation: DateTime(2021, 12, 30, 20, 00),
      ),
      Alarm(
        hour: 21,
        minute: 10,
        isActive: false,
        isGuardEnabled: false,
        isSnoozeEnabled: false,
        name: "testowyAlarm2",
        notes: "To jest testowy alarm numer 2",
      ),
      Alarm(
        hour: 11,
        minute: 12,
        isGuardEnabled: false,
        isActive: false,
      ),
      Alarm(
        hour: 12,
        minute: 10,
        isGuardEnabled: true,
        isActive: false,
      ),
    ];

    isLoading = false;
    return alarms;
  }
}
