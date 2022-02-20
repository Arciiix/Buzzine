import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:buzzine/components/number_vertical_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/select_on_map.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
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
  final GlobalKey<FormFieldState> _homeLatitudeKey =
      GlobalKey<FormFieldState>();
  final GlobalKey<FormFieldState> _homeLongitudeKey =
      GlobalKey<FormFieldState>();

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
  TextEditingController _weatherHoursCountController = TextEditingController();

  RangeValues _temperatureRange = RangeValues(19, 24);

  FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  bool? _isMessagingEnabled;
  String? _notificationsToken;

  Future<double?> selectNumberFromPicker(double min, double max, double init,
      String quantityName, String unit) async {
    int selectedValue = init.floor();
    int selectedValueFracionalValue = getFirstDecimalPlaceOfNumber(init);
    bool? change = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Zmień ${quantityName.toLowerCase()}"),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                NumberVerticalPicker(
                  onChanged: (int val) => selectedValue = val,
                  initValue: selectedValue,
                  minValue: min.floor(),
                  maxValue: max.floor(),
                  propertyName: quantityName + " ($unit)",
                ),
                Text("."),
                NumberVerticalPicker(
                  onChanged: (int val) => selectedValueFracionalValue = val,
                  initValue: selectedValueFracionalValue,
                  minValue: 0,
                  maxValue: 9,
                  propertyName: quantityName + " ($unit)",
                ),
                Text(unit)
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Anuluj"),
              ),
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Zmień")),
            ],
          );
        });

    if (change == true &&
        selectedValue + selectedValueFracionalValue / 10 > min &&
        selectedValue + selectedValueFracionalValue / 10 < max) {
      return selectedValue + selectedValueFracionalValue / 10;
    }
  }

  Future<void> getNotificationsStatus() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Czekaj..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              Text(
                "Trwa pobieranie statusu powiadomień...",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );

    await requestNotificationPermission();

    String? token = await _firebaseMessaging.getToken();
    print("GOT TOKEN: $token");
    if (token == null) {
      //The current context is the AlertDialog, so exit it.
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Błąd"),
            content: Text(
                'Wystąpił nieoczekiwany błąd podczas pobierania tokenu FCM'),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("OK")),
            ],
          );
        },
      );
      return;
    }
    bool isMessagingEnabled = await GlobalData.getNotificationsStatus(token);
    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();

    setState(() {
      _notificationsToken = token;
      _isMessagingEnabled = isMessagingEnabled;
    });
  }

  Future<void> toogleNotifications(bool isTurnedOn) async {
    await GlobalData.toogleNotifications(isTurnedOn, _notificationsToken!);
    setState(() {
      _isMessagingEnabled = !_isMessagingEnabled!;
    });
  }

  Future<void> testNotifications() async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Testowe powiadomienie"),
          content: Text(
              'Czy na pewno chcesz wysłać testowe powiadomienie? Uwaga: Aby sprawdzić, czy wszystko działa, po zatwierdzeniu tego komunikatu musisz wyjść szybko z aplikacji - do ekranu głównego!'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wyślij")),
          ],
        );
      },
    );

    if (confirmed == true) {
      await GlobalData.sendTestNotification(_notificationsToken!);
    }
  }

  Future<void> requestNotificationPermission() async {
    bool isGranted = await AwesomeNotifications().isNotificationAllowed();
    print("Is notification permission granted: $isGranted");
    while (!isGranted) {
      isGranted = await AwesomeNotifications()
          .requestPermissionToSendNotifications(permissions: [
        NotificationPermission.Alert,
        NotificationPermission.CriticalAlert,
        NotificationPermission.PreciseAlarms,
        NotificationPermission.Provisional,
        NotificationPermission.Sound,
      ]);
    }
  }

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
      _weatherHoursCountController.text =
          (_prefsInstance.getInt('WEATHER_HOURS_COUNT') ?? 24).toString();
      _temperatureRange = RangeValues(
          (_prefsInstance.getDouble('TEMPERATURE_RANGE_START') ?? 19),
          _prefsInstance.getDouble('TEMPERATURE_RANGE_END') ?? 24);
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
      _prefsInstance.setInt("WEATHER_HOURS_COUNT",
          int.tryParse(_weatherHoursCountController.text) ?? 24);

      _prefsInstance.setDouble(
          "TEMPERATURE_RANGE_START", _temperatureRange.start);
      _prefsInstance.setDouble("TEMPERATURE_RANGE_END", _temperatureRange.end);

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

  void chooseHomeOnMap() async {
    if (!_homeLatitudeKey.currentState!.validate() ||
        !_homeLongitudeKey.currentState!.validate()) {
      return;
    }

    LatLng? previousPosition;

    if (double.tryParse(_homeLatitudeController.text.replaceAll(",", ".")) !=
            null &&
        double.tryParse(_homeLongitudeController.text.replaceAll(",", ".")) !=
            null) {
      previousPosition = LatLng(
          double.parse(_homeLatitudeController.text.replaceAll(",", ".")),
          double.parse(_homeLongitudeController.text.replaceAll(",", ".")));
    }

    LatLng? selectedPoint = await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => SelectOnMap(
        previousPosition: previousPosition,
      ),
    ));

    if (selectedPoint != null) {
      setState(() {
        _homeLatitudeController.text = selectedPoint.latitude.toString();
        _homeLongitudeController.text = selectedPoint.longitude.toString();
      });
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
            backgroundColor: Theme.of(context).cardColor,
            body: Scrollbar(
              child: SingleChildScrollView(
                child: Form(
                    key: _formKey,
                    child: Padding(
                        padding: EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionTitle(
                              "Ogólne",
                              withoutPadding: true,
                            ),
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
                                    onPressed: () => _APIServerIPController
                                        .text = _prefsInstance
                                            .getString("API_SERVER_IP") ??
                                        "http://192.168.0.107:1111",
                                  )),
                            ),
                            SectionTitle("Drzemki"),
                            TextFormField(
                              controller: _minTotalSnoozeTimeValueController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"[0-9]"))
                              ],
                              validator: (val) =>
                                  int.tryParse(val ?? '') != null
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
                              validator: (val) =>
                                  int.tryParse(val ?? '') != null
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
                            SectionTitle("Audio"),
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
                              controller:
                                  _audioPreviewDurationSecondsController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"[0-9]"))
                              ],
                              validator: (val) =>
                                  int.tryParse(val ?? '') != null
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
                            SectionTitle("Pogoda"),
                            TextFormField(
                              controller: _homeLatitudeController,
                              key: _homeLatitudeKey,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"^-?[0-9]*(.|,)?[0-9]*$"))
                              ],
                              validator: (val) {
                                if (val != null &&
                                    val.isNotEmpty &&
                                    (double.tryParse(
                                                val.replaceAll(",", ".")) ==
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
                                    double.tryParse(_homeLongitudeController
                                            .text
                                            .replaceAll(",", ".")) !=
                                        null) {
                                  return "Podaj też szerokość geograficzną (podałeś długość)";
                                } else {
                                  return null;
                                }
                              },
                              decoration: InputDecoration(
                                  label: const Text(
                                      "Lokalizacja domu - szer. geo."),
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
                                            .text = (_prefsInstance.getDouble(
                                                    'HOME_LATITUDE') ??
                                                '')
                                            .toString(),
                                      ),
                                    ],
                                  )),
                            ),
                            TextFormField(
                              controller: _homeLongitudeController,
                              key: _homeLongitudeKey,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"^-?[0-9]*(.|,)?[0-9]*$"))
                              ],
                              validator: (val) {
                                if (val != null &&
                                    val.isNotEmpty &&
                                    (double.tryParse(
                                                val.replaceAll(",", ".")) ==
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
                                        onPressed: () =>
                                            _homeLongitudeController.text =
                                                (_prefsInstance.getDouble(
                                                            'HOME_LONGITUDE') ??
                                                        '')
                                                    .toString(),
                                      ),
                                    ],
                                  )),
                            ),
                            ElevatedButton(
                                onPressed: chooseHomeOnMap,
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Theme.of(context).primaryColor)),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.place),
                                    Text('Wybierz z mapy')
                                  ],
                                )),
                            TextFormField(
                              controller: _weatherHoursCountController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r"[0-9]"))
                              ],
                              validator: (val) {
                                if (int.tryParse(val ?? '') == null) {
                                  return "Podaj poprawną liczbę całkowitą";
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                label: const Text(
                                    "Ilość godzin w pogodzie (0 = brak limitu)"),
                                hintText: "24",
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                suffix: IconButton(
                                  icon: const Icon(Icons.restart_alt),
                                  onPressed: () => _weatherHoursCountController
                                      .text = (_prefsInstance
                                              .getInt('WEATHER_HOURS_COUNT') ??
                                          24)
                                      .toString(),
                                ),
                              ),
                            ),
                            SectionTitle("Temperatura"),
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text("Idealny zakres",
                                  style: TextStyle(
                                      color: Theme.of(context).hintColor,
                                      fontSize: 12)),
                            ),
                            RangeSlider(
                                values: _temperatureRange,
                                min: 15,
                                max: 30,
                                onChanged: (RangeValues newValues) {
                                  setState(() {
                                    _temperatureRange = RangeValues(
                                      double.parse(
                                          newValues.start.toStringAsFixed(1)),
                                      double.parse(
                                          newValues.end.toStringAsFixed(1)),
                                    );
                                  });
                                }),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                InkWell(
                                    onTap: () async {
                                      double? userSelection =
                                          await selectNumberFromPicker(
                                              15,
                                              _temperatureRange.end,
                                              _temperatureRange.start,
                                              "Min. temperatura",
                                              "°C");

                                      if (userSelection != null) {
                                        setState(() {
                                          _temperatureRange = RangeValues(
                                              userSelection,
                                              _temperatureRange.end);
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                          _temperatureRange.start.toString()),
                                    )),
                                InkWell(
                                    onTap: () async {
                                      double? userSelection =
                                          await selectNumberFromPicker(
                                              _temperatureRange.start,
                                              30,
                                              _temperatureRange.end,
                                              "Max. temperatura",
                                              "°C");

                                      if (userSelection != null) {
                                        setState(() {
                                          _temperatureRange = RangeValues(
                                              _temperatureRange.start,
                                              userSelection);
                                        });
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text(
                                          _temperatureRange.end.toString()),
                                    )),
                              ],
                            ),
                            SectionTitle("Powiadomienia"),
                            Column(
                              children: _isMessagingEnabled != null
                                  ? [
                                      InkWell(
                                        onTap: () => toogleNotifications(
                                            !_isMessagingEnabled!),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.max,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text("Status"),
                                              Switch(
                                                  value: _isMessagingEnabled!,
                                                  onChanged:
                                                      toogleNotifications),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextButton(
                                                child: Text("Odśwież status"),
                                                onPressed:
                                                    getNotificationsStatus,
                                              ),
                                            ),
                                            if (_isMessagingEnabled == true)
                                              Expanded(
                                                child: TextButton(
                                                    child: const Text(
                                                        "Przetestuj"),
                                                    onPressed:
                                                        testNotifications),
                                              ),
                                          ])
                                    ]
                                  : [
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          child: Text("Pobierz status"),
                                          onPressed: getNotificationsStatus,
                                        ),
                                      )
                                    ],
                            )
                          ],
                        ))),
              ),
            )));
  }
}

class SectionTitle extends StatelessWidget {
  final String name;
  final bool? withoutPadding;
  const SectionTitle(this.name, {Key? key, this.withoutPadding})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          withoutPadding == true ? EdgeInsets.all(0) : EdgeInsets.only(top: 20),
      child: Text(name,
          style: TextStyle(
              color: Theme.of(context).textTheme.headline1?.color,
              fontWeight: FontWeight.bold)),
    );
  }
}
