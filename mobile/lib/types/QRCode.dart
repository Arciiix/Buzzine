import 'package:buzzine/types/Alarm.dart';

class QRCode {
  String name;
  String hash;

  QRCode({
    required this.name,
    required this.hash,
  });

  Map<String, String> toMap() {
    return {
      'name': name,
      'hash': hash,
    };
  }
}
