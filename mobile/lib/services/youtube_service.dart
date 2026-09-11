import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/track.dart';

class YoutubeService {
  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Track>> searchTracks(String query) async {
    try {
      final searchResults = await _yt.search.search(query);
      final tracks = <Track>[];

      for (var video in searchResults.take(15)) {
        tracks.add(Track(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'YouTube Music',
          duration: video.duration ?? Duration.zero,
          artworkUrl: video.thumbnails.highResUrl,
          streamUrl: '',
        ));
      }
      return tracks;
    } catch (_) {
      return [];
    }
  }

  Future<String?> getAudioStreamUrl(String videoId) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final audioOnly = manifest.audioOnly;
      if (audioOnly.isNotEmpty) {
        final bestAudio = audioOnly.withHighestBitrate();
        return bestAudio.url.toString();
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _yt.close();
  }
}
