import 'dart:async';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/cut_audio.dart';
import 'package:buzzine/screens/download_YouTube_audio.dart';
import 'package:buzzine/screens/fade_effect.dart';
import 'package:buzzine/screens/nap_list.dart';
import 'package:buzzine/screens/scan_qr_code.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/types/QRCode.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/validate_qr_code.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class QRCodesManager extends StatefulWidget {
  final bool selectCode;

  const QRCodesManager({Key? key, required this.selectCode}) : super(key: key);

  @override
  _QRCodesManagerState createState() => _QRCodesManagerState();
}

class _QRCodesManagerState extends State<QRCodesManager> {
  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  late List<QRCode> codes;

  void addCode() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa tworzenie kodu...");
      },
    );
    await GlobalData.generateQRCode();
    Navigator.of(context).pop();
    setState(() {
      codes = GlobalData.qrCodes;
    });
  }

  void deleteCode(QRCode e) async {
    if (e.name == "default") return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa usuwanie kodu...");
      },
    );

    await GlobalData.deleteQRCode(e.name);

    Navigator.of(context).pop();
    setState(() {
      codes = GlobalData.qrCodes;
    });
  }

  void selectCode(QRCode e) {
    if (widget.selectCode) {
      Navigator.of(context).pop(e);
    }
  }

  void changeCodeName(QRCode code) async {
    if (code.name == "default")
      return; // Default QR code's name cannot be changed
    TextEditingController _qrCodeNameTextFieldController =
        TextEditingController()..text = code.name;
    final GlobalKey<FormFieldState> _qrCodeTextFieldKey =
        GlobalKey<FormFieldState>();
    String? _qrCodeInputError = null;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Zmień nazwę kodu"),
          content: TextFormField(
            controller: _qrCodeNameTextFieldController,
            key: _qrCodeTextFieldKey,
            textCapitalization: TextCapitalization.sentences,
            validator: (String? value) {
              if (_qrCodeNameTextFieldController.text != code.name) {
                if (_qrCodeNameTextFieldController.text.isEmpty) {
                  return "Nazwa kodu nie może być pusta";
                }
                if (_qrCodeNameTextFieldController.text == "default") {
                  return 'Nazwą kodu nie może być "default"';
                }

                if (_qrCodeNameTextFieldController.text.length > 30) {
                  return 'Nazwa kodu nie może być dłuższa niż 30 znaków';
                }
              }
              return null;
            },
            decoration: InputDecoration(
                hintText: "Nazwa kodu", errorText: _qrCodeInputError),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () async {
                  if (_qrCodeTextFieldKey.currentState!.validate()) {
                    if (_qrCodeNameTextFieldController.text == code.name) {
                      Navigator.of(context).pop();
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return SimpleLoadingDialog("Trwa zmiana nazwy kodu...");
                      },
                    );

                    await GlobalData.changeQRCodeName(
                        code.name, _qrCodeNameTextFieldController.text);
                    await _refreshState.currentState?.show();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Zmień")),
          ],
        );
      },
    );
  }

  void showAlarmsWithCode(QRCode code) async {
    bool? showAlarms = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Zobacz powiązania"),
          content: Text('Wybierz, co chcesz zobaczyć'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Drzemki"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Alarmy")),
          ],
        );
      },
    );
    if (showAlarms == true) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            AlarmList(filter: (Alarm e) => e.qrCode.name == code.name),
      ));

      await _refreshState.currentState?.show();
    } else if (showAlarms == false) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            NapList(filter: (Nap e) => e.qrCode.name == code.name),
      ));

      await _refreshState.currentState?.show();
    }
  }

  Future<void> printQRCode(QRCode code) async {
    await launch("${GlobalData.serverIP}/v1/guard/${code.name}/print");
  }

  Future<void> testQRCode(QRCode code) async {
    String? result = await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ScanQRCode(targetName: code.name)));

    if (result != null) {
      if (validateQRCode(result, code.hash)) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("Prawidłowy kod QR"),
                  content: Text(
                      "Ten kod QR jest prawidłowym kodem o nazwie \"${code.name}\". Możesz go używać do wyłączania alarmu."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"))
                  ],
                ));
      } else {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text("Błędy kod QR"),
                  content: Text(
                      "Ten kod QR nie jest prawidłowym kodem o nazwie \"${code.name}\". Być może jest to inny kod lub jest on stary."),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("OK"))
                  ],
                ));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    codes = GlobalData.qrCodes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Kody QR")),
        backgroundColor: Theme.of(context).cardColor,
        floatingActionButton: FloatingActionButton(
          onPressed: addCode,
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
            key: _refreshState,
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                codes = GlobalData.qrCodes;
              });
            },
            child: codes.isNotEmpty
                ? Scrollbar(
                    child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 56),
                        itemCount: codes.length,
                        itemBuilder: (BuildContext context, int index) {
                          QRCode e = codes[index];
                          return Dismissible(
                              key: ObjectKey(e),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.check,
                                                color: Colors.white),
                                            Text("Testuj",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete,
                                                color: Colors.white),
                                            Text("Usuń",
                                                style: TextStyle(
                                                    color: Colors.white)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )),
                              confirmDismiss:
                                  (DismissDirection direction) async {
                                //Navigate here, not in the onDismissed function - keep the qr code list tile, don't destroy it
                                if (direction == DismissDirection.endToStart) {
                                  if (e.name == "default") return false;
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Usuń kod"),
                                        content: Text(
                                            'Czy na pewno chcesz usunąć "${e.name}"?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text("Anuluj"),
                                          ),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context)
                                                      .pop(true),
                                              child: const Text("Usuń")),
                                        ],
                                      );
                                    },
                                  );
                                } else if (direction ==
                                    DismissDirection.startToEnd) {
                                  await testQRCode(e);
                                }
                              },
                              onDismissed: (DismissDirection direction) {
                                if (direction == DismissDirection.endToStart) {
                                  if (e.name != "default") {
                                    deleteCode(e);
                                  }
                                }
                              },
                              child: ListTile(
                                onTap: widget.selectCode
                                    ? () => Navigator.of(context).pop(e)
                                    : () => showAlarmsWithCode(e),
                                onLongPress: () => changeCodeName(e),
                                title: Text(e.name),
                                trailing: IconButton(
                                    icon: Icon(Icons.print, size: 32),
                                    onPressed: () => printQRCode(e)),
                              ));
                        }),
                  )
                : const Center(
                    child: Text("Brak audio!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }

  @override
  void dispose() {
    super.dispose();
    GlobalData.stopAudioPreview();
  }
}
