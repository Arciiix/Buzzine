import 'dart:async';
import 'package:buzzine/components/simple_loading_dialog.dart';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/alarm_list.dart';
import 'package:buzzine/screens/cut_audio.dart';
import 'package:buzzine/screens/download_YouTube_audio.dart';
import 'package:buzzine/screens/nap_list.dart';
import 'package:buzzine/types/Alarm.dart';
import 'package:buzzine/types/Audio.dart';
import 'package:buzzine/types/Nap.dart';
import 'package:buzzine/utils/formatting.dart';
import 'package:flutter/material.dart';

class AudioManager extends StatefulWidget {
  final Audio? selectedAudio;
  final bool selectAudio;

  const AudioManager({Key? key, this.selectedAudio, required this.selectAudio})
      : super(key: key);

  @override
  _AudioManagerState createState() => _AudioManagerState();
}

class _AudioManagerState extends State<AudioManager> {
  GlobalKey<RefreshIndicatorState> _refreshState =
      GlobalKey<RefreshIndicatorState>();

  late List<Audio> audios;

  bool _isPreviewPlaying = false;
  String? _previewId;
  Timer? _audioPlaybackEndTimer;

  void addAudio() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa zatrzymywanie podglądu audio...");
      },
    );
    await GlobalData.stopAudioPreview();
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DownloadYouTubeAudio()),
    );

    await _refreshState.currentState!.show();
  }

  void deleteAudio(Audio e) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa usuwanie audio...");
      },
    );
    await GlobalData.deleteAudio(e.audioId);
    await GlobalData.getAudios();
    Navigator.of(context).pop();
    setState(() {
      audios = GlobalData.audios;
    });
  }

  void selectAudio(Audio e) {
    if (widget.selectAudio) {
      Navigator.of(context).pop(e);
    }
  }

  void playPreview(Audio audio) async {
    if (_previewId == audio.audioId) {
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
        _previewId = '';
        _isPreviewPlaying = false;
        _audioPlaybackEndTimer?.cancel();
      });
    } else {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return SimpleLoadingDialog("Trwa włączanie podglądu audio...");
        },
      );
      await GlobalData.previewAudio(audio.audioId);
      Navigator.of(context).pop();
      setState(() {
        _previewId = audio.audioId;
        _isPreviewPlaying = true;
        _audioPlaybackEndTimer?.cancel();
        _audioPlaybackEndTimer = Timer(
            Duration(seconds: GlobalData.audioPreviewDurationSeconds), () {
          setState(() {
            _previewId = '';
            _isPreviewPlaying = false;
          });
        });
      });
    }
  }

  void changeAudioName(Audio audio) async {
    TextEditingController _audioNameTextFieldController =
        TextEditingController()..text = audio.friendlyName ?? audio.filename;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Zmień nazwę audio"),
          content: TextField(
            controller: _audioNameTextFieldController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: "Nazwa audio"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Anuluj"),
            ),
            TextButton(
                onPressed: () async {
                  if (_audioNameTextFieldController.text !=
                      audio.friendlyName) {
                    if (_audioNameTextFieldController.text.isEmpty) {
                      _audioNameTextFieldController.text = audio.filename;
                    }
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return SimpleLoadingDialog(
                            "Trwa zmiana nazwy audio...");
                      },
                    );
                    await GlobalData.changeAudioName(
                        audio.audioId, _audioNameTextFieldController.text);
                    Navigator.of(context).pop();
                    await _refreshState.currentState!.show();
                    Navigator.of(context).pop();
                  }
                },
                child: const Text("Zmień")),
          ],
        );
      },
    );
  }

  void navigateToAudioCut(Audio audio) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa zatrzymywanie podglądu audio...");
      },
    );
    await GlobalData.stopAudioPreview();
    Navigator.of(context).pop();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => CutAudio(audio: audio),
    ));

    await _refreshState.currentState!.show();
  }

  void showAlarmsWithAudio(Audio audio) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SimpleLoadingDialog("Trwa zatrzymywanie podglądu audio...");
      },
    );
    await GlobalData.stopAudioPreview();
    Navigator.of(context).pop();
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
            AlarmList(filter: (Alarm e) => e.sound?.audioId == audio.audioId),
      ));

      await _refreshState.currentState!.show();
    } else if (showAlarms == false) {
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) =>
            NapList(filter: (Nap e) => e.sound?.audioId == audio.audioId),
      ));

      await _refreshState.currentState!.show();
    }
  }

  @override
  void initState() {
    super.initState();
    audios = GlobalData.audios;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Audio")),
        backgroundColor: Theme.of(context).cardColor,
        floatingActionButton: FloatingActionButton(
          onPressed: addAudio,
          child: const Icon(Icons.add),
        ),
        body: RefreshIndicator(
            key: _refreshState,
            onRefresh: () async {
              await GlobalData.getData();
              setState(() {
                audios = GlobalData.audios;
              });
            },
            child: audios.isNotEmpty
                ? Scrollbar(
                    child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 56),
                        itemCount: audios.length,
                        itemBuilder: (BuildContext context, int index) {
                          Audio e = audios[index];
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
                                            Icon(Icons.content_cut,
                                                color: Colors.white),
                                            Text("Przytnij",
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
                                if (direction == DismissDirection.endToStart) {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Usuń audio"),
                                        content: Text(
                                            'Czy na pewno chcesz usunąć "${e.friendlyName ?? e.filename}"?'),
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
                                  //Navigate here, not in the onDismissed function - keep the audio list tile, don't destroy it
                                  navigateToAudioCut(e);
                                }
                              },
                              onDismissed: (DismissDirection direction) {
                                if (direction == DismissDirection.endToStart) {
                                  if (e.audioId != "default") {
                                    deleteAudio(e);
                                  }
                                }
                              },
                              child: ListTile(
                                onTap: widget.selectAudio
                                    ? () => Navigator.of(context).pop(e)
                                    : () => showAlarmsWithAudio(e),
                                onLongPress: () => changeAudioName(e),
                                title: Text(e.friendlyName ?? e.filename),
                                subtitle: Text(e.filename +
                                    '\n' +
                                    secondsToHHmm(e.duration)),
                                isThreeLine: true,
                                trailing: IconButton(
                                    icon: Icon(
                                        _isPreviewPlaying &&
                                                _previewId == e.audioId
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        size: 32),
                                    onPressed: () => playPreview(e)),
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

    _audioPlaybackEndTimer?.cancel();
    GlobalData.stopAudioPreview();
  }
}
