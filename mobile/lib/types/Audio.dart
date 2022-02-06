class Audio {
  final String audioId;
  final String filename;
  final String? friendlyName;

  Audio({required this.audioId, required this.filename, this.friendlyName});

  Map toMap() {
    return {
      'audioId': audioId,
      'filename': filename,
      'friendlyName': friendlyName,
    };
  }
}
