import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/unlock_alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/SleepAsAndroidIntegrationStatus.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SleepAsAndroidIntegration extends StatefulWidget {
  final Function onRefresh;
  const SleepAsAndroidIntegration({Key? key, required this.onRefresh})
      : super(key: key);

  @override
  _SleepAsAndroidIntegrationState createState() =>
      _SleepAsAndroidIntegrationState();
}

class _SleepAsAndroidIntegrationState extends State<SleepAsAndroidIntegration> {
  late SleepAsAndroidIntegrationStatus _sleepAsAndroidIntegrationStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    refresh().then((value) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> refresh() async {
    SleepAsAndroidIntegrationStatus status =
        await GlobalData.getSleepAsAndroidIntegrationStatus();

    await widget.onRefresh();

    setState(() {
      _sleepAsAndroidIntegrationStatus = status;
    });
  }

  Future<Duration?> selectTimeManually(int min, int max, int init) async {
    Duration? userSelection =
        await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TimeNumberPicker(
        minDuration: min,
        maxDuration: max,
        initialTime: init,
      ),
    ));
    return userSelection;
  }

  Future<void> turnOffSleepAsAndroidAlarm() async {
    bool? unlocked = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => const UnlockAlarm(),
    ));
    if (unlocked != true) {
      return;
    }

    //Confirmation dialog
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wyłącz alarm"),
          content: Text(
              'Czy jesteś pewny, że chcesz wyłączyć alarm Sleep as Android (jeśli istnieje)?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wyłącz")),
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
            "Trwa wyłączanie alarmu Sleep as Android...");
      },
    );

    await GlobalData.toggleSleepAsAndroidCurrentAlarm(false);
    Navigator.of(context).pop();

    //Refresh and re-render
    await refresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: 130,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
                Text("Ładowanie...", style: TextStyle(fontSize: 32))
              ]));
    } else {
      return AnimatedContainer(
          width: MediaQuery.of(context).size.width * 0.9,
          height: _sleepAsAndroidIntegrationStatus.isActive ? 250 : 120,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(5),
          ),
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onLongPress: () {
                  showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                            title: const Text("Sleep as Android"),
                            content: Text(
                                'Dzięki tej integracji alarmy z aplikacji Sleep as Android będą też odtwarzane w Buzzine - kiedy nadejdzie czas na alarm, równocześnie z telefonem włączy się Buzzine z wybranym dźwiękiem oraz po pewnym (wybranym) czasie dodatkowe urządzenie.\nAby włączyć tę integrację, w Sleep as Android przejdź do ustawień, a następnie: Integrations -> Services -> Automation. W sekcji "Webhooks" zaznacz checkboxa, a w polu URL wpisz: "${GlobalData.serverIP}/v1/sleepasandroid/webhook" - czyli adres API z dodatkiem "/v1/sleepasandroid/webhook".'),
                            actions: [
                              TextButton(
                                  onPressed: () async {
                                    await Clipboard.setData(ClipboardData(
                                        text:
                                            "${GlobalData.serverIP}/v1/sleepasandroid/webhook"));
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Kopiuj URL")),
                              TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("OK"))
                            ],
                          ));
                },
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: const [
                        Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(Icons.android),
                        ),
                        Expanded(
                          child: Text("Integracja z Sleep as Android",
                              style: TextStyle(fontSize: 20),
                              overflow: TextOverflow.ellipsis),
                        )
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: const Text("Status",
                              style: TextStyle(fontSize: 17),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Switch(
                          value: _sleepAsAndroidIntegrationStatus.isActive,
                          onChanged: (value) async {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (BuildContext context) {
                                return SimpleLoadingDialog(
                                    "Trwa ${value ? "włączanie" : "wyłączanie"} integracji: Sleep as Android...");
                              },
                            );
                            await GlobalData
                                .toggleSleepAsAndroidIntegrationStatus(value);
                            Navigator.of(context).pop();
                            await refresh();
                          },
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: _sleepAsAndroidIntegrationStatus.isActive
                    ? [
                        InkWell(
                          onTap: () async {
                            Audio? selectedAudio = await Navigator.of(context)
                                .push(MaterialPageRoute(
                              builder: (context) => const AudioManager(
                                selectAudio: true,
                              ),
                            ));

                            if (selectedAudio != null) {
                              await GlobalData
                                  .changeSleepAsAndroidIntegrationSound(
                                      selectedAudio.audioId);
                              await refresh();
                            }
                          },
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                      title: const Text("Audio"),
                                      content: Text(
                                          "Audio, które zostanie odtworzone w wyniku alarmu Sleep as Android."),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("OK"))
                                      ],
                                    ));
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.music_note),
                              Flexible(
                                  child: Padding(
                                      padding: const EdgeInsets.all(5),
                                      child: Text(
                                        _sleepAsAndroidIntegrationStatus
                                                .audio.friendlyName ??
                                            "Domyślna",
                                        overflow: TextOverflow.ellipsis,
                                      )))
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            Duration? userSelection = await selectTimeManually(
                                0,
                                360000, //100 hours
                                GlobalData
                                    .sleepAsAndroidIntegrationStatus.delay);
                            if (userSelection != null) {
                              await GlobalData
                                  .changeSleepAsAndroidIntegrationDelay(
                                      userSelection.inSeconds);
                              await refresh();
                            }
                          },
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                      title: const Text("Opóźnienie"),
                                      content: Text(
                                          "Po tym czasie (format mm:ss) włączony zostanie alarm Buzzine."),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("OK"))
                                      ],
                                    ));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Icon(Icons.hourglass_empty),
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text(addZero(
                                        (_sleepAsAndroidIntegrationStatus
                                                    .delay /
                                                60)
                                            .floor()) +
                                    ":" +
                                    addZero(_sleepAsAndroidIntegrationStatus
                                        .delay
                                        .remainder(60))),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            Duration? userSelection = await selectTimeManually(
                                1,
                                GlobalData.constants.muteAfter * 60 - 1,
                                GlobalData.sleepAsAndroidIntegrationStatus
                                    .emergencyAlarmTimeoutSeconds);
                            if (userSelection != null) {
                              await GlobalData
                                  .changeSleepAsAndroidIntegrationEmergencyAlarmTimeout(
                                      userSelection.inSeconds);
                              await refresh();
                            }
                          },
                          onLongPress: () {
                            showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                      title: const Text(
                                          "Opóźnienie włączenia urządzenia"),
                                      content: Text(
                                          "Po tym czasie (format mm:ss) włączone zostanie dodatkowe urządzenie systemu przeciwawaryjnego. Druga wartość, w nawiasie, to rzeczywista wartość - po uwzględnieniu ogólnego opóźnienia."),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text("OK"))
                                      ],
                                    ));
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Icon(Icons.shield_outlined),
                              Padding(
                                padding: const EdgeInsets.all(5),
                                child: Text(addZero((_sleepAsAndroidIntegrationStatus.emergencyAlarmTimeoutSeconds / 60).floor()) +
                                    ":" +
                                    addZero(_sleepAsAndroidIntegrationStatus
                                        .emergencyAlarmTimeoutSeconds
                                        .remainder(60)) +
                                    " (" +
                                    addZero((_sleepAsAndroidIntegrationStatus.delay /
                                                60 +
                                            _sleepAsAndroidIntegrationStatus
                                                    .emergencyAlarmTimeoutSeconds /
                                                60)
                                        .floor()) +
                                    ":" +
                                    addZero(_sleepAsAndroidIntegrationStatus
                                            .delay
                                            .remainder(60) +
                                        _sleepAsAndroidIntegrationStatus
                                            .emergencyAlarmTimeoutSeconds
                                            .remainder(60)) +
                                    ")"),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              child: TextButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.stop),
                                      Text("Zatrzymaj alarm")
                                    ]),
                                onPressed: turnOffSleepAsAndroidAlarm,
                              ),
                            ),
                            Expanded(
                              child: TextButton(
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.refresh),
                                      Text("Odśwież")
                                    ]),
                                onPressed: refresh,
                              ),
                            ),
                          ],
                        ),
                      ]
                    : [],
              )
            ],
          ));
    }
  }
}
