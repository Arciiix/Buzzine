import 'package:buzzine/components/alarm_card.dart';
import 'package:buzzine/components/carousel.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/audio_manager.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/screens/settings.dart';
import 'package:buzzine/types/Alarm.dart';
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
  late List<Alarm> upcomingAlarms;
  late String qrCodeHash;

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

  void printQRCode() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    String serverIP = _prefs.getString("API_SERVER_IP") ??
        "http://192.168.0.107:3333"; //DEV TODO: Change the default API server IP
    await launch("$serverIP/v1/guard/printQRCode");
  }

  void generateQRCode() async {
    await GlobalData.generateQRCode();
    setState(() {
      qrCodeHash = GlobalData.qrCodeHash;
    });
  }

  @override
  void initState() {
    super.initState();

    GlobalData.getData().then((value) => {
          setState(() {
            _isLoaded = true;
            upcomingAlarms = GlobalData.upcomingAlarms;
            qrCodeHash = GlobalData.qrCodeHash;
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Loading(showText: true);
    } else {
      return Scaffold(
          body: Padding(
              padding: const EdgeInsets.all(10),
              child: SafeArea(
                  child: RefreshIndicator(
                      onRefresh: () async {
                        await GlobalData.getData();
                        setState(() {
                          upcomingAlarms = GlobalData.upcomingAlarms;
                        });
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        scrollDirection: Axis.vertical,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("Buzzine",
                                    style: TextStyle(
                                        fontSize: 48, color: Colors.white))),
                            const Padding(
                              padding: EdgeInsets.all(5),
                              child: Text("⏰ Nadchodzące alarmy",
                                  style: TextStyle(
                                      fontSize: 24, color: Colors.white)),
                            ),
                            Carousel(
                                height: 250,
                                onSelect: handleAlarmSelect,
                                children: upcomingAlarms.map((e) {
                                  return AlarmCard(
                                      id: e.id!, //TODO: Make it in a better way
                                      name: e.name,
                                      hour: e.hour,
                                      minute: e.minute,
                                      nextInvocation: e.nextInvocation,
                                      isActive: e.isActive,
                                      isSnoozeEnabled: e.isSnoozeEnabled,
                                      maxTotalSnoozeLength:
                                          e.maxTotalSnoozeLength,
                                      sound: e.sound,
                                      isGuardEnabled: e.isGuardEnabled,
                                      notes: e.notes);
                                }).toList()),
                            const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("🎵 Audio",
                                    style: TextStyle(
                                        fontSize: 24, color: Colors.white))),
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
                            const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("🔒 Ochrona",
                                    style: TextStyle(
                                        fontSize: 24, color: Colors.white))),
                            Container(
                                width: MediaQuery.of(context).size.width * 0.9,
                                height: 160,
                                padding: const EdgeInsets.all(10),
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(qrCodeHash,
                                        style: const TextStyle(fontSize: 48)),
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
                                      ],
                                    )
                                  ],
                                )),
                            const Padding(
                                padding: EdgeInsets.all(5),
                                child: Text("⚙️ Ustawienia",
                                    style: TextStyle(
                                        fontSize: 24, color: Colors.white))),
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
