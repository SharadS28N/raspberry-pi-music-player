import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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

    _downloadProgress[trackId] = 0.02;
    notifyListeners();

    final client = HttpClient();
    try {
      String? streamUrl = track.streamUrl;
      if (streamUrl.isEmpty || streamUrl.startsWith('/storage') || streamUrl.startsWith('http://127.0.0.1')) {
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
      if (targetFile.existsSync()) {
        targetFile.deleteSync();
      }

      // Probe total length via range 0-1
      int totalBytes = 4 * 1024 * 1024;
      try {
        final probeReq = await client.getUrl(Uri.parse(streamUrl));
        probeReq.headers.set('Range', 'bytes=0-1');
        final probeRes = await probeReq.close();
        final contentRange = probeRes.headers.value(HttpHeaders.contentRangeHeader);
        if (contentRange != null) {
          final match = RegExp(r'/(\d+)').firstMatch(contentRange);
          if (match != null) {
            final parsed = int.tryParse(match.group(1) ?? '');
            if (parsed != null && parsed > 0) {
              totalBytes = parsed;
            }
          }
        }
        await probeRes.drain();
      } catch (_) {}

      final fileSink = targetFile.openWrite();
      const chunkSize = 256 * 1024; // Safe 256KB bounded range
      int current = 0;

      while (current < totalBytes) {
        final chunkEnd = (current + chunkSize - 1) < totalBytes
            ? (current + chunkSize - 1)
            : totalBytes - 1;

        final chunkReq = await client.getUrl(Uri.parse(streamUrl));
        chunkReq.headers.set('Range', 'bytes=$current-$chunkEnd');
        final chunkRes = await chunkReq.close();

        if (chunkRes.statusCode != 206 && chunkRes.statusCode != 200) {
          await chunkRes.drain();
          break;
        }

        await for (var chunk in chunkRes) {
          fileSink.add(chunk);
        }

        current = chunkEnd + 1;
        _downloadProgress[trackId] = (current / totalBytes).clamp(0.05, 0.99);
        notifyListeners();
      }

      await fileSink.flush();
      await fileSink.close();

      if (targetFile.existsSync() && targetFile.lengthSync() > 10000) {
        final downloadedTrack = track.copyWith(
          localPath: targetFile.path,
          isDownloaded: true,
          isLocal: true,
          streamUrl: targetFile.path,
        );

        _downloadedTracks.removeWhere((t) => t.id == downloadedTrack.id);
        _downloadedTracks.insert(0, downloadedTrack);
        await _saveDownloads();
      } else {
        throw Exception('Downloaded file was incomplete or corrupted');
      }
    } catch (e) {
      debugPrint('Download error for ${track.title}: $e');
    } finally {
      client.close();
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
