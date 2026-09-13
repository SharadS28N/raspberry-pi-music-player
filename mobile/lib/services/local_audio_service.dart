import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';

class LocalAudioService extends ChangeNotifier {
  bool _isScanning = false;
  List<Track> _localTracks = [];

  bool get isScanning => _isScanning;
  List<Track> get localTracks => List.unmodifiable(_localTracks);

  LocalAudioService() {
    _loadSampleLocalTracks();
  }

  void _loadSampleLocalTracks() {
    _localTracks = [
      Track(
        id: 'local_track_1',
        title: 'ハイスペックニート - High Spec Neet',
        artist: '40mP',
        album: 'Einstein Problem',
        duration: const Duration(minutes: 3, seconds: 19),
        artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        streamUrl: '',
        localPath: '/storage/emulated/0/Music/HighSpecNeet.mp3',
        isLocal: true,
        codec: 'FLAC 24-bit',
      ),
      Track(
        id: 'local_track_2',
        title: 'マリーゴールド - Marigold (Acoustic Studio)',
        artist: 'aimyon',
        album: 'Acoustic Sessions 2026',
        duration: const Duration(minutes: 5, seconds: 6),
        artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
        streamUrl: '',
        localPath: '/storage/emulated/0/Music/Marigold.flac',
        isLocal: true,
        codec: 'ALAC 96kHz',
      ),
      Track(
        id: 'local_track_3',
        title: '好きだから。 - Sukidakara (Piano Ver)',
        artist: 'Yuika',
        album: 'Piano Memories',
        duration: const Duration(minutes: 4, seconds: 12),
        artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        streamUrl: '',
        localPath: '/storage/emulated/0/Music/Sukidakara.m4a',
        isLocal: true,
        codec: 'AAC 320kbps',
      ),
    ];
  }

  Future<void> scanDeviceMusic() async {
    _isScanning = true;
    notifyListeners();

    try {
      final extDir = await getExternalStorageDirectory();
      if (extDir != null && await extDir.exists()) {
        final List<Track> discovered = [];
        final entities = extDir.listSync(recursive: true);
        for (var entity in entities) {
          if (entity is File) {
            final path = entity.path.toLowerCase();
            if (path.endsWith('.mp3') || path.endsWith('.flac') || path.endsWith('.m4a') || path.endsWith('.wav')) {
              final fileName = entity.path.split(Platform.pathSeparator).last;
              discovered.add(
                Track(
                  id: 'local_${entity.path.hashCode}',
                  title: fileName.replaceAll(RegExp(r'\.[a-zA-Z0-9]+$'), ''),
                  artist: 'Device Storage',
                  album: 'Local Music',
                  duration: const Duration(minutes: 3, seconds: 45),
                  artworkUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400',
                  streamUrl: entity.path,
                  localPath: entity.path,
                  isLocal: true,
                  codec: path.endsWith('.flac') ? 'FLAC' : 'MP3',
                ),
              );
            }
          }
        }
        if (discovered.isNotEmpty) {
          _localTracks.addAll(discovered);
        }
      }
    } catch (e) {
      debugPrint('Local scanning error: $e');
    }

    _isScanning = false;
    notifyListeners();
  }
}
