import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/scan_qr_code.dart';
import 'package:buzzine/types/QRCode.dart';
import 'package:buzzine/utils/validate_qr_code.dart';
import "package:flutter/material.dart";

class UnlockAlarm extends StatefulWidget {
  final QRCode qrCode;
  const UnlockAlarm({Key? key, required this.qrCode}) : super(key: key);

  @override
  _UnlockAlarmState createState() => _UnlockAlarmState();
}

class _UnlockAlarmState extends State<UnlockAlarm> {
  TextEditingController _inputController = TextEditingController();

  final GlobalKey<FormFieldState> _fieldKey = GlobalKey<FormFieldState>();

  void navigateToScanningQR() async {
    String? scannedData = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ScanQRCode(targetName: widget.qrCode.name)));

    if (scannedData != null) {
      _inputController.text = extractHashFromQRData(scannedData);

      handleAccept();
    }
  }

  void handleAccept() {
    if (_fieldKey.currentState!.validate()) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData.dark(),
        child: Scaffold(
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.check),
              onPressed: handleAccept,
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.qrCode.name,
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    TextFormField(
                      controller: _inputController,
                      key: _fieldKey,
                      validator: (value) {
                        return value == widget.qrCode.hash ? null : "Zły hash";
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Podaj hash powyższego kodu',
                      ),
                    ),
                    OutlinedButton(
                        onPressed: navigateToScanningQR,
                        child: Row(children: const [
                          Icon(Icons.qr_code),
                          Text("Skanuj")
                        ])),
                  ],
                ),
              ),
            )));
  }
}
