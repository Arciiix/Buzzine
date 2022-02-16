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

  void toogleEmergency(bool isOn) async {
    await GlobalData.toogleEmergency(isOn);
    await refreshEmergencyData();
  }

  void toogleEmergencyDevice(bool isOn) async {
    await GlobalData.toogleEmergencyDevice(isOn);
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
    });
  }

  @override
  void initState() {
    _isEmergencyEnabled = GlobalData.emergencyStatus.isEmergencyEnabled;
    _isEmergencyDeviceOn = GlobalData.emergencyStatus.isEmergencyDeviceOn;
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
        children: [
          InkWell(
            onTap: () => toogleEmergencyDevice(!_isEmergencyDeviceOn),
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
                    onChanged: toogleEmergencyDevice),
              ],
            ),
          ),
          InkWell(
            onTap: () => toogleEmergency(!_isEmergencyEnabled),
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
                Switch(value: _isEmergencyEnabled, onChanged: toogleEmergency),
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
