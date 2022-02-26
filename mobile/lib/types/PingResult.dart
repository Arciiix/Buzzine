import 'package:buzzine/utils/formatting.dart';

class PingResult {
  DateTime timestamp = DateTime.now();
  bool error;
  ServicePing api;
  ServicePing core;
  ServicePing audio;
  ServicePing adapter;
  ServicePing tracking;

  String toString() {
    return "API: ${api.success}; core: ${core.success}; audio: ${audio.success}; adapter: ${adapter.success}; tracking: ${tracking.success}";
  }

  PingResult(
      {required this.error,
      required this.api,
      required this.core,
      required this.audio,
      required this.adapter,
      required this.tracking});
}

class ServicePing {
  bool success;
  int? delay;
  int? uptime;
  String? uptimeText;

  ServicePing({required this.success, this.delay, this.uptime}) {
    this.uptimeText = secondsToNamedString(uptime);
  }
}
