import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/tracking_screen.dart';
import 'package:buzzine/types/TrackingEntry.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class TrackingEntryWidget extends StatefulWidget {
  const TrackingEntryWidget({Key? key}) : super(key: key);

  @override
  _TrackingEntryWidgetState createState() => _TrackingEntryWidgetState();
}

class _TrackingEntryWidgetState extends State<TrackingEntryWidget> {
  bool _isLoaded = false;
  late TrackingEntry _currentEntry;

  Future<void> getLatestEntry() async {
    TrackingEntry latestEntry = await GlobalData.getLatestTrackingEntry();
    setState(() {
      _currentEntry = latestEntry;
    });
  }

  Future<void> navigateToTrackingScreen() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TrackingScreen(
        initDate: _currentEntry.date!,
      ),
    ));

    setState(() {
      _isLoaded = false;
    });
    await getLatestEntry();
    setState(() {
      _isLoaded = true;
    });
  }

  @override
  void initState() {
    getLatestEntry().then((value) => setState(() => _isLoaded = true));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: navigateToTrackingScreen,
            child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(5),
                ),
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.all(5),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.bed, size: 16),
                                  ),
                                  Text("W łóżku",
                                      style: TextStyle(fontSize: 16))
                                ],
                              ),
                              Text(
                                  _currentEntry.bedTime == null
                                      ? "-"
                                      : dateToTimeString(_currentEntry.bedTime!,
                                          excludeSeconds: true),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.bedtime, size: 16),
                                  ),
                                  Text("Pójście spać",
                                      style: TextStyle(fontSize: 16))
                                ],
                              ),
                              Text(
                                  _currentEntry.sleepTime == null
                                      ? "-"
                                      : dateToTimeString(
                                          _currentEntry.sleepTime!,
                                          excludeSeconds: true),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.alarm, size: 16),
                                  ),
                                  Text("Pierwszy budzik",
                                      style: TextStyle(fontSize: 16))
                                ],
                              ),
                              Text(
                                  _currentEntry.firstAlarmTime == null
                                      ? "-"
                                      : dateToTimeString(
                                          _currentEntry.firstAlarmTime!,
                                          excludeSeconds: true),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          ),
                          Column(
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.timer, size: 16),
                                  ),
                                  Text("Obudzenie się",
                                      style: TextStyle(fontSize: 16))
                                ],
                              ),
                              Text(
                                  _currentEntry.wakeUpTime == null
                                      ? "-"
                                      : dateToTimeString(
                                          _currentEntry.wakeUpTime!,
                                          excludeSeconds: true),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          )
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Column(
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.stop, size: 16),
                                  ),
                                  Text("Wstanie",
                                      style: TextStyle(fontSize: 16))
                                ],
                              ),
                              Text(
                                  _currentEntry.getUpTime == null
                                      ? "-"
                                      : dateToTimeString(
                                          _currentEntry.getUpTime!,
                                          excludeSeconds: true),
                                  style: const TextStyle(fontSize: 24))
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: const [
                                  Padding(
                                    padding: EdgeInsets.all(2),
                                    child: Icon(Icons.star, size: 16),
                                  ),
                                  Text("Ocena", style: TextStyle(fontSize: 16))
                                ],
                              ),
                              if (_currentEntry.rate == null)
                                Text("-")
                              else
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: SizedBox(
                                          width: 100,
                                          child: LinearProgressIndicator(
                                              value: _currentEntry.rate! / 10)),
                                    ),
                                    Text(_currentEntry.rate!.toString())
                                  ],
                                ),
                            ],
                          )
                        ],
                      ),
                      SizedBox(
                        height: 80,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.subject),
                                const Text("Notka",
                                    style: TextStyle(fontSize: 16)),
                              ],
                            ),
                            Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: _currentEntry.notes == null ||
                                        _currentEntry.notes == " "
                                    ? [
                                        Text(
                                          "-",
                                          textAlign: TextAlign.center,
                                        ),
                                      ]
                                    : [
                                        Flexible(
                                            child: Text(
                                          _currentEntry.notes!,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ))
                                      ]),
                          ],
                        ),
                      ),
                      Text(_currentEntry.date!.hour == 0 &&
                              _currentEntry.date!.minute == 0
                          ? dateToDateString(_currentEntry.date!)
                          : dateToDateTimeString(_currentEntry.date!))
                    ],
                  ),
                )),
          ));
    } else {
      return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(5),
            ),
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.all(5),
            child: Column(
              children: const [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                Text("Ładowanie...", style: TextStyle(fontSize: 24))
              ],
            ),
          ));
    }
  }
}
