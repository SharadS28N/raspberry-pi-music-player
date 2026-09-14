import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import 'youtube_service.dart';
import 'local_stream_proxy.dart';

enum AudioTarget { phoneLocal, piSpeaker }

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  final LocalStreamProxy _proxy = LocalStreamProxy();
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

  LoopMode get loopMode => _player.loopMode;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) => _player.setShuffleModeEnabled(enabled);

  final Map<String, String> _resolvedStreamCache = {};

  Future<void> preloadNextTrack(Track track) async {
    try {
      if (track.localPath != null && File(track.localPath!).existsSync()) return;
      if (_resolvedStreamCache.containsKey(track.id)) return;
      final url = await _ytService.getAudioStreamUrl(
        track.id,
        queryFallback: '${track.title} ${track.artist}',
      );
      if (url != null) {
        _resolvedStreamCache[track.id] = url;
      }
    } catch (_) {}
  }

  Future<void> _playThroughProxy(String streamUrl, int totalBytes, String container) async {
    await _proxy.start();
    _proxy.setStream(streamUrl, totalBytes);
    final ext = container.isEmpty ? 'mp4' : container;
    final proxyUrl = _proxy.getProxyUrl('stream.$ext');
    await _player.setUrl(proxyUrl);
  }

  Future<void> playTrack(Track track) async {
    _currentTrack = track;
    _isLoading = true;
    try {
      bool playedLocal = false;
      if (track.localPath != null && track.localPath!.isNotEmpty) {
        final file = File(track.localPath!);
        if (file.existsSync()) {
          await _player.setFilePath(track.localPath!);
          playedLocal = true;
        }
      }

      if (!playedLocal) {
        await _player.stop();
        final streamData = await _ytService.getBestAudioStream(
          track.id,
          queryFallback: '${track.title} ${track.artist}',
        );

        if (streamData == null) {
          throw Exception('No stream URL found for track "${track.title}"');
        }

        await _playThroughProxy(streamData.url, streamData.totalBytes, streamData.container);
        _resolvedStreamCache[track.id] = streamData.url;
      }
      _isLoading = false;
      await _player.setSpeed(_playbackSpeed);
      await _player.setPitch(_pitch);
      _player.play();
    } catch (e) {
      debugPrint('Error playing real track "${track.title}": $e');
      _isLoading = false;
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume({Track? fallbackTrack}) async {
    if (_player.audioSource == null) {
      final trackToPlay = _currentTrack ?? fallbackTrack;
      if (trackToPlay != null) {
        await playTrack(trackToPlay);
        return;
      }
    }
    _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume / 100.0);
  }

  void dispose() {
    _proxy.stop();
    _player.dispose();
    _ytService.dispose();
  }
}
