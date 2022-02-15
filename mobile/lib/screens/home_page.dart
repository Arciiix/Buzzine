import 'dart:async';
import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/audio_widget.dart';
import 'package:buzzine/components/carousel.dart';
import 'package:buzzine/components/ping_result_indicator.dart';
import 'package:buzzine/components/snooze_card.dart';
import 'package:buzzine/components/weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/download_YouTube_audio.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/screens/ringing_alarm.dart';
import 'package:buzzine/screens/scan_qr_code.dart';
import 'package:buzzine/screens/settings.dart';
import 'package:buzzine/screens/weather_screen.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/PingResult.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:buzzine/types/YouTubeVideoInfo.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/validate_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

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
  PingResult? pingResult;
  late StreamSubscription _intentData;

  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  void handleAlarmSelect(int? alarmIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => AlarmList(
              selectedAlarm:
                  alarmIndex != null ? upcomingAlarms[alarmIndex] : null)),
    );

    await refresh();
  }

  void navigateToAudioManager() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const AudioManager(selectAudio: false)));
    await refresh();
  }

  void navigateToSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const Settings()));
    await refresh();
  }

  void navigateToRingingAlarm(RingingAlarmEntity ringingAlarm,
      {bool? overrideIsSnoozeEnabled}) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RingingAlarm(
              ringingAlarm: ringingAlarm,
              overrideIsSnoozeEnabled: overrideIsSnoozeEnabled,
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

  void navigateToWeather() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => WeatherScreen()));
  }

  Future<void> refresh() async {
    _refreshState.currentState!.show();
  }

  void handleShareIntent(String? value) {
    print("Intent data: $value");
    if (youtubeRegExp.hasMatch(value ?? "")) {
      Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) =>
                DownloadYouTubeAudio(initialURL: Uri.tryParse(value ?? ""))),
      );
    }
  }

  @override
  void initState() {
    super.initState();

    _intentData =
        ReceiveSharingIntent.getTextStream().listen(handleShareIntent);
    ReceiveSharingIntent.getInitialText().then(handleShareIntent);

    GlobalData.getData().then((value) {
      setState(() {
        _isLoaded = true;
        upcomingAlarms = GlobalData.upcomingAlarms;
        qrCodeHash = GlobalData.qrCodeHash;
        ringingAlarms = GlobalData.ringingAlarms;
        activeSnoozes = GlobalData.activeSnoozes;
      });
      GlobalData.ping().then((PingResult result) {
        setState(() {
          pingResult = result;
        });
      });
      GlobalData.getWeatherData().then((_) {
        if (GlobalData.weather != null) {
          //Re-render the screen
          setState(() {});
        }
      });
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
          backgroundColor: const Color(0xFF00283F),
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

                        //Clear the current ping cached data
                        setState(() {
                          pingResult = null;
                        });
                        GlobalData.ping().then((PingResult result) {
                          setState(() {
                            pingResult = result;
                          });
                        });

                        //Clear the current cached weather data
                        GlobalData.weather = null;
                        await GlobalData.getWeatherData();
                        //Re-render the screen
                        setState(() {});
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
                                                      .ringingAlarmInstance,
                                                  overrideIsSnoozeEnabled:
                                                      false),
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
                              children: ringingAlarms.isEmpty &&
                                      activeSnoozes.isEmpty
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
                                child: AudioWidget()),
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
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      qrCodeHash,
                                      style: const TextStyle(fontSize: 30),
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
                            Container(
                              margin: const EdgeInsets.all(10),
                              child: Column(
                                children: GlobalData.weather != null
                                    ? [
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: const Padding(
                                              padding: EdgeInsets.all(5),
                                              child: Text("⛅ Pogoda",
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      color: Colors.white))),
                                        ),
                                        InkWell(
                                            onTap: navigateToWeather,
                                            child: Hero(
                                                tag: "WEATHER_WIDGET",
                                                child: WeatherWidget(
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .cardColor,
                                                )))
                                      ]
                                    : [],
                              ),
                            ),
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
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: Icon(Icons.settings),
                                        ),
                                        Text("Zmień ustawienia",
                                            style: TextStyle(fontSize: 24)),
                                      ],
                                    ))),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: Text("📈 Informacje",
                                      style: TextStyle(
                                          fontSize: 24, color: Colors.white))),
                            ),
                            Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 220,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Text(GlobalData.appVersion,
                                                    style: TextStyle(
                                                        fontSize: 32)),
                                                const Text("Wersja aplikacji",
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                              ],
                                            ),
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.spaceAround,
                                              children: [
                                                Text(GlobalData.appBuildNumber,
                                                    style: TextStyle(
                                                        fontSize: 32)),
                                                const Text("Numer buildu",
                                                    style: TextStyle(
                                                        fontSize: 18)),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      PingResultIndicator(
                                                        isSuccess: pingResult
                                                            ?.api.success,
                                                        delay: 0,
                                                        apiDelay: pingResult
                                                            ?.api.delay,
                                                        serviceName: "API",
                                                      ),
                                                      PingResultIndicator(
                                                        isSuccess: pingResult
                                                            ?.core.success,
                                                        delay: pingResult
                                                            ?.core.delay,
                                                        apiDelay: pingResult
                                                            ?.api.delay,
                                                        serviceName: "core",
                                                      ),
                                                      PingResultIndicator(
                                                        isSuccess: pingResult
                                                            ?.audio.success,
                                                        delay: pingResult
                                                            ?.audio.delay,
                                                        apiDelay: pingResult
                                                            ?.api.delay,
                                                        serviceName: "audio",
                                                      ),
                                                      PingResultIndicator(
                                                        isSuccess: pingResult
                                                            ?.adapter.success,
                                                        delay: pingResult
                                                            ?.adapter.delay,
                                                        apiDelay: pingResult
                                                            ?.api.delay,
                                                        serviceName: "adapter",
                                                      )
                                                    ],
                                                  ),
                                                  const Text("Status",
                                                      style: TextStyle(
                                                          fontSize: 18)),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                      pingResult?.api
                                                                  .uptimeText !=
                                                              null
                                                          ? pingResult!
                                                              .api.uptimeText!
                                                          : "Czekaj...",
                                                      style: TextStyle(
                                                          fontSize: 28)),
                                                  const Text("Czas pracy",
                                                      style: TextStyle(
                                                          fontSize: 18)),
                                                ],
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                    Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: pingResult?.timestamp != null
                                            ? [
                                                Text(
                                                    "Dane z ${dateToTimeString(pingResult!.timestamp.toLocal())}",
                                                    style: const TextStyle(
                                                        fontSize: 18)),
                                                IconButton(
                                                  icon:
                                                      const Icon(Icons.refresh),
                                                  onPressed: () async {
                                                    //Clear the current data
                                                    setState(() {
                                                      pingResult = null;
                                                    });
                                                    PingResult pingResultTemp =
                                                        await GlobalData.ping();
                                                    setState(() {
                                                      pingResult =
                                                          pingResultTemp;
                                                    });
                                                  },
                                                )
                                              ]
                                            : [
                                                const Text("Ładowanie...",
                                                    style:
                                                        TextStyle(fontSize: 18))
                                              ])
                                  ],
                                )),
                          ],
                        ),
                      )))));
    }
  }
}
