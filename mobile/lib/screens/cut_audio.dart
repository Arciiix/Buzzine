import 'dart:async';

import 'package:buzzine/components/time_number_picker.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class CutAudio extends StatefulWidget {
  final Audio audio;
  const CutAudio({Key? key, required this.audio}) : super(key: key);

  @override
  _CutAudioState createState() => _CutAudioState();
}

class _CutAudioState extends State<CutAudio> {
  late RangeValues _values;
  bool _isPreviewPlaying = false;
  Timer? _previewCleaner;

  void applyAudioCut() async {
    await stopPreview();
    bool confirm = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Przytnij"),
          content: Text(
              'Czy na pewno chcesz przyciąć plik ${widget.audio.filename} ${widget.audio.friendlyName != null ? "(" + widget.audio.friendlyName! + ")?" : "?"} Jeżeli jest to audio z YouTube, będzie można pobrać je ponownie (jeśli jest dalej dostępne). Tej operacji nie można cofnąć.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Wyłącz")),
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
          title: Text("Przycinanie audio"),
          content: LinearProgressIndicator(),
        );
      },
    );
    await GlobalData.cutAudio(
        widget.audio.audioId, _values.start.floor(), _values.end.floor());

    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();
    //Exit the screen - go back
    Navigator.of(context).pop();
  }

  void previewCut() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Przycinanie audio"),
          content: LinearProgressIndicator(),
        );
      },
    );

    await GlobalData.previewAudioCut(
        widget.audio.audioId, _values.start.floor(), _values.end.floor());
    setState(() {
      _isPreviewPlaying = true;
      _previewCleaner = Timer(
          Duration(seconds: _values.end.floor() - _values.start.floor()), () {
        setState(() {
          _isPreviewPlaying = false;
        });
      });
    });

    //The current context is the AlertDialog, so exit it.
    Navigator.of(context).pop();
  }

  Future<bool> stopPreview() async {
    await GlobalData.stopAudioPreview();
    setState(() {
      _isPreviewPlaying = false;
      _previewCleaner?.cancel();
    });
    return true;
  }

  Future<Duration?> selectNumberFromPicker(
      int initialTime, int minTime, int maxTime) async {
    Duration? userSelection =
        await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => TimeNumberPicker(
        maxDuration: maxTime,
        minDuration: minTime,
        initialTime: initialTime,
      ),
    ));
    return userSelection;
  }

  @override
  void initState() {
    _values = RangeValues(0, widget.audio.duration!);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: stopPreview,
      child: Scaffold(
          appBar: AppBar(
            title: const Text("Przytnij audio"),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: applyAudioCut,
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
              RangeSlider(
                  values: _values,
                  min: 0,
                  max: widget.audio.duration!,
                  onChanged: (RangeValues newValues) {
                    setState(() {
                      _values = newValues;
                    });

                    if (_isPreviewPlaying) {
                      stopPreview();
                    }
                  }),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                      onTap: () async {
                        await stopPreview();
                        Duration? userSelection = await selectNumberFromPicker(
                            _values.start.toInt(),
                            0,
                            (_values.end - 3).floor());

                        if (userSelection != null) {
                          if (userSelection.inSeconds <
                              widget.audio.duration!) {
                            setState(() {
                              _values = RangeValues(
                                  userSelection.inSeconds.toDouble(),
                                  _values.end);
                            });
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(secondsToHHmm(_values.start)),
                      )),
                  InkWell(
                      onTap: () async {
                        await stopPreview();
                        Duration? userSelection = await selectNumberFromPicker(
                            _values.end.toInt(),
                            _values.start.toInt() + 3,
                            widget.audio.duration!.floor());
                        if (userSelection != null) {
                          if (userSelection.inSeconds <
                              widget.audio.duration!) {
                            setState(() {
                              _values = RangeValues(_values.start,
                                  userSelection.inSeconds.toDouble());
                            });
                          }
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(secondsToHHmm(_values.end)),
                      )),
                ],
              ),
              TextButton(
                onPressed: _isPreviewPlaying ? stopPreview : previewCut,
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
