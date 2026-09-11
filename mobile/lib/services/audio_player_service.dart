import 'package:just_audio/just_audio.dart';
import '../models/track.dart';

enum AudioTarget { phoneLocal, piSpeaker }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  AudioTarget _target = AudioTarget.phoneLocal;
  Track? _currentTrack;

  AudioPlayer get player => _player;
  AudioTarget get target => _target;
  Track? get currentTrack => _currentTrack;

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
      try {
        if (track.localPath != null && track.localPath!.isNotEmpty) {
          await _player.setFilePath(track.localPath!);
        } else if (track.streamUrl.isNotEmpty) {
          await _player.setUrl(track.streamUrl);
        }
        await _player.play();
      } catch (e) {
        // Handle playback error fallback
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
    await _player.setVolume(volume);
  }

  void dispose() {
    _player.dispose();
  }
}
