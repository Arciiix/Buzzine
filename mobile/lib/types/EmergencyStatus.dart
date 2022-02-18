class EmergencyStatus {
  bool isEmergencyActive;
  bool isEmergencyEnabled;
  bool isEmergencyDeviceOn;
  bool error;

  EmergencyStatus(
      {required this.isEmergencyActive,
      required this.isEmergencyEnabled,
      required this.isEmergencyDeviceOn,
      required this.error});
}
