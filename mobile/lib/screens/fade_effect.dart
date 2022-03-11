import 'dart:async';
import 'package:buzzine/components/number_vertical_picker.dart';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class FadeEffect extends StatefulWidget {
  final Audio audio;
  const FadeEffect({Key? key, required this.audio}) : super(key: key);

  @override
  _FadeEffectState createState() => _FadeEffectState();
}

class _FadeEffectState extends State<FadeEffect> {
  Duration fadeInDuration = Duration(seconds: 0);
  Duration fadeOutDuration = Duration(seconds: 0);
  bool _isPreviewPlaying = false;
  Timer? _previewCleaner;

  void applyAudioFadeEffect() async {
    await stopPreview();
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Dodaj efekty"),
          content: Text(
              'Czy na pewno chcesz dodać efekty wejścia i wyjścia audio ${widget.audio.filename} ${widget.audio.friendlyName != null ? "(" + widget.audio.friendlyName! + ")?" : "?"} Jeżeli jest to audio z YouTube, będzie można pobrać je ponownie (jeśli jest dalej dostępne). Tej operacji nie można cofnąć.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Dodaj")),
          ],
        );
      },
    );
    if (!confirm) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Dodawanie efektu audio"),
          content: LinearProgressIndicator(),
        );
      },
    );

    await GlobalData.addFadeEffects(widget.audio.audioId,
        fadeInDuration.inSeconds, fadeOutDuration.inSeconds);

    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();
    //Exit the screen - go back
    Navigator.of(context).pop();
  }

  void previewFadeEffect() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Podgląd efektu audio"),
          content: LinearProgressIndicator(),
        );
      },
    );

    await GlobalData.previewFadeEffect(widget.audio.audioId,
        fadeInDuration.inSeconds, fadeOutDuration.inSeconds);
    setState(() {
      _isPreviewPlaying = true;
      _previewCleaner =
          Timer(Duration(seconds: widget.audio.duration!.toInt()), () {
        setState(() {
          _isPreviewPlaying = false;
        });
      });
    });

    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();
  }

  Future<bool> stopPreview() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa zatrzymywanie podglądu audio...");
      },
    );
    await GlobalData.stopAudioPreview();
    Navigator.of(context).pop();
    setState(() {
      _isPreviewPlaying = false;
      _previewCleaner?.cancel();
    });
    return true;
  }

  Future<Duration?> selectValueManually(
      int min, int max, int init, bool isFadeIn) async {
    int selectedValue = init;
    bool? change = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Zmień długość ${isFadeIn ? "wejścia" : "wyjścia"}"),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              NumberVerticalPicker(
                onChanged: (int val) => selectedValue = val,
                initValue: init,
                minValue: min,
                maxValue: max,
                propertyName: "Długość ${isFadeIn ? "wejścia" : "wyjścia"}",
              ),
              Text("s")
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Zmień")),
          ],
        );
      },
    );

    return change == true ? Duration(seconds: selectedValue) : null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: stopPreview,
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Dodaj efekty audio"),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: applyAudioFadeEffect,
              )
            ],
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: widget.audio.friendlyName != null
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(Icons.bookmark_border),
                        ),
                        Flexible(
                            child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(widget.audio.friendlyName!),
                        )),
                      ]
                    : [],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.description),
                  ),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(widget.audio.filename),
                  )),
                ],
              ),
              Text("Długość wejścia"),
              Slider(
                value: fadeInDuration.inSeconds.toDouble(),
                min: 0,
                max: widget.audio.duration!.floor().toDouble(),
                onChanged: (value) {
                  setState(() {
                    fadeInDuration = Duration(seconds: value.floor());
                  });
                  if (_isPreviewPlaying) {
                    stopPreview();
                  }
                },
              ),
              InkWell(
                  onTap: () async {
                    await stopPreview();
                    Duration? userSelection = await selectValueManually(
                        0,
                        widget.audio.duration?.floor() ?? 0,
                        fadeInDuration.inSeconds,
                        true);

                    if (userSelection != null) {
                      if (userSelection.inSeconds < widget.audio.duration!) {
                        setState(() {
                          fadeInDuration = userSelection;
                        });
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(secondsTommss(fadeInDuration.inSeconds)),
                  )),
              Text("Długość wyjścia"),
              Slider(
                value: fadeOutDuration.inSeconds.toDouble(),
                min: 0,
                max: widget.audio.duration!.floor().toDouble(),
                onChanged: (value) {
                  setState(() {
                    fadeOutDuration = Duration(seconds: value.floor());
                  });
                  if (_isPreviewPlaying) {
                    stopPreview();
                  }
                },
              ),
              InkWell(
                  onTap: () async {
                    await stopPreview();
                    Duration? userSelection = await selectValueManually(
                        0,
                        widget.audio.duration?.floor() ?? 0,
                        fadeOutDuration.inSeconds,
                        false);

                    if (userSelection != null) {
                      if (userSelection.inSeconds < widget.audio.duration!) {
                        setState(() {
                          fadeOutDuration = userSelection;
                        });
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(secondsTommss(fadeOutDuration.inSeconds)),
                  )),
              TextButton(
                onPressed: _isPreviewPlaying ? stopPreview : previewFadeEffect,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                          _isPreviewPlaying ? Icons.pause : Icons.play_arrow),
                    ),
                    const Text("Podgląd")
                  ],
                ),
              )
            ],
          )),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _previewCleaner?.cancel();
  }
}
