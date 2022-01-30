import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/carousel.dart';
import 'package:buzzine/components/snooze_card.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/screens/ringing_alarm.dart';
import 'package:buzzine/screens/scan_qr_code.dart';
import 'package:buzzine/screens/settings.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:buzzine/utils/validate_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoaded = false;
  List<Alarm> upcomingAlarms = [];
  List<RingingAlarmEntity> ringingAlarms = [];
  List<Snooze> activeSnoozes = [];
  late String qrCodeHash;

  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  void handleAlarmSelect(int? alarmIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => AlarmList(
              selectedAlarm:
                  alarmIndex != null ? upcomingAlarms[alarmIndex] : null)),
    );
  }

  void navigateToAudioManager() {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const AudioManager(selectAudio: false)));
  }

  void navigateToSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const Settings()));
  }

  void navigateToRingingAlarm(RingingAlarmEntity ringingAlarm) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RingingAlarm(
              ringingAlarm: ringingAlarm,
            )));

    //Refresh everything - for example alarm could've been deleted because of the deleteAfterRinging option
    await refresh();
  }

  void printQRCode() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String serverIP = _prefs.getString("API_SERVER_IP") ??
        "http://192.168.0.107:3333"; //DEV TODO: Change the default API server IP
    await launch("$serverIP/v1/guard/printQRCode");
  }

  void generateQRCode() async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wygeneruj nowy hash"),
          content: Text(
              'Czy na pewno chcesz wygenerować nowy hash? Stary stanie się nieważny.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wygeneruj")),
          ],
        );
      },
    );

    //It could be either null, so I check it by ==
    if (confirmed == true) {
      await GlobalData.generateQRCode();
      setState(() {
        qrCodeHash = GlobalData.qrCodeHash;
      });
    }
  }

  void testQRCode() async {
    String? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ScanQRCode(targetHash: qrCodeHash)));

    if (result != null) {
      if (validateQRCode(result, qrCodeHash)) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("Prawidłowy kod QR"),
                  content: const Text(
                      "Ten kod QR jest prawidłowym kodem Buzzine. Możesz go używać do wyłączania alarmu."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"))
                  ],
                ));
      } else {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("Błędy kod QR"),
                  content: const Text(
                      "Ten kod QR nie jest prawidłowym kodem Buzzine. Może to być np. stary, nieaktualny już kod."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"))
                  ],
                ));
      }
    }
  }

  Future<void> refresh() async {
    _refreshState.currentState!.show();
  }

  @override
  void initState() {
    super.initState();

    GlobalData.getData().then((value) => {
          setState(() {
            _isLoaded = true;
            upcomingAlarms = GlobalData.upcomingAlarms;
            qrCodeHash = GlobalData.qrCodeHash;
            ringingAlarms = GlobalData.ringingAlarms;
            activeSnoozes = GlobalData.activeSnoozes;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Loading(
        showText: true,
        isInitLoading: true,
      );
    } else {
      return Scaffold(
          body: Padding(
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                  child: RefreshIndicator(
                      key: _refreshState,
                      onRefresh: () async {
                        await GlobalData.getData();
                        setState(() {
                          upcomingAlarms = GlobalData.upcomingAlarms;
                          qrCodeHash = GlobalData.qrCodeHash;
                          ringingAlarms = GlobalData.ringingAlarms;
                          activeSnoozes = GlobalData.activeSnoozes;
                        });
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text("Buzzine",
                                      style: TextStyle(
                                          fontSize: 48, color: Colors.white))),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: ringingAlarms.isNotEmpty
                                  ? [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Text("🚨 Aktywne alarmy",
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      Carousel(
                                          height: 320,
                                          onSelect: (_) =>
                                              navigateToRingingAlarm(
                                                  ringingAlarms.first),
                                          children: ringingAlarms.map((e) {
                                            return AlarmCard(
                                                id: e.alarm.id!,
                                                name: e.alarm.name,
                                                hour: e.alarm.hour,
                                                minute: e.alarm.minute,
                                                nextInvocation:
                                                    e.alarm.nextInvocation,
                                                isActive: e.alarm.isActive,
                                                isSnoozeEnabled:
                                                    e.alarm.isSnoozeEnabled,
                                                maxTotalSnoozeDuration: e.alarm
                                                    .maxTotalSnoozeDuration,
                                                sound: e.alarm.sound,
                                                isGuardEnabled:
                                                    e.alarm.isGuardEnabled,
                                                deleteAfterRinging:
                                                    e.alarm.deleteAfterRinging,
                                                notes: e.alarm.notes,
                                                isRepeating:
                                                    e.alarm.isRepeating,
                                                repeat: e.alarm.repeat,
                                                hideSwitch: true);
                                          }).toList()),
                                    ]
                                  : [],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: activeSnoozes.isNotEmpty
                                  ? [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Text("😴 Aktywne drzemki",
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      Carousel(
                                          height: 320,
                                          onSelect: (_) =>
                                              navigateToRingingAlarm(
                                                  activeSnoozes.first
                                                      .ringingAlarmInstance),
                                          children:
                                              activeSnoozes.map((Snooze e) {
                                            return SnoozeCard(
                                              name: e.ringingAlarmInstance.alarm
                                                  .name,
                                              invocationDate: e.invocationDate,
                                              maxAlarmTime: e
                                                  .ringingAlarmInstance
                                                  .maxDate!,
                                              maxTotalSnoozeDuration: e
                                                  .ringingAlarmInstance
                                                  .alarm
                                                  .maxTotalSnoozeDuration,
                                              sound: e.ringingAlarmInstance
                                                  .alarm.sound,
                                              isGuardEnabled: e
                                                  .ringingAlarmInstance
                                                  .alarm
                                                  .isGuardEnabled,
                                              deleteAfterRinging: e
                                                  .ringingAlarmInstance
                                                  .alarm
                                                  .deleteAfterRinging,
                                              notes: e.ringingAlarmInstance
                                                  .alarm.notes,
                                              isRepeating: e
                                                  .ringingAlarmInstance
                                                  .alarm
                                                  .isRepeating,
                                              repeat: e.ringingAlarmInstance
                                                  .alarm.repeat,
                                            );
                                          }).toList()),
                                    ]
                                  : [],
                            ),
                            Column(
                              children: ringingAlarms.isEmpty
                                  ? [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: const Padding(
                                          padding: EdgeInsets.all(5),
                                          child: Text("⏰ Nadchodzące alarmy",
                                              style: TextStyle(
                                                  fontSize: 24,
                                                  color: Colors.white)),
                                        ),
                                      ),
                                      Carousel(
                                          height: 320,
                                          onSelect: handleAlarmSelect,
                                          children: upcomingAlarms.map((e) {
                                            return AlarmCard(
                                                key: Key(e.id!),
                                                id: e.id!,
                                                name: e.name,
                                                hour: e.hour,
                                                minute: e.minute,
                                                nextInvocation:
                                                    e.nextInvocation,
                                                isActive: e.isActive,
                                                isSnoozeEnabled:
                                                    e.isSnoozeEnabled,
                                                maxTotalSnoozeDuration:
                                                    e.maxTotalSnoozeDuration,
                                                sound: e.sound,
                                                isGuardEnabled:
                                                    e.isGuardEnabled,
                                                deleteAfterRinging:
                                                    e.deleteAfterRinging,
                                                notes: e.notes,
                                                isRepeating: e.isRepeating,
                                                repeat: e.repeat,
                                                refresh: refresh);
                                          }).toList()),
                                    ]
                                  : [],
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text("🎵 Audio",
                                      style: TextStyle(
                                          fontSize: 24, color: Colors.white))),
                            ),
                            InkWell(
                                onTap: navigateToAudioManager,
                                child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: 120,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                            GlobalData.audios.length.toString(),
                                            style:
                                                const TextStyle(fontSize: 52)),
                                        const Text("Ilość audio",
                                            style: TextStyle(fontSize: 24))
                                      ],
                                    ))),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text("🔒 Ochrona",
                                      style: TextStyle(
                                          fontSize: 24, color: Colors.white))),
                            ),
                            Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 200,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      qrCodeHash,
                                      style: const TextStyle(fontSize: 38),
                                      textAlign: TextAlign.center,
                                    ),
                                    const Text("Hash kodu QR",
                                        style: TextStyle(fontSize: 24)),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        TextButton(
                                            onPressed: generateQRCode,
                                            child: Row(
                                              children: const [
                                                Icon(Icons.refresh),
                                                Text("Wygeneruj")
                                              ],
                                            )),
                                        TextButton(
                                            onPressed: printQRCode,
                                            child: Row(
                                              children: const [
                                                Icon(Icons.print),
                                                Text("Wydrukuj")
                                              ],
                                            )),
                                        TextButton(
                                            onPressed: testQRCode,
                                            child: Row(
                                              children: const [
                                                Icon(Icons.quiz),
                                                Text("Przetestuj")
                                              ],
                                            )),
                                      ],
                                    )
                                  ],
                                )),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text("⚙️ Ustawienia",
                                      style: TextStyle(
                                          fontSize: 24, color: Colors.white))),
                            ),
                            InkWell(
                                onTap: navigateToSettings,
                                child: Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.9,
                                    height: 50,
                                    padding: const EdgeInsets.all(10),
                                    margin: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Center(
                                        child: Text("Zmień ustawienia",
                                            style: TextStyle(fontSize: 24))))),
                          ],
                        ),
                      )))));
    }
  }
}
