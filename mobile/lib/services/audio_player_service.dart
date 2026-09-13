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

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  double _crossfadeDuration = 3.0; // 3 seconds crossfade
  bool _loudnessNormalization = true;

  AudioPlayer get player => _player;
  AudioTarget get target => _target;
  Track? get currentTrack => _currentTrack;
  bool get isLoading => _isLoading;
  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  double get crossfadeDuration => _crossfadeDuration;
  bool get loudnessNormalization => _loudnessNormalization;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  void setAudioTarget(AudioTarget newTarget) {
    _target = newTarget;
    if (_target == AudioTarget.piSpeaker) {
      _player.pause();
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    if (_target == AudioTarget.phoneLocal) {
      await _player.setSpeed(speed);
    }
  }

  Future<void> setPitch(double pitchVal) async {
    _pitch = pitchVal;
    if (_target == AudioTarget.phoneLocal) {
      await _player.setPitch(pitchVal);
    }
  }

  void setCrossfade(double seconds) {
    _crossfadeDuration = seconds;
  }

  void setLoudnessNormalization(bool enabled) {
    _loudnessNormalization = enabled;
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
        await _player.setSpeed(_playbackSpeed);
        await _player.setPitch(_pitch);
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
