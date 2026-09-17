import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/track.dart';

class StreamData {
  final String url;
  final int totalBytes;
  final String container;

  StreamData({
    required this.url,
    required this.totalBytes,
    required this.container,
  });
}

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

  Future<StreamData?> getBestAudioStream(String videoId, {String? queryFallback}) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // 1. Prioritize itag 18 (360p MP4 with AAC stereo audio) which has ratebypass=yes and never 403s on streaming
      final muxed18 = manifest.muxed.where((s) => s.tag == 18 || s.url.toString().contains('ratebypass=yes')).firstOrNull;
      if (muxed18 != null) {
        return StreamData(
          url: muxed18.url.toString(),
          totalBytes: muxed18.size.totalBytes,
          container: 'mp4',
        );
      }

      final audioOnly = manifest.audioOnly;
      if (audioOnly.isNotEmpty) {
        // Prioritize itag 140 (128kbps AAC), then 251 (Opus), then any mp4
        final itag140 = audioOnly.where((s) => s.tag == 140).firstOrNull;
        if (itag140 != null) {
          return StreamData(
            url: itag140.url.toString(),
            totalBytes: itag140.size.totalBytes,
            container: itag140.container.name,
          );
        }
        final itag251 = audioOnly.where((s) => s.tag == 251).firstOrNull;
        if (itag251 != null) {
          return StreamData(
            url: itag251.url.toString(),
            totalBytes: itag251.size.totalBytes,
            container: itag251.container.name,
          );
        }
        final bestMp4 = audioOnly.where((s) => s.container.name == 'mp4').firstOrNull;
        if (bestMp4 != null) {
          return StreamData(
            url: bestMp4.url.toString(),
            totalBytes: bestMp4.size.totalBytes,
            container: bestMp4.container.name,
          );
        }
        final first = audioOnly.first;
        return StreamData(
          url: first.url.toString(),
          totalBytes: first.size.totalBytes,
          container: first.container.name,
        );
      }
    } catch (_) {}

    if (queryFallback != null && queryFallback.isNotEmpty) {
      try {
        final searchResults = await _yt.search.search(queryFallback);
        if (searchResults.isNotEmpty) {
          final firstVideoId = searchResults.first.id.value;
          return await getBestAudioStream(firstVideoId);
        }
      } catch (_) {}
    }
    return null;
  }

  Future<List<String>> getAudioStreamUrls(String videoId, {String? queryFallback}) async {
    final streamData = await getBestAudioStream(videoId, queryFallback: queryFallback);
    return streamData != null ? [streamData.url] : [];
  }

  Future<String?> getAudioStreamUrl(String videoId, {String? queryFallback}) async {
    final streamData = await getBestAudioStream(videoId, queryFallback: queryFallback);
    return streamData?.url;
  }

  void dispose() {
    _yt.close();
  }
}
