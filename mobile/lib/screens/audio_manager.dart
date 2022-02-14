import 'dart:async';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/screens/download_YouTube_audio.dart';
import 'package:buzzine/types/Audio.dart';
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
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DownloadYouTubeAudio()),
    );

    await _refreshState.currentState!.show();
  }

  void deleteAudio(Audio e) async {
    await GlobalData.deleteAudio(e.audioId);
    await GlobalData.getAudios();
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
      await GlobalData.stopAudioPreview();
      setState(() {
        _previewId = '';
        _isPreviewPlaying = false;
        _audioPlaybackEndTimer?.cancel();
      });
    } else {
      await GlobalData.previewAudio(audio.audioId);
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
                    await GlobalData.changeAudioName(
                        audio.audioId, _audioNameTextFieldController.text);
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
                                      Row(
                                        children: [
                                          Icon(Icons.content_cut,
                                              color: Colors.white),
                                          Text("Przytnij",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Icon(Icons.delete,
                                              color: Colors.white),
                                          Text("Usuń",
                                              style: TextStyle(
                                                  color: Colors.white)),
                                        ],
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
                                    : null,
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
