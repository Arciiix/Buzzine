import 'dart:math';
import 'package:buzzine/components/temperature_chart.dart';
import 'package:buzzine/components/temperature_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/TemperatureData.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';

class TemperatureScreen extends StatefulWidget {
  const TemperatureScreen({Key? key}) : super(key: key);

  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  bool _isLoaded = true;
  late DateTime _currentSelectedDate;
  late TemperatureData temperatureData;
  double leftIconOffset = 0;
  double rightIconOffset = 0;

  void selectDate() async {
    DateTime? datePickerResponse = await showDatePicker(
        context: context,
        initialDate: _currentSelectedDate,
        lastDate: DateTime.now(),
        cancelText: "Anuluj",
        confirmText: "Zatwierdź",
        helpText: "Wybierz datę",
        errorInvalidText: "Zła data",
        errorFormatText: "Zły format",
        fieldHintText: "Podaj datę",
        fieldLabelText: "Data",
        firstDate: DateTime(2022, 1, 1, 0, 0, 0));

    if (datePickerResponse != null) {
      setState(() {
        _isLoaded = false;
      });
      getTemperatureDataForDate(datePickerResponse);
    }
  }

  Future<void> getTemperatureDataForDate(DateTime date) async {
    TemperatureData? data = await GlobalData.getTemperatureDataForDate(date);
    if (data != null) {
      setState(() {
        temperatureData = data;
        _currentSelectedDate = date;
        _isLoaded = true;
      });
    } else {
      //The temperature is null - probably there's no data for the selected date
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Nie pobrano temperatury"),
            content: const Text(
                "Nie udało się pobrać temperatury dla wyznaczonej daty."),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK")),
            ],
          );
        },
      );

      setState(() {
        _isLoaded = true;
      });
    }
  }

  void dateForward() async {
    if (_currentSelectedDate
            .add(const Duration(days: 1))
            .compareTo(DateTime.now()) <=
        0) {
      getTemperatureDataForDate(
          _currentSelectedDate.add(const Duration(days: 1)));
    } else {
      showSnackbar(context, "Wybierz wcześniejszą datę");
    }
  }

  void dateBackward() async {
    getTemperatureDataForDate(
        _currentSelectedDate.subtract(const Duration(days: 1)));
  }

  @override
  void initState() {
    _currentSelectedDate = DateTime.now();
    temperatureData = GlobalData.currentTemperatureData as TemperatureData;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoaded) {
      return Theme(
        data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.white,
                displayColor: Colors.white,
                fontSizeFactor: 1.2)),
        child: Stack(
          children: [
            GestureDetector(
                onHorizontalDragEnd: (DragEndDetails details) {
                  if ((details.primaryVelocity ?? 0) > 0) {
                    dateBackward();
                  }
                  if ((details.primaryVelocity ?? 0) < 0) {
                    dateForward();
                  }
                  setState(() {
                    rightIconOffset = 0;
                    leftIconOffset = 0;
                  });
                },
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    if (details.delta.dx * details.delta.distance * 5 > 0) {
                      leftIconOffset = min(
                          details.delta.dx * details.delta.distance * 5, 20);
                      rightIconOffset = 0;
                    } else {
                      rightIconOffset = max(
                          details.delta.dx * details.delta.distance * 5, 20);
                      leftIconOffset = 0;
                    }
                  });
                },
                child: Scaffold(
                    appBar: AppBar(title: const Text("Temperatura")),
                    body: Column(
                      children: [
                        Expanded(
                          child: SafeArea(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Material(
                                        child: IconButton(
                                          icon: Icon(Icons.arrow_back,
                                              color: Theme.of(context)
                                                  .buttonTheme
                                                  .colorScheme!
                                                  .primary),
                                          onPressed: dateBackward,
                                        ),
                                      ),
                                      Expanded(
                                        child: TextButton(
                                          onPressed: selectDate,
                                          child: Text(dateToDateString(
                                              _currentSelectedDate)),
                                        ),
                                      ),
                                      Material(
                                        child: IconButton(
                                          icon: Icon(Icons.arrow_forward,
                                              color: Theme.of(context)
                                                  .buttonTheme
                                                  .colorScheme!
                                                  .primary),
                                          onPressed: dateForward,
                                        ),
                                      ),
                                    ],
                                  ),
                                  TemperatureChart(
                                      chartData: temperatureData.temperatures
                                          .map((e) => ChartData(
                                              timestamp: e.timestamp.toLocal(),
                                              value: e.value))
                                          .toList(),
                                      id: "temperatureChart"),
                                  TemperatureStatsWidget(
                                    temperatureData: temperatureData,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ))),
            AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                left: leftIconOffset - 5,
                top: MediaQuery.of(context).size.height / 2,
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: leftIconOffset > 0 ? 1 : 0,
                      child: Icon(Icons.arrow_left, size: 50)),
                )),
            AnimatedPositioned(
                duration: const Duration(milliseconds: 100),
                right: rightIconOffset - 5,
                top: MediaQuery.of(context).size.height / 2,
                child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 100),
                    opacity: rightIconOffset > 0 ? 1 : 0,
                    child: Icon(Icons.arrow_right, size: 50)))
          ],
        ),
      );
    } else {
      return Loading(showText: true);
    }
  }
}
