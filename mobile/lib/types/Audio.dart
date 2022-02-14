class Audio {
  final String audioId;
  final String filename;
  final String? friendlyName;
  final double? duration;

  Audio(
      {required this.audioId,
      required this.filename,
      this.friendlyName,
      this.duration});

  Map toMap() {
    return {
      'audioId': audioId,
      'filename': filename,
      'friendlyName': friendlyName,
      'duration': duration
    };
  }
}
