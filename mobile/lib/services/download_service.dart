import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'youtube_service.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService();

  final Map<String, double> _downloadProgress = {};
  final List<Track> _downloadedTracks = [];

  Map<String, double> get downloadProgress => Map.unmodifiable(_downloadProgress);
  List<Track> get downloadedTracks => List.unmodifiable(_downloadedTracks);

  DownloadService() {
    _loadSavedDownloads();
  }

  bool isDownloaded(String trackId) {
    return _downloadedTracks.any((t) => t.id == trackId);
  }

  bool isDownloading(String trackId) {
    return _downloadProgress.containsKey(trackId);
  }

  double? getProgress(String trackId) {
    return _downloadProgress[trackId];
  }

  Future<void> _loadSavedDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList('saved_downloaded_tracks') ?? [];
      _downloadedTracks.clear();
      for (var str in jsonList) {
        final map = jsonDecode(str) as Map<String, dynamic>;
        final track = Track.fromJson(map);
        if (track.localPath != null && File(track.localPath!).existsSync()) {
          _downloadedTracks.add(track);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading saved downloads: $e');
    }
  }

  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _downloadedTracks.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('saved_downloaded_tracks', jsonList);
    } catch (e) {
      debugPrint('Error saving downloads to preferences: $e');
    }
  }

  Future<void> downloadTrack(Track track, YoutubeService ytService) async {
    final trackId = track.id;
    if (isDownloaded(trackId) || isDownloading(trackId)) return;

    _downloadProgress[trackId] = 0.05;
    notifyListeners();

    try {
      String? streamUrl = track.streamUrl;
      if (streamUrl.isEmpty || streamUrl.startsWith('/storage')) {
        streamUrl = await ytService.getAudioStreamUrl(
          track.id,
          queryFallback: '${track.title} ${track.artist}',
        );
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw Exception('Could not resolve audio stream URL for download');
      }

      final docDir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${docDir.path}/offline_music');
      if (!musicDir.existsSync()) {
        musicDir.createSync(recursive: true);
      }

      final sanitizedTitle = track.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final targetFile = File('${musicDir.path}/${track.id}_$sanitizedTitle.m4a');

      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['User-Agent'] =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

      final client = http.Client();
      final streamedResponse = await client.send(request);

      final totalBytes = streamedResponse.contentLength ?? (4 * 1024 * 1024);
      int receivedBytes = 0;

      final fileSink = targetFile.openWrite();
      await for (var chunk in streamedResponse.stream) {
        fileSink.add(chunk);
        receivedBytes += chunk.length;
        _downloadProgress[trackId] = (receivedBytes / totalBytes).clamp(0.0, 0.99);
        notifyListeners();
      }

      await fileSink.flush();
      await fileSink.close();

      final downloadedTrack = track.copyWith(
        localPath: targetFile.path,
        isDownloaded: true,
        isLocal: true,
        streamUrl: targetFile.path,
      );

      _downloadedTracks.add(downloadedTrack);
      await _saveDownloads();
    } catch (e) {
      debugPrint('Download error for ${track.title}: $e');
    } finally {
      _downloadProgress.remove(trackId);
      notifyListeners();
    }
  }

  Future<void> deleteDownloadedTrack(String trackId) async {
    try {
      final idx = _downloadedTracks.indexWhere((t) => t.id == trackId);
      if (idx != -1) {
        final track = _downloadedTracks[idx];
        if (track.localPath != null) {
          final file = File(track.localPath!);
          if (file.existsSync()) {
            file.deleteSync();
          }
        }
        _downloadedTracks.removeAt(idx);
        await _saveDownloads();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting download: $e');
    }
  }
}
