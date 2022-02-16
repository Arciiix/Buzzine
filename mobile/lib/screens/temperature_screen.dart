import 'package:buzzine/components/temperature_chart.dart';
import 'package:buzzine/components/temperature_widget.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/loading.dart';
import 'package:buzzine/types/TemperatureData.dart';
import 'package:buzzine/utils/formatting.dart';
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
                          TextButton(
                            onPressed: selectDate,
                            child: Text(dateToDateString(_currentSelectedDate)),
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
            )),
      );
    } else {
      return Loading(showText: true);
    }
  }
}
