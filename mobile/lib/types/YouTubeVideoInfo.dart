class YouTubeVideoInfo {
  final YouTubeChannelInfo channel;
  final String description;
  final Duration length;
  final String thumbnailURL;
  final String title;
  final DateTime? uploadDate;
  final String? url;

  YouTubeVideoInfo(
      {required this.channel,
      required this.description,
      required this.length,
      required this.thumbnailURL,
      required this.title,
      this.uploadDate,
      this.url});
}

class YouTubeChannelInfo {
  final String name;
  final String? id;
  final bool? isVerified;
  final String? username;
  final Uri? url;

  YouTubeChannelInfo(
      {required this.name, this.id, this.isVerified, this.username, this.url});
}
