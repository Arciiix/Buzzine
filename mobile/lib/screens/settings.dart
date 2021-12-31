import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatefulWidget {
  const Settings({Key? key}) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _isLoaded = false;
  late final SharedPreferences _prefsInstance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  TextEditingController _minTotalSnoozeTimeValueController =
      TextEditingController();
  TextEditingController _maxTotalSnoozeTimeValueController =
      TextEditingController();
  TextEditingController _APIServerIPController = TextEditingController();

  @override
  void initState() {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    _prefsInstance = await SharedPreferences.getInstance();

    setState(() {
      _isLoaded = true;
      _minTotalSnoozeTimeValueController.text =
          (_prefsInstance.getInt('MIN_TOTAL_SNOOZE_TIME_VALUE') ?? 5)
              .toString();
      _maxTotalSnoozeTimeValueController.text =
          (_prefsInstance.getInt('MAX_TOTAL_SNOOZE_TIME_VALUE') ?? 50)
              .toString();
      _APIServerIPController.text = _prefsInstance.getString("API_SERVER_IP") ??
          "http://192.168.0.107:1111"; //DEV TODO: Change it
    });
  }

  void handleSave() {
    if (_formKey.currentState!.validate()) {
      _prefsInstance.setInt("MIN_TOTAL_SNOOZE_TIME_VALUE",
          int.tryParse(_minTotalSnoozeTimeValueController.text) ?? 5);
      _prefsInstance.setInt("MAX_TOTAL_SNOOZE_TIME_VALUE",
          int.tryParse(_maxTotalSnoozeTimeValueController.text) ?? 60);
      _prefsInstance.setString("API_SERVER_IP", _APIServerIPController.text);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          bool? response = await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                    title: const Text("Czy na pewno chcesz wyjść?"),
                    content: const Text(
                        "Jeżeli zmieniłeś jakieś ustawienia, nie zostaną one zapisane - użyj przycisku zapisu, aby wyjść."),
                    actions: [
                      TextButton(
                          child: const Text("Nie"),
                          onPressed: () => Navigator.of(c).pop(false)),
                      TextButton(
                          child: const Text("Tak"),
                          onPressed: () => Navigator.of(c).pop(true)),
                    ],
                  ));
          return response ?? true;
        },
        child: Scaffold(
            appBar: AppBar(
              title: const Text("Ustawienia"),
              actions: [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: handleSave,
                )
              ],
            ),
            backgroundColor: Colors.white,
            body: Form(
                key: _formKey,
                child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _APIServerIPController,
                          validator: (val) {
                            return RegExp(
                                        r"^http(s)?:\/\/*(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]):[0-9]+$")
                                    .hasMatch(val ?? "")
                                ? null
                                : "Zły format adresu IP - pamiętaj, aby podać port i protokół (https lub http)";
                          },
                          decoration: InputDecoration(
                              label: const Text("IP API (z portem)"),
                              hintText: "http://xxx.xxx.x.x:1111",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              suffix: IconButton(
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () => _APIServerIPController.text =
                                    _prefsInstance.getString("API_SERVER_IP") ??
                                        "http://192.168.0.107:1111",
                              )),
                        ),
                        TextFormField(
                          controller: _minTotalSnoozeTimeValueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                          ],
                          validator: (val) => int.tryParse(val ?? '') != null
                              ? null
                              : "Podaj poprawną liczbę całkowitą",
                          decoration: InputDecoration(
                              label:
                                  const Text("Min. łączny czas drzemek (min)"),
                              hintText: "5",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              suffix: IconButton(
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () =>
                                    _minTotalSnoozeTimeValueController
                                        .text = (_prefsInstance.getInt(
                                                'MIN_TOTAL_SNOOZE_TIME_VALUE') ??
                                            5)
                                        .toString(),
                              )),
                        ),
                        TextFormField(
                          controller: _maxTotalSnoozeTimeValueController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r"[0-9]"))
                          ],
                          validator: (val) => int.tryParse(val ?? '') != null
                              ? null
                              : "Podaj poprawną liczbę całkowitą",
                          decoration: InputDecoration(
                              label:
                                  const Text("Max. łączny czas drzemek (min)"),
                              hintText: "60",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              suffix: IconButton(
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () =>
                                    _maxTotalSnoozeTimeValueController
                                        .text = (_prefsInstance.getInt(
                                                'MAX_TOTAL_SNOOZE_TIME_VALUE') ??
                                            60)
                                        .toString(),
                              )),
                        ),
                      ],
                    )))));
  }
}
