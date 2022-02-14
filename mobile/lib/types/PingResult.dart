import 'dart:developer';

class PingResult {
  DateTime timestamp = DateTime.now();
  bool error;
  ServicePing api;
  ServicePing core;
  ServicePing audio;

  String toString() {
    return "API: ${api.success}; core: ${core.success}; audio: ${audio.success}";
  }

  PingResult(
      {required this.error,
      required this.api,
      required this.core,
      required this.audio});
}

class ServicePing {
  bool success;
  int? delay;

  ServicePing({required this.success, this.delay});
}
