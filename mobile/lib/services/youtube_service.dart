import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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
      if (tracks.isNotEmpty) return tracks;
    } catch (e) {
      debugPrint('searchTracks primary error: $e');
    }

    try {
      final backendUrl = Uri.parse('http://192.168.18.159:8000/api/search?q=${Uri.encodeComponent(query)}&limit=15');
      final resp = await http.get(backendUrl).timeout(const Duration(seconds: 4));
      if (resp.statusCode == 200) {
        final List<dynamic> data = jsonDecode(resp.body);
        final tracks = data.map((item) => Track(
          id: item['id'] as String? ?? '',
          title: item['title'] as String? ?? 'Unknown Title',
          artist: item['artist'] as String? ?? 'Unknown Artist',
          album: 'YouTube Music',
          duration: Duration(seconds: (item['duration'] as num?)?.toInt() ?? 0),
          artworkUrl: item['thumbnail'] as String? ?? item['artworkUrl'] as String? ?? '',
          streamUrl: '',
        )).toList();
        if (tracks.isNotEmpty) return tracks;
      }
    } catch (e) {
      debugPrint('searchTracks backend fallback error: $e');
    }

    return [];
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
        for (var video in searchResults.take(4)) {
          if (video.id.value == videoId) continue;
          final fallbackStream = await getBestAudioStream(video.id.value);
          if (fallbackStream != null) {
            return fallbackStream;
          }
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

  Future<Channel?> getChannelByHandle(String handleOrQuery) async {
    try {
      final clean = handleOrQuery.trim();
      final handle = clean.startsWith('@') ? clean : '@$clean';
      return await _yt.channels.getByHandle(handle);
    } catch (_) {
      try {
        // Fallback: search channels
        final clean = handleOrQuery.replaceAll('@', '').trim();
        final searchResults = await _yt.search.search(clean);
        if (searchResults.isNotEmpty) {
          final channelId = searchResults.first.channelId;
          return await _yt.channels.get(channelId);
        }
      } catch (_) {}
      return null;
    }
  }

  Future<List<Track>> getChannelUploads(dynamic channelId, {int limit = 20}) async {
    try {
      final uploads = _yt.channels.getUploads(channelId);
      final tracks = <Track>[];
      await for (var video in uploads.take(limit)) {
        tracks.add(Track(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: 'YouTube Uploads',
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

  Future<List<Track>> getPlaylistTracks(String playlistId, {int limit = 50}) async {
    try {
      final playlist = await _yt.playlists.get(playlistId);
      final tracks = <Track>[];
      final videos = _yt.playlists.getVideos(playlistId);
      await for (var video in videos.take(limit)) {
        tracks.add(Track(
          id: video.id.value,
          title: video.title,
          artist: video.author,
          album: playlist.title,
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

  void dispose() {
    _yt.close();
  }
}
