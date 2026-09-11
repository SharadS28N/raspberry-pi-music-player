class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String artworkUrl;
  final String streamUrl;
  final String? localPath;
  final bool isDownloaded;

  Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album = 'Single',
    this.duration = Duration.zero,
    required this.artworkUrl,
    required this.streamUrl,
    this.localPath,
    this.isDownloaded = false,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] ?? json['youtube_id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? json['name'] ?? 'Unknown Track',
      artist: json['artist'] ?? json['uploader'] ?? 'Unknown Artist',
      album: json['album'] ?? 'YouTube Stream',
      duration: Duration(seconds: (json['duration'] ?? json['duration_seconds'] ?? 0).toInt()),
      artworkUrl: json['artwork_url'] ?? json['thumbnail'] ?? json['thumbnail_url'] ?? '',
      streamUrl: json['stream_url'] ?? json['url'] ?? '',
      localPath: json['local_path'],
      isDownloaded: json['is_downloaded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_seconds': duration.inSeconds,
      'artwork_url': artworkUrl,
      'stream_url': streamUrl,
      'local_path': localPath,
      'is_downloaded': isDownloaded,
    };
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkUrl,
    String? streamUrl,
    String? localPath,
    bool? isDownloaded,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      localPath: localPath ?? this.localPath,
      isDownloaded: isDownloaded ?? this.isDownloaded,
    );
  }
}
