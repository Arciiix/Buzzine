class Audio {
  final String filename;
  final String? friendlyName;

  Audio({required this.filename, this.friendlyName});

  Map toMap() {
    return {
      'filename': filename,
      'friendlyName': friendlyName,
    };
  }
}
