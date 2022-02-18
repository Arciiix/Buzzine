import 'package:buzzine/components/number_vertical_picker.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Wybierz czas")),
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
                  NumberVerticalPicker(
                    validator: (int newValue) {
                      if (newValue * 3600 + minute * 60 + second <=
                              widget.maxDuration &&
                          newValue * 3600 + minute * 60 + second >=
                              (widget.minDuration ?? -1)) {
                        return true;
                      }
                      return false;
                    },
                    onChanged: (int newValue) {
                      setState(() => hour = newValue);
                    },
                    initValue: hour,
                    minValue: 0,
                    maxValue: 99,
                    propertyName: "Godzina",
                  )
                ],
              ),
              Text(":"),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("M"),
                  NumberVerticalPicker(
                    validator: (int newValue) {
                      if (hour * 3600 + newValue * 60 + second <=
                              widget.maxDuration &&
                          hour * 3600 + newValue * 60 + second >=
                              (widget.minDuration ?? -1)) {
                        return true;
                      }
                      return false;
                    },
                    onChanged: (int newValue) {
                      setState(() => minute = newValue);
                    },
                    initValue: minute,
                    minValue: 0,
                    maxValue: 59,
                    propertyName: "Minuta",
                  )
                ],
              ),
              Text(":"),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("S"),
                  NumberVerticalPicker(
                    validator: (int newValue) {
                      if (hour * 3600 + minute * 60 + newValue <=
                              widget.maxDuration &&
                          hour * 3600 + minute * 60 + newValue >=
                              (widget.minDuration ?? -1)) {
                        return true;
                      }
                      return false;
                    },
                    onChanged: (int newValue) {
                      setState(() {
                        second = newValue;
                      });
                    },
                    initValue: second,
                    minValue: 0,
                    maxValue: 59,
                    propertyName: "Sekunda",
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
