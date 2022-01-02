bool validateQRCodeFormat(String data) {
  RegExp regExp = RegExp(r"^Buzzine\/[A-Za-z0-9]{8}$");

  return regExp.hasMatch(data);
}

bool validateQRCode(String data, String correctHash) {
  if (!validateQRCodeFormat(data)) return false;
  String hash = data.substring(8, 16);
  return hash == correctHash;
}
