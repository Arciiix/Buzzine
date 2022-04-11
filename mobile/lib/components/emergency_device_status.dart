import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:flutter/material.dart';

class EmergencyDeviceStatus extends StatefulWidget {
  final Function refreshEmergencyStatus;
  const EmergencyDeviceStatus({Key? key, required this.refreshEmergencyStatus})
      : super(key: key);

  @override
  _EmergencyDeviceStatusState createState() => _EmergencyDeviceStatusState();
}

class _EmergencyDeviceStatusState extends State<EmergencyDeviceStatus> {
  bool _isLoading = false;
  late bool _isEmergencyEnabled;
  late bool _isEmergencyDeviceOn;
  bool _isError = false;

  void toggleEmergency(bool isOn) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog(
            "Trwa ${isOn ? "włączanie" : "wyłączanie"} systemu alarmowego...");
      },
    );
    await GlobalData.toggleEmergency(isOn);
    Navigator.of(context).pop();
    await refreshEmergencyData();
  }

  void toggleEmergencyDevice(bool isOn) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog(
            "Trwa ${isOn ? "włączanie" : "wyłączanie"} urządzenia systemu alarmowego...");
      },
    );
    await GlobalData.toggleEmergencyDevice(isOn);
    Navigator.of(context).pop();
    await refreshEmergencyData();
  }

  Future<void> refreshEmergencyData() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    await widget.refreshEmergencyStatus();
    setState(() {
      _isLoading = false;
      _isEmergencyEnabled = GlobalData.emergencyStatus.isEmergencyEnabled;
      _isEmergencyDeviceOn = GlobalData.emergencyStatus.isEmergencyDeviceOn;
      _isError = GlobalData.emergencyStatus.error;
    });
  }

  @override
  void initState() {
    _isEmergencyEnabled = GlobalData.emergencyStatus.isEmergencyEnabled;
    _isEmergencyDeviceOn = GlobalData.emergencyStatus.isEmergencyDeviceOn;
    _isError = GlobalData.emergencyStatus.error;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      height: 180,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _isError
            ? const [
                Icon(Icons.error_outline, size: 68),
                Text(
                  "Błąd podczas pobierania statusu",
                  style: TextStyle(fontSize: 24),
                  textAlign: TextAlign.center,
                )
              ]
            : [
                InkWell(
                  onTap: () => toggleEmergencyDevice(!_isEmergencyDeviceOn),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.power_settings_new),
                          ),
                          Text("Status urządzenia",
                              style: const TextStyle(fontSize: 17)),
                        ],
                      ),
                      Switch(
                          value: _isEmergencyDeviceOn,
                          onChanged: toggleEmergencyDevice),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => toggleEmergency(!_isEmergencyEnabled),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.verified_user),
                          ),
                          Text("Status ochrony",
                              style: const TextStyle(fontSize: 17)),
                        ],
                      ),
                      Switch(
                          value: _isEmergencyEnabled,
                          onChanged: toggleEmergency),
                    ],
                  ),
                ),
                TextButton(
                    onPressed: refreshEmergencyData,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _isLoading
                          ? [
                              Container(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator()),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  "Czekaj...",
                                ),
                              )
                            ]
                          : [Icon(Icons.refresh), Text("Odśwież")],
                    ))
              ],
      ),
    );
  }
}
