import 'dart:async';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/components/temperature_widget.dart';
import 'package:buzzine/components/weather_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/snooze_alarm.dart';
import 'package:buzzine/screens/temperature_screen.dart';
import 'package:buzzine/screens/unlock_alarm.dart';
import 'package:buzzine/screens/weather_screen.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/RingingAlarmEntity.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RingingAlarm extends StatefulWidget {
  final RingingAlarmEntity ringingAlarm;
  final bool? isItActuallyRinging;

  const RingingAlarm(
      {Key? key, required this.ringingAlarm, this.isItActuallyRinging})
      : super(key: key);

  @override
  _RingingAlarmState createState() => _RingingAlarmState();
}

class _RingingAlarmState extends State<RingingAlarm>
    with SingleTickerProviderStateMixin {
  bool _isBlinkVisible = true;
  late Timer _blinkingTimer;
  DateTime now = DateTime.now();
  late DateTime? maxAlarmTime;
  late Duration remainingTime;
  late Timer _remainingTimeTimer;
  late bool isSnoozeAvailable;

  int tempMuteAudioDuration = 30;
  bool didMuteAudio = false;

  double initOffset = 0;
  double swipeHeight = 0;
  late AnimationController _animationController;
  late CurvedAnimation _animation;

  Future<bool> onDismiss(DismissDirection direction) async {
    if (direction == DismissDirection.startToEnd) {
      if (!isSnoozeAvailable) {
        return false;
      }
      //If no snooze is left
      if (remainingTime.inSeconds <= 0) {
        return false;
      }
      //If any ringing alarm is protected, ask for the QR code
      List<Alarm>? protectedAlarm = GlobalData.ringingAlarms
          .where((element) => element.alarm.isGuardEnabled)
          .map((e) => e.alarm)
          .toList();
      if (protectedAlarm.isNotEmpty ||
          widget.ringingAlarm.alarm.isGuardEnabled) {
        bool? unlocked = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => UnlockAlarm(qrCode: protectedAlarm[0].qrCode),
        ));
        if (unlocked != true) {
          return false;
        }
      }

      int? snoozeDuration = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SnoozeAlarm(
            leftSnooze: remainingTime.inSeconds,
            alarmInstance: widget.ringingAlarm),
      ));

      if (snoozeDuration != null && snoozeDuration != 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return SimpleLoadingDialog("Trwa w????czanie drzemki...");
          },
        );
        bool didSnooze = await GlobalData.snoozeAlarm(
            widget.ringingAlarm.alarm.id!, snoozeDuration);
        Navigator.of(context).pop();
        if (didSnooze) {
          Navigator.of(context).pop();
        }
      }

      return false;
    } else {
      //If any ringing alarm is protected, ask for the QR code
      List<Alarm>? protectedAlarm = [
        ...GlobalData.ringingAlarms
            .where((element) => element.alarm.isGuardEnabled)
            .map((e) => e.alarm)
            .toList(),
        ...GlobalData.ringingNaps
            .where((element) => element.alarm.isGuardEnabled)
            .map((e) => e.alarm)
            .toList()
      ];
      if (protectedAlarm.isNotEmpty ||
          widget.ringingAlarm.alarm.isGuardEnabled) {
        bool? unlocked = await Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => UnlockAlarm(qrCode: protectedAlarm[0].qrCode),
        ));
        if (unlocked != true) {
          return false;
        }
      }

      bool turnOff = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Wy????cz alarm"),
            content: const Text('Czy na pewno chcesz wy????czy?? alarm?'),
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
      if (turnOff) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return SimpleLoadingDialog("Trwa wy????czanie alarm??w...");
          },
        );
        await GlobalData.cancelAllAlarms();
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
      return false;
    }
  }

  void getMuteDuration() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      tempMuteAudioDuration = _prefs.getInt('TEMP_MUTE_AUDIO_DURATION') ?? 30;
    });
  }

  Future<void> tempMuteAlarm() async {
    if (didMuteAudio || widget.isItActuallyRinging == false) return;
    bool? shouldMuteAudio = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Wycisz alarm"),
          content: Text(
              'Czy na pewno chcesz jednorazowo wyciszy?? audio na ${tempMuteAudioDuration.toString()} sekund?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wycisz")),
          ],
        );
      },
    );
    //It could be null
    if (shouldMuteAudio == true) {
      setState(() {
        didMuteAudio = true;
      });
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa wyciszanie audio...");
        },
      );
      bool isAudioMuted = await GlobalData.muteAudio(tempMuteAudioDuration);
      Navigator.of(context).pop();
      if (!isAudioMuted) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("B????d"),
                  content: const Text(
                      "Nie uda??o si?? wyciszy?? audio - prawdopodobnie zosta??o ono ju?? wcze??niej wyciszone."),
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

  void navigateToTemperature() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => TemperatureScreen()));
  }

  @override
  void initState() {
    super.initState();

    maxAlarmTime = widget.ringingAlarm.maxDate;
    remainingTime = Duration(
        seconds: maxAlarmTime?.difference(now).inSeconds ??
            widget.ringingAlarm.alarm.maxTotalSnoozeDuration ??
            300);
    isSnoozeAvailable = widget.isItActuallyRinging == false
        ? false
        : widget.ringingAlarm.alarm.isSnoozeEnabled ?? false;
    _blinkingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _isBlinkVisible = !_isBlinkVisible);
    });

    _remainingTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        remainingTime = Duration(seconds: remainingTime.inSeconds - 1);
      });
      if (remainingTime.inSeconds <= 0) {
        setState(() {
          isSnoozeAvailable = false;
          _remainingTimeTimer.cancel();
        });
      }
    });

    _animationController =
        AnimationController(duration: Duration(seconds: 2), vsync: this);
    _animation = CurvedAnimation(
        parent: _animationController,
        curve: Interval(0, 0.2, curve: Curves.decelerate));
    _animationController.repeat(reverse: true);

    //Re-render on every animation state change
    _animation.addListener(() {
      setState(() {});
    });

    getMuteDuration();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: (e) => setState(() {
                initOffset = e.globalPosition.dy;
              }),
          onVerticalDragUpdate: (e) => setState(() {
                swipeHeight = (initOffset - e.globalPosition.dy) * 0.5;
              }),
          onVerticalDragEnd: (e) {
            //If user has dragged to at least half the screen size
            if (swipeHeight > MediaQuery.of(context).size.height / 5) {
              tempMuteAlarm();
            }
            setState(() {
              swipeHeight = 0;
            });
          },
          onVerticalDragCancel: () => setState(() {
                swipeHeight = 0;
              }),
          child: Stack(
            children: [
              Dismissible(
                key: const Key("RINGING_ALARM"),
                confirmDismiss: onDismiss,
                background: Scaffold(
                    body: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        padding: EdgeInsets.only(left: 20),
                        color: isSnoozeAvailable ? Colors.blue : Colors.grey,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Row(children: const [
                          Icon(Icons.snooze, color: Colors.white),
                          Text("Drzemka", style: TextStyle(color: Colors.white))
                        ])),
                    Container(
                        padding: EdgeInsets.only(right: 20),
                        color: Colors.red,
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Icon(Icons.delete, color: Colors.white),
                              Text("Wy????cz",
                                  style: TextStyle(color: Colors.white))
                            ])),
                  ],
                )),
                child: Scaffold(
                  backgroundColor: Colors.black,
                  body: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 15),
                            padding: EdgeInsets.all(8),
                            child: Row(children: [
                              Expanded(
                                  child: SafeArea(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    AnimatedOpacity(
                                      opacity: _isBlinkVisible ? 1.0 : 0.0,
                                      duration:
                                          const Duration(milliseconds: 100),
                                      child: Column(
                                        children: [
                                          Text(
                                              "${addZero(now.hour)}:${addZero(now.minute)}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 72)),
                                          Text(
                                              "${addZero(now.day)}.${addZero(now.month)}.${now.year}",
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24)),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      widget.ringingAlarm.alarm.name ?? "Alarm",
                                      style: const TextStyle(fontSize: 32),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      widget.ringingAlarm.alarm.notes ?? "",
                                      style: const TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          children: isSnoozeAvailable
                                              ? [
                                                  const Text(
                                                      "Zu??yty czas drzemek",
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18)),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(vertical: 5),
                                                    child:
                                                        LinearProgressIndicator(
                                                      value: 1 -
                                                          (remainingTime
                                                                  .inSeconds /
                                                              (widget
                                                                      .ringingAlarm
                                                                      .alarm
                                                                      .maxTotalSnoozeDuration ??
                                                                  300)),
                                                      minHeight: 20,
                                                    ),
                                                  ),
                                                  Text(
                                                      remainingTime.inSeconds >
                                                              0
                                                          ? "${addZero(remainingTime.inMinutes)}:${addZero(remainingTime.inSeconds.remainder(60))}"
                                                          : "Brak",
                                                      style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 18))
                                                ]
                                              : [],
                                        )),
                                    Column(
                                      children: GlobalData.weather != null
                                          ? [
                                              InkWell(
                                                onTap: navigateToWeather,
                                                child: Hero(
                                                  tag: "WEATHER_WIDGET",
                                                  child: WeatherWidget(
                                                    backgroundColor:
                                                        Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    InkWell(
                                        onTap: navigateToTemperature,
                                        child: TemperatureWidget(
                                          backgroundColor: Colors.black,
                                        )),
                                  ],
                                ),
                              )),
                            ]),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(
                            bottom: swipeHeight / 2 +
                                (MediaQuery.of(context).size.height /
                                    50 *
                                    (1 - _animation.value)) +
                                10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: didMuteAudio ||
                                  widget.isItActuallyRinging == false
                              ? []
                              : [
                                  const Icon(Icons.keyboard_arrow_up,
                                      color: Colors.white),
                                  Text("Wycisz",
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 15))
                                ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: 15,
                    child: DecoratedBox(
                        decoration: BoxDecoration(
                            color:
                                isSnoozeAvailable ? Colors.blue : Colors.grey,
                            borderRadius: BorderRadius.only(
                                topRight: Radius.circular(5),
                                bottomRight: Radius.circular(5))))),
              ),
              Positioned(
                right: 0,
                child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    width: 15,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(5),
                              bottomLeft: Radius.circular(5))),
                    )),
              ),
            ],
          )),
    );
  }

  @override
  void dispose() {
    _blinkingTimer.cancel();
    _remainingTimeTimer.cancel();
    _animationController.dispose();
    super.dispose();
  }
}
