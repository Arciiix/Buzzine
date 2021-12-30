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
  String? _previewFilename;

  void addAudio() {
    //TODO: Add audio
    print("TODO: Add audio");
  }

  void deleteAudio() {
    //TODO: Delete audio
    print("TODO: Delete audio");
  }

  void selectAudio(Audio e) {
    if (widget.selectAudio) {
      Navigator.of(context).pop(e);
    }
  }

  void playPreview(Audio audio) {
    //TODO: Play a preview of the audio
    if (_previewFilename == audio.filename) {
      //TODO: Pause the preview
      setState(() {
        _previewFilename = '';
        _isPreviewPlaying = false;
      });
    } else {
      //TODO: Pause the current preview if it's playing and play the new preview
      setState(() {
        _previewFilename = audio.filename;
        _isPreviewPlaying = true;
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
                ? ListView.builder(
                    itemCount: audios.length,
                    itemBuilder: (BuildContext context, int index) {
                      Audio e = audios[index];
                      return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          child: Dismissible(
                              key: ObjectKey(e),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                  alignment: Alignment.centerLeft,
                                  padding: EdgeInsets.only(right: 20),
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
                                deleteAudio();
                              },
                              child: InkWell(
                                  onTap: () => selectAudio(e),
                                  child: Container(
                                      width: MediaQuery.of(context).size.width *
                                          0.9,
                                      padding: const EdgeInsets.all(10),
                                      margin: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(e.friendlyName ?? e.filename,
                                              style: const TextStyle(
                                                  fontSize: 24)),
                                          IconButton(
                                              icon: Icon(
                                                  _isPreviewPlaying &&
                                                          _previewFilename ==
                                                              e.filename
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  size: 32),
                                              onPressed: () => playPreview(e)),
                                        ],
                                      )))));
                    })
                : const Center(
                    child: Text("Brak audio!",
                        style: TextStyle(fontSize: 32, color: Colors.white)))));
  }
}
