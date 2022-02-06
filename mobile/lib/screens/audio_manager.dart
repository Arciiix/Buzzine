import 'dart:async';
import 'package:buzzine/globalData.dart';
import 'package:buzzine/types/Audio.dart';
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
  late List<Audio> audios;

  bool _isPreviewPlaying = false;
  String? _previewId;
  Timer? _audioPlaybackEndTimer;

  void addAudio() {
    //TODO: Add audio
    print("TODO: Add audio");
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
                              direction: DismissDirection.endToStart,
                              background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: const EdgeInsets.only(right: 20),
                                  color: Colors.red,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Icon(Icons.delete, color: Colors.white),
                                      Text("Usuń",
                                          style: TextStyle(color: Colors.white))
                                    ],
                                  )),
                              confirmDismiss:
                                  (DismissDirection direction) async {
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
                                              Navigator.of(context).pop(false),
                                          child: const Text("Anuluj"),
                                        ),
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            child: const Text("Usuń")),
                                      ],
                                    );
                                  },
                                );
                              },
                              onDismissed: (DismissDirection direction) {
                                if (e.audioId != "default") {
                                  deleteAudio(e);
                                }
                              },
                              child: ListTile(
                                onTap: widget.selectAudio
                                    ? () => Navigator.of(context).pop(e)
                                    : null,
                                title: Text(e.friendlyName ?? e.filename),
                                subtitle: Text(e.filename),
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
