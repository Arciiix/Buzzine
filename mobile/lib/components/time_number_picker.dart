import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';

class TimeNumberPicker extends StatefulWidget {
  final int maxDuration;
  final int? initialTime;
  final int? minDuration;
  const TimeNumberPicker(
      {Key? key, required this.maxDuration, this.initialTime, this.minDuration})
      : super(key: key);

  @override
  _TimeNumberPickerState createState() => _TimeNumberPickerState();
}

class _TimeNumberPickerState extends State<TimeNumberPicker> {
  int hour = 0;
  int minute = 0;
  int second = 0;

  @override
  void initState() {
    if (widget.initialTime != null) {
      hour = (widget.initialTime! / 3600).floor();
      minute = ((widget.initialTime! % 3600) / 60).floor();
      second = ((widget.initialTime! % 3600) % 60).floor();
    }

    super.initState();
  }

  Future<int?> getValueFromUserInput(int currentValue, String unit) async {
    TextEditingController _inputController = TextEditingController()
      ..text = currentValue.toString();
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(unit),
          content: TextField(
            controller: _inputController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(hintText: unit),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () async {
                  Navigator.of(context)
                      .pop(int.tryParse(_inputController.text));
                },
                child: const Text("Zmień")),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wybierz liczbę")),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () => Navigator.of(context)
            .pop(Duration(hours: hour, minutes: minute, seconds: second)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("H"),
                  GestureDetector(
                    onTap: () async {
                      int? newValue =
                          await getValueFromUserInput(hour, "Godzina");
                      if (newValue != null) {
                        if (newValue * 3600 + minute * 60 + second <=
                                widget.maxDuration &&
                            newValue * 3600 + minute * 60 + second >=
                                (widget.minDuration ?? -1)) {
                          setState(() => hour = newValue);
                        }
                      }
                    },
                    child: NumberPicker(
                      value: hour,
                      minValue: 0,
                      maxValue: 99,
                      zeroPad: true,
                      onChanged: (value) {
                        if (value * 3600 + minute * 60 + second <=
                                widget.maxDuration &&
                            value * 3600 + minute * 60 + second >=
                                (widget.minDuration ?? -1)) {
                          setState(() => hour = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              Text(":"),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("M"),
                  GestureDetector(
                    onTap: () async {
                      int? newValue =
                          await getValueFromUserInput(minute, "Minuta");
                      if (newValue != null) {
                        if (hour * 3600 + newValue * 60 + second <=
                                widget.maxDuration &&
                            hour * 3600 + newValue * 60 + second >=
                                (widget.minDuration ?? -1)) {
                          setState(() => minute = newValue);
                        }
                      }
                    },
                    child: NumberPicker(
                      value: minute,
                      minValue: 0,
                      maxValue: 59,
                      zeroPad: true,
                      onChanged: (value) {
                        if (hour * 3600 + value * 60 + second <=
                                widget.maxDuration &&
                            hour * 3600 + value * 60 + second >=
                                (widget.minDuration ?? -1)) {
                          setState(() => minute = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
              Text(":"),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("S"),
                  GestureDetector(
                    onTap: () async {
                      int? newValue =
                          await getValueFromUserInput(second, "Sekunda");
                      if (newValue != null) {
                        if (hour * 3600 + minute * 60 + newValue <=
                                widget.maxDuration &&
                            hour * 3600 + minute * 60 + newValue >=
                                (widget.minDuration ?? -1)) {
                          setState(() => hour = newValue);
                        }
                      }
                    },
                    child: NumberPicker(
                      value: second,
                      minValue: 0,
                      maxValue: 59,
                      zeroPad: true,
                      onChanged: (value) {
                        if (hour * 3600 + minute * 60 + value <=
                                widget.maxDuration &&
                            hour * 3600 + minute * 60 + value >=
                                (widget.minDuration ?? -1)) {
                          setState(() => second = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
