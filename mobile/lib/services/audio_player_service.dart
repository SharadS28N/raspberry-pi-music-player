import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import 'youtube_service.dart';

enum AudioTarget { phoneLocal, piSpeaker }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  AudioTarget _target = AudioTarget.phoneLocal;
  Track? _currentTrack;
  bool _isLoading = false;

  AudioPlayer get player => _player;
  AudioTarget get target => _target;
  Track? get currentTrack => _currentTrack;
  bool get isLoading => _isLoading;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  void setAudioTarget(AudioTarget newTarget) {
    _target = newTarget;
    if (_target == AudioTarget.piSpeaker) {
      _player.pause();
    }
  }

  Future<void> playTrack(Track track) async {
    _currentTrack = track;
    if (_target == AudioTarget.phoneLocal) {
      _isLoading = true;
      try {
        String? audioUrl = track.streamUrl;
        if (track.localPath != null && track.localPath!.isNotEmpty) {
          await _player.setFilePath(track.localPath!);
        } else {
          if (audioUrl.isEmpty) {
            audioUrl = await _ytService.getAudioStreamUrl(track.id);
          }
          if (audioUrl != null && audioUrl.isNotEmpty) {
            await _player.setUrl(audioUrl);
          } else {
            // Fallback stream URL from Pi backend or direct YouTube search
            final fallbackUrl = 'http://192.168.18.159:8000/api/audio/stream?id=${track.id}';
            await _player.setUrl(fallbackUrl);
          }
        }
        await _player.play();
      } catch (e) {
        // Retry fallback stream
        try {
          final fallbackUrl = 'http://192.168.18.159:8000/api/audio/stream?id=${track.id}';
          await _player.setUrl(fallbackUrl);
          await _player.play();
        } catch (_) {}
      } finally {
        _isLoading = false;
      }
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    if (_target == AudioTarget.phoneLocal) {
      await _player.play();
    }
  }

  Future<void> seek(Duration position) async {
    if (_target == AudioTarget.phoneLocal) {
      await _player.seek(position);
    }
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume / 100.0);
  }

  void dispose() {
    _player.dispose();
    _ytService.dispose();
  }
}
