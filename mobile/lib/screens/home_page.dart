import 'dart:async';
import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/audio_widget.dart';
import 'package:buzzine/components/carousel.dart';
import 'package:buzzine/components/emergency_device_status.dart';
import 'package:buzzine/components/guard_widget.dart';
import 'package:buzzine/components/logo.dart';
import 'package:buzzine/components/ping_result_indicator.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/components/sleep_as_android_integration.dart';
import 'package:buzzine/components/sleep_calculations_widget.dart';
import 'package:buzzine/components/snooze_card.dart';
import 'package:buzzine/components/temperature_widget.dart';
import 'package:buzzine/components/tracking_entry_widget.dart';
import 'package:buzzine/components/weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_history.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/download_YouTube_audio.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/screens/nap_list.dart';
import 'package:buzzine/screens/qr_codes_manager.dart';
import 'package:buzzine/screens/ringing_alarm.dart';
import 'package:buzzine/screens/scan_qr_code.dart';
import 'package:buzzine/screens/settings.dart';
import 'package:buzzine/screens/temperature_screen.dart';
import 'package:buzzine/screens/unlock_alarm.dart';
import 'package:buzzine/screens/weather_screen.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/AlarmType.dart';
import 'package:buzzine/types/EmergencyStatus.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/types/PingResult.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/types/Snooze.dart';
import 'package:buzzine/types/YouTubeVideoInfo.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:buzzine/utils/validate_qr_code.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  List<Nap> upcomingNaps = [];
  List<RingingAlarmEntity> ringingNaps = [];
  List<Snooze> activeSnoozes = [];
  PingResult? pingResult;
  late EmergencyStatus emergencyStatus;
  late StreamSubscription _intentData;

  GlobalKey<TrackingEntryWidgetState> _trackingWidgetKey =
      GlobalKey<TrackingEntryWidgetState>();

  String? _currentLoadingStage = "Inicjalizacja";

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

  void handleNapSelect(int? napIndex) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
          builder: (context) => NapList(
                selectedNap: napIndex != null ? upcomingNaps[napIndex] : null,
              )),
    );

    await refresh();
  }

  void navigateToAudioManager() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const AudioManager(selectAudio: false)));
    await refresh();
  }

  void navigateToQRCodesManager() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const QRCodesManager(selectCode: false)));
    await refresh();
  }

  void navigateToSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const Settings()));
    await refresh();
  }

  Future<void> navigateToRingingAlarm(RingingAlarmEntity ringingAlarm,
      {bool? isItActuallyRinging}) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => RingingAlarm(
              ringingAlarm: ringingAlarm,
              isItActuallyRinging: isItActuallyRinging,
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
              'Czy na pewno chcesz wygenerowa?? nowy hash? Stary stanie si?? niewa??ny.'),
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa generowanie hashu kodu QR...");
        },
      );
      await GlobalData.generateQRCode();
      Navigator.of(context).pop();
    }
  }

  void testQRCode() async {
    // String? result = await Navigator.of(context).push(MaterialPageRoute(
    //     builder: (context) => ScanQRCode(targetName: qrCodeHash)));

    // if (result != null) {
    //   if (validateQRCode(result, qrCodeHash)) {
    //     showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //               title: const Text("Prawid??owy kod QR"),
    //               content: const Text(
    //                   "Ten kod QR jest prawid??owym kodem Buzzine. Mo??esz go u??ywa?? do wy????czania alarmu."),
    //               actions: [
    //                 TextButton(
    //                     onPressed: () => Navigator.of(context).pop(),
    //                     child: const Text("OK"))
    //               ],
    //             ));
    //   } else {
    //     showDialog(
    //         context: context,
    //         builder: (_) => AlertDialog(
    //               title: const Text("B????dy kod QR"),
    //               content: const Text(
    //                   "Ten kod QR nie jest prawid??owym kodem Buzzine. Mo??e to by?? np. stary, nieaktualny ju?? kod."),
    //               actions: [
    //                 TextButton(
    //                     onPressed: () => Navigator.of(context).pop(),
    //                     child: const Text("OK"))
    //               ],
    //             ));
    //   }
    // }
  }

  void navigateToWeather() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => WeatherScreen()));
  }

  void navigateToTemperature() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => TemperatureScreen()));
  }

  void navigateToAlarmHistory() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => AlarmHistoryScreen()));
  }

  Future<void> refresh() async {
    _refreshState.currentState?.show();
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

  void turnOffEmergency() async {
    bool? unlocked = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => UnlockAlarm(
        qrCode: GlobalData.qrCodes
            .firstWhere((element) => element.name == "default"),
      ),
    ));
    if (unlocked != true) {
      return;
    }

    //Confirmation dialog
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wy????cz alarm"),
          content: Text(
              'Czy jeste?? pewny, ??e chcesz wy????czy?? aktualny alarm systemu przeciwawaryjnego?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wy????cz")),
          ],
        );
      },
    );

    if (confirmed != true) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog(
            "Trwa wy????czanie systemu przeciwawaryjnego...");
      },
    );
    await GlobalData.turnOffEmergency();
    Navigator.of(context).pop();
    //Refresh and re-render
    await refresh();
    setState(() {});
  }

  void displayUptimeAlert() {
    //Shows the app start date
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: const Text("Czas pracy"),
              content: Text(
                  //Remove the last space (using the replaceFirst method and a RegExp)
                  "Czas pracy to: ${pingResult!.api.uptimeText!.replaceFirst(RegExp(r"\s$"), "")}. W????czono: ${dateToDateTimeString(DateTime.now().subtract(Duration(seconds: pingResult!.api.uptime!)))}"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("OK"))
              ],
            ));
  }

  @override
  void initState() {
    super.initState();

    _intentData =
        ReceiveSharingIntent.getTextStream().listen(handleShareIntent);
    ReceiveSharingIntent.getInitialText().then(handleShareIntent);

    FirebaseMessaging.instance.getToken().then((value) {
      FirebaseMessaging.onMessageOpenedApp.listen((data) async {
        print("User clicked on message: ${data.messageId}");

        print("Fetching the data because of a notification...");
        //Fetch the data
        await GlobalData.getData();

        //When the notification has alarmId property, it means that the alarm is ringing right now
        if (data.data['alarmId'] != null) {
          print("Going to the ringing alarm screen...");
          await navigateToRingingAlarm(GlobalData.ringingAlarms.firstWhere(
              (element) => element.alarm.id == data.data['alarmId'],
              orElse: () => GlobalData.ringingNaps.firstWhere(
                  (element) => element.alarm.id == data.data['alarmId'])));
        }
      });
      FirebaseMessaging.onMessage.listen((data) async {
        print("Got new message: ${data.messageId}");

        //That's probably a ringing alarm - refresh the data
        await refresh();
      });
      GlobalData.getNotificationsStatus(value ?? "").then((areEnabled) {
        if (!areEnabled) {
          showSnackbar(context, "Ostrze??enie: powiadomienia s?? wy????czone");
        }
      });
    });
    init();
  }

  @override
  Future<void> init() async {
    await GlobalData.getData(onProgress: _updateLoadingStage);

    setState(() {
      _isLoaded = true;
      upcomingAlarms = GlobalData.upcomingAlarms;
      // qrCodeHash = GlobalData.qrCodeHash;
      ringingAlarms = GlobalData.ringingAlarms;
      ringingNaps = GlobalData.ringingNaps;
      upcomingNaps = GlobalData.upcomingNaps;
      activeSnoozes = GlobalData.activeSnoozes;
      emergencyStatus = GlobalData.emergencyStatus;
    });

    if (GlobalData.ringingAlarms.isNotEmpty ||
        GlobalData.ringingNaps.isNotEmpty) {
      await navigateToRingingAlarm(GlobalData.ringingAlarms.isNotEmpty
          ? GlobalData.ringingAlarms[0]
          : GlobalData.ringingNaps[0]);
    }
    PingResult result = await GlobalData.ping();
    if (mounted) {
      setState(() {
        pingResult = result;
      });
    }

    await GlobalData.getWeatherData();
    if (GlobalData.weather != null && mounted) {
      //Re-render the screen
      setState(() {});
    }

    await GlobalData.getCurrentTemperatureData();
    if (mounted) {
      //Re-render the screen
      setState(() {});
    }
  }

  void _updateLoadingStage(String stage) {
    setState(() {
      _currentLoadingStage = stage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return Loading(
          showText: true,
          isInitLoading: true,
          currentStage: _currentLoadingStage,
          reloadFunction: init);
    } else {
      return Scaffold(
          backgroundColor: const Color(0xFF00283F),
          body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SafeArea(
                  child: RefreshIndicator(
                      key: _refreshState,
                      onRefresh: () async {
                        await GlobalData.getData();
                        setState(() {
                          upcomingAlarms = GlobalData.upcomingAlarms;
                          // qrCodeHash = GlobalData.qrCodeHash;
                          ringingAlarms = GlobalData.ringingAlarms;
                          ringingNaps = GlobalData.ringingNaps;
                          upcomingNaps = GlobalData.upcomingNaps;
                          activeSnoozes = GlobalData.activeSnoozes;
                          emergencyStatus = GlobalData.emergencyStatus;
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
                        await GlobalData.getCurrentTemperatureData();

                        //Refetch the tracking widget data
                        _trackingWidgetKey.currentState?.refresh();
                        //Re-render the screen
                        setState(() {});
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: emergencyStatus.isEmergencyActive
                            ? Axis.horizontal
                            : Axis
                                .vertical, //A workaround to center the content in the emergency case
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: emergencyStatus.isEmergencyActive
                              ? MainAxisAlignment.center
                              : MainAxisAlignment
                                  .start, //A workaround to center the content in the emergency case
                          children: emergencyStatus.isEmergencyActive
                              ? [
                                  Container(
                                    width: MediaQuery.of(context).size.width *
                                        0.95,
                                    child: Padding(
                                      padding: EdgeInsets.all(5),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          const Logo(),
                                          Icon(Icons.error, size: 72),
                                          Text("System przeciwawaryjny aktywny",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 32,
                                                color: Colors.white,
                                              )),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: TextButton(
                                              onPressed: turnOffEmergency,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.verified_user),
                                                  Text("Wy????cz")
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: const Logo(),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: ringingAlarms.isNotEmpty
                                        ? [
                                            Section("???? Aktywne alarmy"),
                                            Carousel(
                                                height: 360,
                                                onSelect: (_) =>
                                                    navigateToRingingAlarm(
                                                        ringingAlarms.first),
                                                children:
                                                    ringingAlarms.map((e) {
                                                  return AlarmCard(
                                                      id: e.alarm.id!,
                                                      name: e.alarm.name,
                                                      hour: e.alarm.hour,
                                                      minute: e.alarm.minute,
                                                      nextInvocation: e
                                                          .alarm.nextInvocation,
                                                      isActive:
                                                          e.alarm.isActive,
                                                      isSnoozeEnabled: e.alarm
                                                          .isSnoozeEnabled,
                                                      maxTotalSnoozeDuration: e
                                                          .alarm
                                                          .maxTotalSnoozeDuration,
                                                      sound: e.alarm.sound,
                                                      isGuardEnabled: e
                                                          .alarm.isGuardEnabled,
                                                      deleteAfterRinging: e
                                                          .alarm
                                                          .deleteAfterRinging,
                                                      notes: e.alarm.notes,
                                                      isRepeating:
                                                          e.alarm.isRepeating,
                                                      repeat: e.alarm.repeat,
                                                      emergencyAlarmTimeoutSeconds: e
                                                          .alarm
                                                          .emergencyAlarmTimeoutSeconds,
                                                      qrCode: e.alarm.qrCode,
                                                      isFavorite:
                                                          e.alarm.isFavorite,
                                                      hideSwitch: true);
                                                }).toList()),
                                          ]
                                        : [],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: ringingNaps.isNotEmpty
                                        ? [
                                            Section("??? Aktywne drzemki"),
                                            Carousel(
                                                height: 360,
                                                onSelect: (_) =>
                                                    navigateToRingingAlarm(
                                                        ringingNaps.first),
                                                isNap: true,
                                                children: ringingNaps.map((e) {
                                                  return AlarmCard(
                                                      id: e.alarm.id!,
                                                      name: e.alarm.name,
                                                      hour: e.alarm.hour,
                                                      minute: e.alarm.minute,
                                                      second: e.alarm.second!,
                                                      isActive:
                                                          e.alarm.isActive,
                                                      isSnoozeEnabled: e.alarm
                                                          .isSnoozeEnabled,
                                                      maxTotalSnoozeDuration: e
                                                          .alarm
                                                          .maxTotalSnoozeDuration,
                                                      sound: e.alarm.sound,
                                                      isGuardEnabled: e
                                                          .alarm.isGuardEnabled,
                                                      deleteAfterRinging: e
                                                          .alarm
                                                          .deleteAfterRinging,
                                                      notes: e.alarm.notes,
                                                      isRepeating: false,
                                                      emergencyAlarmTimeoutSeconds: e
                                                          .alarm
                                                          .emergencyAlarmTimeoutSeconds,
                                                      qrCode: e.alarm.qrCode,
                                                      isFavorite:
                                                          e.alarm.isFavorite,
                                                      hideSwitch: true,
                                                      alarmType: AlarmType.nap);
                                                }).toList()),
                                          ]
                                        : [],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: activeSnoozes.isNotEmpty
                                        ? [
                                            Section("???? Aktywne drzemki"),
                                            Carousel(
                                                height: 320,
                                                onSelect: (_) =>
                                                    navigateToRingingAlarm(
                                                        activeSnoozes.first
                                                            .ringingAlarmInstance,
                                                        isItActuallyRinging:
                                                            false),
                                                children: activeSnoozes
                                                    .map((Snooze e) {
                                                  return SnoozeCard(
                                                    name: e.ringingAlarmInstance
                                                        .alarm.name,
                                                    invocationDate:
                                                        e.invocationDate,
                                                    maxAlarmTime: e
                                                        .ringingAlarmInstance
                                                        .maxDate!,
                                                    maxTotalSnoozeDuration: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .maxTotalSnoozeDuration,
                                                    sound: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .sound,
                                                    isGuardEnabled: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .isGuardEnabled,
                                                    deleteAfterRinging: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .deleteAfterRinging,
                                                    notes: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .notes,
                                                    isRepeating: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .isRepeating,
                                                    repeat: e
                                                        .ringingAlarmInstance
                                                        .alarm
                                                        .repeat,
                                                  );
                                                }).toList()),
                                          ]
                                        : [],
                                  ),
                                  Column(
                                    children: ringingAlarms.isEmpty &&
                                            activeSnoozes.isEmpty &&
                                            ringingNaps.isEmpty
                                        ? [
                                            Section(
                                              "??? Nadchodz??ce alarmy",
                                            ),
                                            Carousel(
                                                height: 360,
                                                onSelect: handleAlarmSelect,
                                                children:
                                                    upcomingAlarms.map((e) {
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
                                                      maxTotalSnoozeDuration: e
                                                          .maxTotalSnoozeDuration,
                                                      sound: e.sound,
                                                      isGuardEnabled:
                                                          e.isGuardEnabled,
                                                      deleteAfterRinging:
                                                          e.deleteAfterRinging,
                                                      notes: e.notes,
                                                      isRepeating:
                                                          e.isRepeating,
                                                      repeat: e.repeat,
                                                      emergencyAlarmTimeoutSeconds:
                                                          e.emergencyAlarmTimeoutSeconds,
                                                      qrCode: e.qrCode,
                                                      isFavorite: e.isFavorite,
                                                      refresh: refresh);
                                                }).toList()),
                                            Section("??? Nadchodz??ce drzemki"),
                                            Carousel(
                                                height: 360,
                                                onSelect: handleNapSelect,
                                                isNap: true,
                                                children: upcomingNaps.map((e) {
                                                  return AlarmCard(
                                                    alarmType: AlarmType.nap,
                                                    key: Key(e.id!),
                                                    id: e.id!,
                                                    name: e.name,
                                                    hour: e.hour,
                                                    minute: e.minute,
                                                    second: e.second,
                                                    nextInvocation:
                                                        e.invocationDate,
                                                    isActive: e.isActive,
                                                    isSnoozeEnabled:
                                                        e.isSnoozeEnabled,
                                                    maxTotalSnoozeDuration: e
                                                        .maxTotalSnoozeDuration,
                                                    sound: e.sound,
                                                    isGuardEnabled:
                                                        e.isGuardEnabled,
                                                    deleteAfterRinging:
                                                        e.deleteAfterRinging,
                                                    notes: e.notes,
                                                    isRepeating: false,
                                                    isFavorite: e.isFavorite,
                                                    emergencyAlarmTimeoutSeconds:
                                                        e.emergencyAlarmTimeoutSeconds,
                                                    qrCode: e.qrCode,
                                                  );
                                                }).toList()),
                                          ]
                                        : [],
                                  ),
                                  Section("???? Sen"),
                                  TrackingEntryWidget(key: _trackingWidgetKey),
                                  Section("???? Kalkulacje"),
                                  SleepCalculationsWidget(
                                    onRefresh: refresh,
                                  ),
                                  Section("???? Ochrona"),
                                  InkWell(
                                      onTap: navigateToQRCodesManager,
                                      child: GuardWidget()),
                                  Section("???? Audio"),
                                  InkWell(
                                      onTap: navigateToAudioManager,
                                      child: AudioWidget()),
                                  // Section("???? Ochrona [LEGACY]"),
                                  // Container(
                                  //     width: MediaQuery.of(context).size.width *
                                  //         0.9,
                                  //     height: 200,
                                  //     padding: const EdgeInsets.all(10),
                                  //     margin: const EdgeInsets.all(5),
                                  //     decoration: BoxDecoration(
                                  //       color: Theme.of(context).cardColor,
                                  //       borderRadius: BorderRadius.circular(5),
                                  //     ),
                                  //     child: Column(
                                  //       mainAxisAlignment:
                                  //           MainAxisAlignment.center,
                                  //       children: [
                                  //         Text(
                                  //           // qrCodeHash,
                                  //           "DEV",
                                  //           style:
                                  //               const TextStyle(fontSize: 30),
                                  //           textAlign: TextAlign.center,
                                  //         ),
                                  //         const Text("Hash kodu QR",
                                  //             style: TextStyle(fontSize: 24)),
                                  //         Row(
                                  //           mainAxisAlignment:
                                  //               MainAxisAlignment.spaceAround,
                                  //           children: [
                                  //             TextButton(
                                  //                 onPressed: generateQRCode,
                                  //                 child: Row(
                                  //                   children: const [
                                  //                     Icon(Icons.refresh),
                                  //                     Text("Wygeneruj")
                                  //                   ],
                                  //                 )),
                                  //             TextButton(
                                  //                 onPressed: printQRCode,
                                  //                 child: Row(
                                  //                   children: const [
                                  //                     Icon(Icons.print),
                                  //                     Text("Wydrukuj")
                                  //                   ],
                                  //                 )),
                                  //             TextButton(
                                  //                 onPressed: testQRCode,
                                  //                 child: Row(
                                  //                   children: const [
                                  //                     Icon(Icons.quiz),
                                  //                     Text("Przetestuj")
                                  //                   ],
                                  //                 )),
                                  //           ],
                                  //         )
                                  //       ],
                                  //     )),
                                  Container(
                                    margin: const EdgeInsets.all(10),
                                    child: Column(
                                      children: GlobalData.weather != null
                                          ? [
                                              Section("??? Pogoda"),
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
                                  Container(
                                    margin: const EdgeInsets.all(10),
                                    child: Column(
                                      children: GlobalData.weather != null
                                          ? [
                                              Section("??????? Temperatura"),
                                              InkWell(
                                                  onTap: navigateToTemperature,
                                                  child: TemperatureWidget(
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .cardColor,
                                                  ))
                                            ]
                                          : [],
                                    ),
                                  ),
                                  Section("???? Historia alarm??w"),
                                  InkWell(
                                      onTap: navigateToAlarmHistory,
                                      child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          height: 50,
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: const [
                                              Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 2),
                                                child: Icon(Icons.history),
                                              ),
                                              Text("Zobacz histori?? alarm??w",
                                                  style:
                                                      TextStyle(fontSize: 24)),
                                            ],
                                          ))),
                                  Section(
                                    "??????? Ochrona",
                                  ),
                                  EmergencyDeviceStatus(
                                    refreshEmergencyStatus: () async {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (BuildContext context) {
                                          return SimpleLoadingDialog(
                                              "Trwa pobieranie statusu systemu przeciwawaryjnego...");
                                        },
                                      );
                                      EmergencyStatus newEmergencyStatus =
                                          await GlobalData.getEmergencyStatus();
                                      Navigator.of(context).pop();
                                      setState(() {
                                        emergencyStatus:
                                        newEmergencyStatus;
                                      });
                                    },
                                  ),
                                  Section("???? Sleep as Android"),
                                  SleepAsAndroidIntegration(onRefresh: refresh),
                                  Section("?????? Ustawienia"),
                                  InkWell(
                                      onTap: navigateToSettings,
                                      child: Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.9,
                                          height: 50,
                                          padding: const EdgeInsets.all(10),
                                          margin: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).cardColor,
                                            borderRadius:
                                                BorderRadius.circular(5),
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
                                              Text("Zmie?? ustawienia",
                                                  style:
                                                      TextStyle(fontSize: 24)),
                                            ],
                                          ))),
                                  Section("???? Informacje"),
                                  Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceAround,
                                                children: [
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.9 *
                                                            0.45,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        Text(
                                                            GlobalData
                                                                .appVersion,
                                                            style: TextStyle(
                                                                fontSize: 32)),
                                                        const Text(
                                                            "Wersja aplikacji",
                                                            style: TextStyle(
                                                                fontSize: 18)),
                                                      ],
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.9 *
                                                            0.45,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceAround,
                                                      children: [
                                                        Text(
                                                            GlobalData
                                                                .appBuildNumber,
                                                            style: TextStyle(
                                                                fontSize: 32)),
                                                        const Text(
                                                            "Numer buildu",
                                                            style: TextStyle(
                                                                fontSize: 18)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceAround,
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.9 *
                                                              0.45,
                                                      child: Column(
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
                                                                isSuccess:
                                                                    pingResult
                                                                        ?.api
                                                                        .success,
                                                                delay: 0,
                                                                apiDelay:
                                                                    pingResult
                                                                        ?.api
                                                                        .delay,
                                                                serviceName:
                                                                    "API",
                                                              ),
                                                              PingResultIndicator(
                                                                isSuccess:
                                                                    pingResult
                                                                        ?.core
                                                                        .success,
                                                                delay:
                                                                    pingResult
                                                                        ?.core
                                                                        .delay,
                                                                apiDelay:
                                                                    pingResult
                                                                        ?.api
                                                                        .delay,
                                                                serviceName:
                                                                    "core",
                                                              ),
                                                              PingResultIndicator(
                                                                isSuccess:
                                                                    pingResult
                                                                        ?.audio
                                                                        .success,
                                                                delay:
                                                                    pingResult
                                                                        ?.audio
                                                                        .delay,
                                                                apiDelay:
                                                                    pingResult
                                                                        ?.api
                                                                        .delay,
                                                                serviceName:
                                                                    "audio",
                                                              ),
                                                              PingResultIndicator(
                                                                isSuccess:
                                                                    pingResult
                                                                        ?.adapter
                                                                        .success,
                                                                delay: pingResult
                                                                    ?.adapter
                                                                    .delay,
                                                                apiDelay:
                                                                    pingResult
                                                                        ?.api
                                                                        .delay,
                                                                serviceName:
                                                                    "adapter",
                                                              ),
                                                              PingResultIndicator(
                                                                isSuccess:
                                                                    pingResult
                                                                        ?.tracking
                                                                        .success,
                                                                delay: pingResult
                                                                    ?.tracking
                                                                    .delay,
                                                                apiDelay:
                                                                    pingResult
                                                                        ?.api
                                                                        .delay,
                                                                serviceName:
                                                                    "tracking",
                                                              )
                                                            ],
                                                          ),
                                                          const Text("Status",
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      18)),
                                                        ],
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width *
                                                              0.9 *
                                                              0.45,
                                                      child: InkWell(
                                                        onTap: pingResult?.api
                                                                    .uptimeText !=
                                                                null
                                                            ? displayUptimeAlert
                                                            : null,
                                                        child: Column(
                                                          children: [
                                                            Text(
                                                                pingResult?.api
                                                                            .uptimeText !=
                                                                        null
                                                                    ? pingResult!
                                                                        .api
                                                                        .uptimeText!
                                                                    : "Czekaj...",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        28)),
                                                            const Text(
                                                                "Czas pracy",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        18)),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            ],
                                          ),
                                          Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: pingResult?.timestamp !=
                                                      null
                                                  ? [
                                                      Text(
                                                          "Dane z ${dateToTimeString(pingResult!.timestamp.toLocal())}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      18)),
                                                      IconButton(
                                                        icon: const Icon(
                                                            Icons.refresh),
                                                        onPressed: () async {
                                                          //Clear the current data
                                                          setState(() {
                                                            pingResult = null;
                                                          });
                                                          PingResult
                                                              pingResultTemp =
                                                              await GlobalData
                                                                  .ping();
                                                          setState(() {
                                                            pingResult =
                                                                pingResultTemp;
                                                          });
                                                        },
                                                      )
                                                    ]
                                                  : [
                                                      const Text("??adowanie...",
                                                          style: TextStyle(
                                                              fontSize: 18))
                                                    ])
                                        ],
                                      )),
                                ],
                        ),
                      )))));
    }
  }
}

class Section extends StatelessWidget {
  final String name;
  const Section(
    this.name, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.all(5),
          child: Text(name,
              style: const TextStyle(fontSize: 24, color: Colors.white))),
    );
  }
}
