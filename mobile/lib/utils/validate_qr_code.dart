bool validateQRCodeFormat(String data) {
  RegExp regExp = RegExp(r"^Buzzine\/[A-Za-z0-9]{8}$");

  return regExp.hasMatch(data);
}

bool validateQRCode(String data, String correctHash) {
  if (!validateQRCodeFormat(data)) return false;
  String hash = extractHashFromQRData(data);
  return hash == correctHash;
}

String extractHashFromQRData(String data) {
  return data.substring(8, 16);
}
