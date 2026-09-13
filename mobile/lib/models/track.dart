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
  final bool isLocal;
  final String codec;
  final String? spotifyUri;
  final List<String>? syncedLyrics;
  final List<String>? romajiLyrics;
  final List<String>? translatedLyrics;
  final double loudnessGain;

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
    this.isLocal = false,
    this.codec = 'OPUS',
    this.spotifyUri,
    this.syncedLyrics,
    this.romajiLyrics,
    this.translatedLyrics,
    this.loudnessGain = 0.0,
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
      isLocal: json['is_local'] ?? false,
      codec: json['codec'] ?? 'OPUS',
      spotifyUri: json['spotify_uri'],
      syncedLyrics: (json['synced_lyrics'] as List?)?.cast<String>(),
      romajiLyrics: (json['romaji_lyrics'] as List?)?.cast<String>(),
      translatedLyrics: (json['translated_lyrics'] as List?)?.cast<String>(),
      loudnessGain: (json['loudness_gain'] ?? 0.0).toDouble(),
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
      'is_local': isLocal,
      'codec': codec,
      'spotify_uri': spotifyUri,
      'synced_lyrics': syncedLyrics,
      'romaji_lyrics': romajiLyrics,
      'translated_lyrics': translatedLyrics,
      'loudness_gain': loudnessGain,
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
    bool? isLocal,
    String? codec,
    String? spotifyUri,
    List<String>? syncedLyrics,
    List<String>? romajiLyrics,
    List<String>? translatedLyrics,
    double? loudnessGain,
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
      isLocal: isLocal ?? this.isLocal,
      codec: codec ?? this.codec,
      spotifyUri: spotifyUri ?? this.spotifyUri,
      syncedLyrics: syncedLyrics ?? this.syncedLyrics,
      romajiLyrics: romajiLyrics ?? this.romajiLyrics,
      translatedLyrics: translatedLyrics ?? this.translatedLyrics,
      loudnessGain: loudnessGain ?? this.loudnessGain,
    );
  }
}
