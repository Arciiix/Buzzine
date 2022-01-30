import 'package:buzzine/utils/validate_qr_code.dart';
import "package:flutter/material.dart";
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ScanQRCode extends StatefulWidget {
  final String targetHash;

  const ScanQRCode({Key? key, required this.targetHash}) : super(key: key);

  @override
  _ScanQRCodeState createState() => _ScanQRCodeState();
}

class _ScanQRCodeState extends State<ScanQRCode> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool _isDialogShowed = false;
  bool _isCameraFlashlightEnabled = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Skanowanie kodu QR")),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
              flex: 1,
              child: Row(children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Text(widget.targetHash,
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 24, color: Colors.white)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: Colors.transparent,
                    shape: CircleBorder(),
                    clipBehavior: Clip.hardEdge,
                    child: IconButton(
                      iconSize: 30,
                      icon: Icon(
                          _isCameraFlashlightEnabled
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.white),
                      onPressed: () async {
                        await controller?.toggleFlash();
                        setState(() {
                          _isCameraFlashlightEnabled =
                              !_isCameraFlashlightEnabled;
                        });
                      },
                    ),
                  ),
                ),
              ]))
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (!validateQRCodeFormat(scanData.code!)) {
        if (_isDialogShowed) return;
        //There's no need to rerender, so I'm not using setState
        _isDialogShowed = true;
        await showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("Błędy kod QR"),
                  content: const Text(
                      "Ten kod QR nie jest prawidłowym formatem kodu Buzzine."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"))
                  ],
                ));
        _isDialogShowed = false;
      } else {
        controller.dispose();
        Navigator.of(context).pop(scanData.code!);
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    controller?.dispose();
    super.dispose();
  }
}
