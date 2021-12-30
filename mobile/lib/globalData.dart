import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';

class GlobalData {
  static late List<Alarm> alarms;
  static late List<Alarm> upcomingAlarms;
  static late List<Audio> audios;
  static bool isLoading = true;

  GlobalData() {
    getData();
  }

  static Future<List<Alarm>> getData() async {
    isLoading = true;

    //TODO: Fetch the alarms from the API
    await Future.delayed(Duration(seconds: 1));

    await getAlarms();
    await getUpcomingAlarms();
    await getAudios();

    isLoading = false;
    return alarms;
  }

  static Future<List<Alarm>> getAlarms() async {
    //TODO: Fetch it from the API

    //DEV
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

    return alarms;
  }

  static Future<List<Alarm>> getUpcomingAlarms() async {
    //TODO: Fetch it from the API

    //DEV
    upcomingAlarms = [
      Alarm(
        id: 'alarm1',
        hour: 0,
        minute: 00,
        isActive: true,
        isGuardEnabled: true,
        isSnoozeEnabled: true,
        maxTotalSnoozeLength: 15,
        sound: Audio(filename: "testoweAudio", friendlyName: "testowy.mp3"),
        name: "testowyAlarm",
        notes: "To jest testowy alarm",
        nextInvocation: DateTime(2022, 1, 1, 0, 0),
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

    return upcomingAlarms;
  }

  static Future<List<Audio>> getAudios() async {
    //TODO: Fetch it from the API

    //DEV
    audios = [
      Audio(
        filename: "audio1.mp3",
        friendlyName: "Pierwsze audio",
      ),
      Audio(filename: "audio2.mp3", friendlyName: "Drugie audio"),
      Audio(filename: "audio3.mp3", friendlyName: "Trzecie audio"),
    ];

    audios.insert(0, Audio(filename: "default.mp3", friendlyName: "Domyślna"));

    return audios;
  }
}
