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
  final double energy;
  final double valence;
  final double danceability;
  final double acousticness;
  final double tempo;
  final String genre;
  final String mood;
  final double aiRecommendationScore;
  final String aiExplanation;

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
    double? energy,
    double? valence,
    double? danceability,
    double? acousticness,
    double? tempo,
    String? genre,
    String? mood,
    this.aiRecommendationScore = 0.0,
    this.aiExplanation = '',
  })  : energy = energy ?? _estimateEnergy(title, artist),
        valence = valence ?? _estimateValence(title, artist),
        danceability = danceability ?? 0.60,
        acousticness = acousticness ?? _estimateAcousticness(title, artist),
        tempo = tempo ?? _estimateTempo(title, artist),
        genre = genre ?? _estimateGenre(title, artist),
        mood = mood ?? _estimateMood(title, artist);

  static double _estimateEnergy(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('rock') || lower.contains('metal') || lower.contains('linkin') || lower.contains('queen')) {
      return 0.88;
    }
    if (lower.contains('lofi') || lower.contains('relax') || lower.contains('sleep') || lower.contains('piano')) {
      return 0.25;
    }
    if (lower.contains('workout') || lower.contains('party') || lower.contains('edm') || lower.contains('dance')) {
      return 0.92;
    }
    return 0.65;
  }

  static double _estimateValence(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('happy') || lower.contains('feel good') || lower.contains('yellow') || lower.contains('summer')) {
      return 0.85;
    }
    if (lower.contains('sad') || lower.contains('melanchol') || lower.contains('numb') || lower.contains('cry')) {
      return 0.22;
    }
    return 0.58;
  }

  static double _estimateAcousticness(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('acoustic') || lower.contains('piano') || lower.contains('unplugged') || lower.contains('orchestra')) {
      return 0.82;
    }
    if (lower.contains('synth') || lower.contains('edm') || lower.contains('electronic') || lower.contains('remix')) {
      return 0.08;
    }
    return 0.35;
  }

  static double _estimateTempo(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('workout') || lower.contains('fast') || lower.contains('drum')) {
      return 140.0;
    }
    if (lower.contains('lofi') || lower.contains('slow') || lower.contains('ballad')) {
      return 82.0;
    }
    return 118.0;
  }

  static String _estimateGenre(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('coldplay') || lower.contains('rock') || lower.contains('linkin') || lower.contains('queen')) {
      return 'Rock / Alternative';
    }
    if (lower.contains('lofi') || lower.contains('chill')) return 'Lo-Fi / Beats';
    if (lower.contains('einaudi') || lower.contains('piano') || lower.contains('classical')) return 'Classical';
    if (lower.contains('weeknd') || lower.contains('ed sheeran') || lower.contains('dua lipa')) return 'Pop / R&B';
    return 'Modern Music';
  }

  static String _estimateMood(String title, String artist) {
    final lower = '$title $artist'.toLowerCase();
    if (lower.contains('lofi') || lower.contains('relax') || lower.contains('sleep')) return 'Relax';
    if (lower.contains('focus') || lower.contains('study') || lower.contains('classical')) return 'Focus';
    if (lower.contains('sad') || lower.contains('cry') || lower.contains('numb')) return 'Melancholy';
    if (lower.contains('party') || lower.contains('dance')) return 'Party';
    if (lower.contains('workout') || lower.contains('gym')) return 'Workout';
    return 'Energize';
  }

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
      energy: (json['energy'] as num?)?.toDouble(),
      valence: (json['valence'] as num?)?.toDouble(),
      danceability: (json['danceability'] as num?)?.toDouble(),
      acousticness: (json['acousticness'] as num?)?.toDouble(),
      tempo: (json['tempo'] as num?)?.toDouble(),
      genre: json['genre'],
      mood: json['mood'],
      aiRecommendationScore: (json['ai_score'] as num?)?.toDouble() ?? 0.0,
      aiExplanation: json['ai_explanation'] ?? '',
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
      'energy': energy,
      'valence': valence,
      'danceability': danceability,
      'acousticness': acousticness,
      'tempo': tempo,
      'genre': genre,
      'mood': mood,
      'ai_score': aiRecommendationScore,
      'ai_explanation': aiExplanation,
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
    double? energy,
    double? valence,
    double? danceability,
    double? acousticness,
    double? tempo,
    String? genre,
    String? mood,
    double? aiRecommendationScore,
    String? aiExplanation,
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
      energy: energy ?? this.energy,
      valence: valence ?? this.valence,
      danceability: danceability ?? this.danceability,
      acousticness: acousticness ?? this.acousticness,
      tempo: tempo ?? this.tempo,
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      aiRecommendationScore: aiRecommendationScore ?? this.aiRecommendationScore,
      aiExplanation: aiExplanation ?? this.aiExplanation,
    );
  }
}
