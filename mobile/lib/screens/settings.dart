import 'package:buzzine/globalData.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

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
  TextEditingController _tempMuteAudioDurationController =
      TextEditingController();
  TextEditingController _APIServerIPController = TextEditingController();
  TextEditingController _audioPreviewDurationSecondsController =
      TextEditingController();
  TextEditingController _homeLatitudeController = TextEditingController();
  TextEditingController _homeLongitudeController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
          (_prefsInstance.getInt('MAX_TOTAL_SNOOZE_TIME_VALUE') ?? 60)
              .toString();
      _tempMuteAudioDurationController.text =
          (_prefsInstance.getInt('TEMP_MUTE_AUDIO_DURATION') ?? 30).toString();
      _APIServerIPController.text = _prefsInstance.getString("API_SERVER_IP") ??
          "http://192.168.0.107:1111"; //DEV TODO: Change it
      _audioPreviewDurationSecondsController.text =
          (_prefsInstance.getInt('AUDIO_PREVIEW_DURATION_SECONDS') ?? 30)
              .toString();
      _homeLatitudeController.text =
          (_prefsInstance.getDouble('HOME_LATITUDE') ?? '').toString();
      _homeLongitudeController.text =
          (_prefsInstance.getDouble('HOME_LONGITUDE') ?? '').toString();
    });
  }

  void handleSave() {
    if (_formKey.currentState!.validate()) {
      _prefsInstance.setInt("MIN_TOTAL_SNOOZE_TIME_VALUE",
          int.tryParse(_minTotalSnoozeTimeValueController.text) ?? 5);
      _prefsInstance.setInt("MAX_TOTAL_SNOOZE_TIME_VALUE",
          int.tryParse(_maxTotalSnoozeTimeValueController.text) ?? 60);
      _prefsInstance.setInt("TEMP_MUTE_AUDIO_DURATION",
          int.tryParse(_tempMuteAudioDurationController.text) ?? 30);
      _prefsInstance.setString("API_SERVER_IP", _APIServerIPController.text);
      _prefsInstance.setInt("AUDIO_PREVIEW_DURATION_SECONDS",
          int.tryParse(_audioPreviewDurationSecondsController.text) ?? 30);
      if (double.tryParse(_homeLatitudeController.text.replaceAll(",", ".")) !=
              null &&
          double.tryParse(_homeLongitudeController.text.replaceAll(",", ".")) !=
              null) {
        _prefsInstance.setDouble("HOME_LATITUDE",
            double.parse(_homeLatitudeController.text.replaceAll(",", ".")));
        _prefsInstance.setDouble("HOME_LONGITUDE",
            double.parse(_homeLongitudeController.text.replaceAll(",", ".")));
      } else {
        _prefsInstance.remove("HOME_LATITUDE");
        _prefsInstance.remove("HOME_LONGITUDE");
      }

      GlobalData.loadSettings();
      Navigator.of(context).pop();
    }
  }

  void pasteHomeCoordinates(isLatitude) async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      String? output;
      //If the data contains both latitude and longitude
      RegExp bothCoordinatesRegExp =
          RegExp(r"^-?[0-9]*(.|,)?[0-9]*,\s-?[0-9]*(.|,)?[0-9]*$");
      if (bothCoordinatesRegExp.hasMatch(data.text ?? "")) {
        List<String> coordinatesTextPieces = data.text!.split(", ");
        output = double.tryParse(coordinatesTextPieces[isLatitude ? 0 : 1]
                    .replaceAll(",", "."))
                ?.toString() ??
            "";
      } else if (double.tryParse(data.text?.replaceAll(",", ".") ?? "") !=
          null) {
        output = double.tryParse(data.text?.replaceAll(",", ".") ?? "")
                ?.toString() ??
            "";
      } else {
        showSnackbar(context, "Zły format danych!");
      }

      if (output != null) {
        setState(() {
          if (isLatitude) {
            _homeLatitudeController.text = output!;
          } else {
            _homeLongitudeController.text = output!;
          }
        });
      }
    } else {
      showSnackbar(context, "Pusty schowek!");
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
            body: SingleChildScrollView(
              child: Form(
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
                                      _prefsInstance
                                              .getString("API_SERVER_IP") ??
                                          "http://192.168.0.107:1111",
                                )),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _minTotalSnoozeTimeValueController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9]"))
                            ],
                            validator: (val) => int.tryParse(val ?? '') != null
                                ? null
                                : "Podaj poprawną liczbę całkowitą",
                            decoration: InputDecoration(
                                label: const Text(
                                    "Min. łączny czas drzemek (minuty)"),
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
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9]"))
                            ],
                            validator: (val) => int.tryParse(val ?? '') != null
                                ? null
                                : "Podaj poprawną liczbę całkowitą",
                            decoration: InputDecoration(
                                label: const Text(
                                    "Max. łączny czas drzemek (minuty)"),
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
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _tempMuteAudioDurationController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9]"))
                            ],
                            validator: (val) {
                              if (int.tryParse(val ?? '') == null ||
                                  int.tryParse(val ?? '')! < 5 ||
                                  int.tryParse(val ?? '')! > 300)
                                return "Podaj poprawną liczbę całkowitą z przedziału 5-300";
                              return null;
                            },
                            decoration: InputDecoration(
                              label: const Text(
                                  "Długość wyciszenia audio alarmu (sekundy)"),
                              hintText: "30",
                              floatingLabelBehavior:
                                  FloatingLabelBehavior.always,
                              suffix: IconButton(
                                icon: const Icon(Icons.restart_alt),
                                onPressed: () =>
                                    _tempMuteAudioDurationController
                                        .text = (_prefsInstance.getInt(
                                                'TEMP_MUTE_AUDIO_DURATION') ??
                                            30)
                                        .toString(),
                              ),
                            ),
                          ),
                          TextFormField(
                            controller: _audioPreviewDurationSecondsController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"[0-9]"))
                            ],
                            validator: (val) => int.tryParse(val ?? '') != null
                                ? null
                                : "Podaj poprawną liczbę całkowitą",
                            decoration: InputDecoration(
                                label: const Text(
                                    "Długość podglądu audio (sekundy)"),
                                hintText: "30",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                suffix: IconButton(
                                  icon: const Icon(Icons.restart_alt),
                                  onPressed: () =>
                                      _audioPreviewDurationSecondsController
                                          .text = (_prefsInstance.getInt(
                                                  'AUDIO_PREVIEW_DURATION_SECONDS') ??
                                              30)
                                          .toString(),
                                )),
                          ),
                          SizedBox(height: 20),
                          TextFormField(
                            controller: _homeLatitudeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"^-?[0-9]*(.|,)?[0-9]*$"))
                            ],
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  (double.tryParse(val.replaceAll(",", ".")) ==
                                          null ||
                                      double.parse(val.replaceAll(",", ".")) >
                                          90 ||
                                      double.parse(val.replaceAll(",", ".")) <
                                          -90 ||
                                      !RegExp(r"^-?[0-9]*(.|,)?[0-9]*$")
                                          .hasMatch(val))) {
                                return "Podaj poprawną szerokość geograficzną";
                              } else if (double.tryParse(
                                          val?.replaceAll(",", ".") ?? '') ==
                                      null &&
                                  double.tryParse(_homeLongitudeController.text
                                          .replaceAll(",", ".")) !=
                                      null) {
                                return "Podaj też szerokość geograficzną (podałeś długość)";
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                label:
                                    const Text("Lokalizacja domu - szer. geo."),
                                hintText: "",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                suffix: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.paste),
                                        onPressed: () =>
                                            pasteHomeCoordinates(true)),
                                    IconButton(
                                      icon: const Icon(Icons.restart_alt),
                                      onPressed: () => _homeLatitudeController
                                          .text = (_prefsInstance
                                                  .getDouble('HOME_LATITUDE') ??
                                              '')
                                          .toString(),
                                    ),
                                  ],
                                )),
                          ),
                          TextFormField(
                            controller: _homeLongitudeController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r"^-?[0-9]*(.|,)?[0-9]*$"))
                            ],
                            validator: (val) {
                              if (val != null &&
                                  val.isNotEmpty &&
                                  (double.tryParse(val.replaceAll(",", ".")) ==
                                          null ||
                                      double.parse(val.replaceAll(",", ".")) >
                                          180 ||
                                      double.parse(val.replaceAll(",", ".")) <
                                          -180 ||
                                      !RegExp(r"^-?[0-9]*(.|,)?[0-9]*$")
                                          .hasMatch(val))) {
                                return "Podaj poprawną długość geograficzną";
                              } else if (double.tryParse(
                                          val?.replaceAll(",", ".") ?? '') ==
                                      null &&
                                  double.tryParse(_homeLatitudeController.text
                                          .replaceAll(",", ".")) !=
                                      null) {
                                return "Podaj też długość geograficzną (podałeś szerokość)";
                              } else {
                                return null;
                              }
                            },
                            decoration: InputDecoration(
                                label:
                                    const Text("Lokalizacja domu - dł. geo."),
                                hintText: "",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                suffix: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.paste),
                                        onPressed: () =>
                                            pasteHomeCoordinates(false)),
                                    IconButton(
                                      icon: const Icon(Icons.restart_alt),
                                      onPressed: () => _homeLongitudeController
                                          .text = (_prefsInstance.getDouble(
                                                  'HOME_LONGITUDE') ??
                                              '')
                                          .toString(),
                                    ),
                                  ],
                                )),
                          ),
                          ElevatedButton(
                              onPressed: () => print(
                                  "TODO: Choose the home location from the map"),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.place),
                                  Text('Wybierz z mapy')
                                ],
                              )),
                        ],
                      ))),
            )));
  }
}
