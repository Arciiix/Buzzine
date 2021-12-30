import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';

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
        id: 'alarm1',
        hour: 20,
        minute: 00,
        isActive: true,
        isGuardEnabled: true,
        isSnoozeEnabled: true,
        maxTotalSnoozeLength: 15,
        sound: Audio(filename: "testoweAudio", friendlyName: "testowy.mp3"),
        name: "testowyAlarm",
        notes: "To jest testowy alarm",
        nextInvocation: DateTime(2021, 12, 30, 20, 00),
      ),
      Alarm(
        id: 'alarm2',
        hour: 21,
        minute: 10,
        isActive: false,
        isGuardEnabled: false,
        isSnoozeEnabled: false,
        name: "testowyAlarm2",
        notes: "To jest testowy alarm numer 2",
      ),
      Alarm(
        id: 'alarm3',
        hour: 11,
        minute: 12,
        isGuardEnabled: false,
        isActive: false,
      ),
      Alarm(
        id: 'alarm4',
        hour: 12,
        minute: 10,
        isGuardEnabled: true,
        isActive: false,
      ),
    ];

    upcomingAlarms = [
      Alarm(
        id: 'alarm1',
        hour: 20,
        minute: 00,
        isActive: true,
        isGuardEnabled: true,
        isSnoozeEnabled: true,
        maxTotalSnoozeLength: 15,
        sound: Audio(filename: "testoweAudio", friendlyName: "testowy.mp3"),
        name: "testowyAlarm",
        notes: "To jest testowy alarm",
        nextInvocation: DateTime(2021, 12, 30, 20, 00),
      ),
      Alarm(
        id: 'alarm2',
        hour: 21,
        minute: 10,
        isActive: false,
        isGuardEnabled: false,
        isSnoozeEnabled: false,
        name: "testowyAlarm2",
        notes: "To jest testowy alarm numer 2",
      ),
      Alarm(
        id: 'alarm3',
        hour: 11,
        minute: 12,
        isGuardEnabled: false,
        isActive: false,
      ),
      Alarm(
        id: 'alarm4',
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
