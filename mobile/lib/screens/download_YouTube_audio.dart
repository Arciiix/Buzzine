import 'dart:async';

import 'package:buzzine/types/YouTubeVideoInfo.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:buzzine/utils/show_snackbar.dart';
import 'package:flutter/material.dart';
import 'package:buzzine/globalData.dart';
import 'package:flutter/services.dart';

class DownloadYouTubeAudio extends StatefulWidget {
  final Uri? initialURL;
  const DownloadYouTubeAudio({Key? key, this.initialURL}) : super(key: key);

  @override
  _DownloadYouTubeAudioState createState() => _DownloadYouTubeAudioState();
}

class _DownloadYouTubeAudioState extends State<DownloadYouTubeAudio> {
  final TextEditingController _inputController = TextEditingController();
  final GlobalKey<FormFieldState> _inputKey = GlobalKey<FormFieldState>();
  Timer? _inputChangeTimer;
  YouTubeVideoInfo? _fetchedInfo;

  void handleInputChange(_) {
    if (_inputChangeTimer != null && _inputChangeTimer!.isActive) {
      _inputChangeTimer!.cancel();
    }

    _inputChangeTimer = Timer(const Duration(seconds: 1), getVideoInfo);
  }

  void getVideoInfo() async {
    String youtubeURL = _inputController.text;
    if (!validateYoutubeURL(youtubeURL)) {
      setState(() {
        _fetchedInfo = null;
      });
      return;
    }

    YouTubeVideoInfo? videoInfo =
        await GlobalData.getYouTubeVideoInfo(youtubeURL);

    setState(() {
      _fetchedInfo = videoInfo;
    });
  }

  bool validateYoutubeURL(String? url) {
    if (url == null) return false;
    if (url.isEmpty) return false;
    if (!youtubeRegExp.hasMatch(url)) return false;

    return true;
  }

  void downloadVideo() async {
    if (!_inputKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pobieranie z YouTube"),
          content: LinearProgressIndicator(),
        );
      },
    );

    String? error =
        await GlobalData.downloadYouTubeVideo(_inputController.text);
    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();
    if (error != null) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("B????d"),
            content: Text("Podczas pobierania wyst??pi?? b????d: $error."),
            actions: <Widget>[
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text("Rozumiem")),
            ],
          );
        },
      );
    } else {
      await GlobalData.getAudios();
      //Pop the screen navigation - go back to the previous route (screen).
      Navigator.of(context).pop();
    }
  }

  void pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      if (validateYoutubeURL(data.text)) {
        setState(() {
          _inputController.text = data.text!;
        });
        getVideoInfo();
      } else {
        showSnackbar(context, "Niepoprawny format linku");
      }
    } else {
      showSnackbar(context, "Pusty schowek");
    }
  }

  @override
  void initState() {
    if (widget.initialURL != null) {
      _inputController.text = widget.initialURL.toString();
      getVideoInfo();
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Pobierz z YouTube")),
        floatingActionButton: FloatingActionButton(
          onPressed: downloadVideo,
          child: const Icon(Icons.download),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 72),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: _fetchedInfo != null
                            ? [
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(Icons.remove_red_eye),
                                      ),
                                      Text("Podgl??d",
                                          style: TextStyle(fontSize: 32)),
                                    ],
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                      _fetchedInfo!.thumbnailURL,
                                      width: MediaQuery.of(context).size.width *
                                          0.8,
                                      fit: BoxFit.contain),
                                ),
                                ListTile(
                                  title: Text(_fetchedInfo!.title),
                                  subtitle: Text(_fetchedInfo!.channel.name +
                                      "\n" +
                                      addZero(_fetchedInfo!.length.inMinutes) +
                                      ":" +
                                      addZero(_fetchedInfo!.length.inSeconds
                                          .remainder(60))),
                                  isThreeLine: true,
                                )
                              ]
                            : [
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Padding(
                                            padding: EdgeInsets.only(right: 8),
                                            child: Icon(Icons.remove_red_eye),
                                          ),
                                          Text("Podgl??d",
                                              style: TextStyle(fontSize: 32)),
                                        ],
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.link),
                                          Text("Wpisz link do video"),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    key: _inputKey,
                    controller: _inputController,
                    validator: (String? content) {
                      if (!validateYoutubeURL(content)) {
                        return "Z??y format URL filmu z YouTube";
                      }
                    },
                    onChanged: handleInputChange,
                    decoration: InputDecoration(
                        labelText: "Adres URL filmu",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        suffixIcon: IconButton(
                          icon: Icon(Icons.paste),
                          onPressed: pasteFromClipboard,
                        )),
                  ),
                )
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    _inputChangeTimer?.cancel();

    super.dispose();
  }
}
