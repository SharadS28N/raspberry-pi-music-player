import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'youtube_service.dart';
import 'local_stream_proxy.dart';
import 'pi_aamps_service.dart';

enum AudioTarget { phoneLocal, piSpeaker }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  final LocalStreamProxy _proxy = LocalStreamProxy();
  final PiAampsService _piService = PiAampsService.instance;
  AudioTarget _target = AudioTarget.phoneLocal;
  Track? _currentTrack;
  bool _isLoading = false;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  double _crossfadeDuration = 3.0;
  bool _loudnessNormalization = true;

  // Sleep timer state
  Timer? _sleepTimer;
  Timer? _sleepTicker;
  DateTime? _sleepEndTime;
  final ValueNotifier<Duration?> _sleepTimerRemaining = ValueNotifier(null);

  // Playback History & Liked Songs
  final List<Track> _history = [];
  final Set<String> _likedIds = {};
  final List<Track> _likedTracks = [];

  // Playlist Queue
  final List<Track> _queue = [];
  int _queueIndex = -1;

  // Stream Controllers for unified local & Pi telemetry
  final StreamController<PlayerState> _playerStateController = StreamController<PlayerState>.broadcast();
  final StreamController<Duration?> _durationController = StreamController<Duration?>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

  AudioPlayer get player => _player;
  PiAampsService get piService => _piService;
  AudioTarget get target => _target;
  Track? get currentTrack => _currentTrack;
  bool get isLoading => _isLoading;
  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  double get crossfadeDuration => _crossfadeDuration;
  bool get loudnessNormalization => _loudnessNormalization;

  ValueListenable<Duration?> get sleepTimerRemaining => _sleepTimerRemaining;
  bool get isSleepTimerActive => _sleepTimer != null && _sleepTimer!.isActive;

  List<Track> get history => List.unmodifiable(_history);
  List<Track> get likedTracks => List.unmodifiable(_likedTracks);
  List<Track> get queue => List.unmodifiable(_queue);
  int get queueIndex => _queueIndex;

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<Duration> get positionStream => _positionController.stream;

  Duration get currentPosition {
    if (_target == AudioTarget.piSpeaker) {
      return Duration(milliseconds: (_piService.currentState.currentPosition * 1000).toInt());
    }
    return _player.position;
  }

  Duration get currentDuration {
    if (_target == AudioTarget.piSpeaker) {
      final d = _piService.currentState.duration;
      if (d > 0) return Duration(milliseconds: (d * 1000).toInt());
    }
    return _player.duration ?? (_currentTrack?.duration ?? Duration.zero);
  }

  AudioPlayerService() {
    _loadHistoryAndLikes();

    // Local player listeners
    _player.playerStateStream.listen((state) {
      if (_target == AudioTarget.phoneLocal) {
        _playerStateController.add(state);
      }
      if (state.processingState == ProcessingState.completed) {
        if (_player.loopMode == LoopMode.one) {
          seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
      }
    });

    _player.durationStream.listen((dur) {
      if (_target == AudioTarget.phoneLocal) {
        _durationController.add(dur);
      }
      if (dur != null && dur > Duration.zero && _currentTrack != null) {
        if (_currentTrack!.duration == Duration.zero) {
          _currentTrack = _currentTrack!.copyWith(duration: dur);
          notifyListeners();
        }
      }
    });

    _player.positionStream.listen((pos) {
      if (_target == AudioTarget.phoneLocal) {
        _positionController.add(pos);
      }
    });

    // Raspberry Pi telemetry listener
    _piService.stateStream.listen((piState) {
      if (_target == AudioTarget.piSpeaker) {
        _positionController.add(Duration(milliseconds: (piState.currentPosition * 1000).toInt()));
        if (piState.duration > 0) {
          _durationController.add(Duration(milliseconds: (piState.duration * 1000).toInt()));
        }
        _playerStateController.add(
          PlayerState(
            piState.isPlaying,
            piState.isPlaying ? ProcessingState.ready : ProcessingState.idle,
          ),
        );
      }
    });

    _player.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace st) async {
        debugPrint('Playback error observed on local player: $e');
        if (_currentTrack != null && !_currentTrack!.isLocal && _resolvedStreamCache.containsKey(_currentTrack!.id)) {
          final url = _resolvedStreamCache[_currentTrack!.id];
          if (url != null) {
            try {
              await _playThroughProxy(url, 'mp4', _currentTrack!);
              _player.play();
            } catch (_) {}
          }
        }
      },
    );
  }

  Future<void> _loadHistoryAndLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('playback_history') ?? [];
      _history.clear();
      for (var s in historyJson) {
        try {
          _history.add(Track.fromJson(jsonDecode(s)));
        } catch (_) {}
      }

      final likesJson = prefs.getStringList('liked_tracks') ?? [];
      _likedTracks.clear();
      _likedIds.clear();
      for (var s in likesJson) {
        try {
          final t = Track.fromJson(jsonDecode(s));
          _likedTracks.add(t);
          _likedIds.add(t.id);
        } catch (_) {}
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _history.take(50).map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('playback_history', list);
    } catch (_) {}
  }

  Future<void> _saveLikes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _likedTracks.map((t) => jsonEncode(t.toJson())).toList();
      await prefs.setStringList('liked_tracks', list);
    } catch (_) {}
  }

  bool isLiked(String trackId) => _likedIds.contains(trackId);

  void toggleLike(Track track) {
    if (_likedIds.contains(track.id)) {
      _likedIds.remove(track.id);
      _likedTracks.removeWhere((t) => t.id == track.id);
    } else {
      _likedIds.add(track.id);
      _likedTracks.insert(0, track);
    }
    _saveLikes();
    notifyListeners();
  }

  void setSleepTimer(Duration duration) {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();

    _sleepEndTime = DateTime.now().add(duration);
    _sleepTimerRemaining.value = duration;

    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (ticker) {
      if (_sleepEndTime == null) {
        ticker.cancel();
        return;
      }
      final diff = _sleepEndTime!.difference(DateTime.now());
      if (diff <= Duration.zero) {
        ticker.cancel();
        _sleepTimer?.cancel();
        _sleepTimer = null;
        _sleepEndTime = null;
        _sleepTimerRemaining.value = null;
        pause();
      } else {
        _sleepTimerRemaining.value = diff;
      }
    });

    _sleepTimer = Timer(duration, () {
      _sleepTicker?.cancel();
      _sleepTimer = null;
      _sleepEndTime = null;
      _sleepTimerRemaining.value = null;
      pause();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepTimer = null;
    _sleepTicker = null;
    _sleepEndTime = null;
    _sleepTimerRemaining.value = null;
  }

  void setAudioTarget(AudioTarget newTarget) {
    _target = newTarget;
    if (_target == AudioTarget.piSpeaker) {
      _player.pause();
      if (_currentTrack != null) {
        _piService.playTrackOnPi(_currentTrack!);
      }
    } else {
      _piService.pause();
      if (_currentTrack != null) {
        resume();
      }
    }
    notifyListeners();
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    if (_target == AudioTarget.phoneLocal) {
      await _player.setSpeed(speed);
    }
    notifyListeners();
  }

  Future<void> setPitch(double pitchVal) async {
    _pitch = pitchVal;
    if (_target == AudioTarget.phoneLocal) {
      await _player.setPitch(pitchVal);
    }
    notifyListeners();
  }

  void setCrossfade(double seconds) {
    _crossfadeDuration = seconds;
    notifyListeners();
  }

  void setLoudnessNormalization(bool enabled) {
    _loudnessNormalization = enabled;
    notifyListeners();
  }

  LoopMode get loopMode => _player.loopMode;
  Stream<LoopMode> get loopModeStream => _player.loopModeStream;
  Stream<bool> get shuffleModeEnabledStream => _player.shuffleModeEnabledStream;
  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);
  Future<void> setShuffleModeEnabled(bool enabled) => _player.setShuffleModeEnabled(enabled);

  final Map<String, String> _resolvedStreamCache = {};

  MediaItem _mediaItemForTrack(Track track) {
    Uri? artUri;
    if (track.artworkUrl.isNotEmpty &&
        (track.artworkUrl.startsWith('http://') || track.artworkUrl.startsWith('https://'))) {
      artUri = Uri.tryParse(track.artworkUrl);
    }
    return MediaItem(
      id: track.id,
      album: track.album.isNotEmpty ? track.album : 'OpenAamps',
      title: track.title,
      artist: track.artist.isNotEmpty ? track.artist : 'OpenAamps Artist',
      artUri: artUri,
      duration: track.duration > Duration.zero ? track.duration : null,
      playable: true,
    );
  }

  void setQueue(List<Track> tracks, {int startIndex = 0}) {
    _queue.clear();
    _queue.addAll(tracks);
    _queueIndex = startIndex;
    if (startIndex >= 0 && startIndex < _queue.length) {
      playTrack(_queue[startIndex]);
    }
  }

  void addToQueue(Track track) {
    _queue.add(track);
    notifyListeners();
  }

  Future<void> skipToNext() async {
    if (_queue.isNotEmpty && _queueIndex + 1 < _queue.length) {
      _queueIndex++;
      await playTrack(_queue[_queueIndex]);
    } else if (_player.loopMode == LoopMode.all && _queue.isNotEmpty) {
      _queueIndex = 0;
      await playTrack(_queue[0]);
    }
  }

  Future<void> skipToPrevious() async {
    if (_player.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (_queueIndex > 0 && _queue.isNotEmpty) {
      _queueIndex--;
      await playTrack(_queue[_queueIndex]);
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> _playThroughProxy(String streamUrl, String container, Track track) async {
    await _proxy.start();
    _proxy.setStream(streamUrl);
    final ext = container.isEmpty ? 'mp4' : container;
    final proxyUrl = _proxy.getProxyUrl('stream.$ext');
    final audioSource = AudioSource.uri(
      Uri.parse(proxyUrl),
      tag: _mediaItemForTrack(track),
    );
    await _player.setAudioSource(audioSource);
  }

  Future<void> playTrack(Track track) async {
    // Proactively verify notification permissions for Android 13+ lockscreen / notification panel
    try {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.notification.request();
      }
    } catch (_) {}

    _currentTrack = track;
    _isLoading = true;

    // Update queue position
    final existingIdx = _queue.indexWhere((t) => t.id == track.id);
    if (existingIdx != -1) {
      _queueIndex = existingIdx;
    } else {
      _queue.insert(0, track);
      _queueIndex = 0;
    }

    // Record into history
    _history.removeWhere((t) => t.id == track.id);
    _history.insert(0, track);
    _saveHistory();
    notifyListeners();

    // If target is Pi Speaker, dispatch to Raspberry Pi
    if (_target == AudioTarget.piSpeaker) {
      _isLoading = false;
      notifyListeners();
      await _piService.playTrackOnPi(track);
      return;
    }

    try {
      bool playedLocal = false;
      if (track.localPath != null && track.localPath!.isNotEmpty) {
        var file = File(track.localPath!);
        if (!file.existsSync() && track.localPath!.startsWith('/storage/emulated/0/')) {
          final alt = File(track.localPath!.replaceFirst('/storage/emulated/0/', '/sdcard/'));
          if (alt.existsSync()) file = alt;
        } else if (!file.existsSync() && track.localPath!.startsWith('/sdcard/')) {
          final alt = File(track.localPath!.replaceFirst('/sdcard/', '/storage/emulated/0/'));
          if (alt.existsSync()) file = alt;
        }
        if (file.existsSync()) {
          final audioSource = AudioSource.uri(
            Uri.file(file.path),
            tag: _mediaItemForTrack(track),
          );
          await _player.setAudioSource(audioSource);
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

        final codecName = streamData.container.toLowerCase() == 'mp4' ? 'AAC' : 'OPUS';
        _currentTrack = _currentTrack!.copyWith(codec: codecName);
        notifyListeners();

        final desktopHeaders = {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Referer': 'https://www.youtube.com/',
        };

        try {
          final audioSource = AudioSource.uri(
            Uri.parse(streamData.url),
            headers: desktopHeaders,
            tag: _mediaItemForTrack(_currentTrack!),
          );
          await _player.setAudioSource(audioSource);
          _resolvedStreamCache[track.id] = streamData.url;
        } catch (e) {
          debugPrint('Direct audio source failed, falling back to proxy: $e');
          await _playThroughProxy(streamData.url, streamData.container, _currentTrack!);
          _resolvedStreamCache[track.id] = streamData.url;
        }
      }
      _isLoading = false;
      await _player.setSpeed(_playbackSpeed);
      await _player.setPitch(_pitch);
      _player.play();
    } catch (e) {
      debugPrint('Error playing track "${track.title}": $e');
      _isLoading = false;
    }
  }

  Future<void> pause() async {
    if (_target == AudioTarget.piSpeaker) {
      await _piService.pause();
    } else {
      await _player.pause();
    }
    notifyListeners();
  }

  Future<void> resume({Track? fallbackTrack}) async {
    if (_target == AudioTarget.piSpeaker) {
      final trackToPlay = _currentTrack ?? fallbackTrack;
      if (trackToPlay != null) {
        await _piService.playTrackOnPi(trackToPlay);
      } else {
        await _piService.resume();
      }
      notifyListeners();
      return;
    }
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
    if (_target == AudioTarget.piSpeaker) {
      await _piService.seek(position.inSeconds.toDouble());
    } else {
      await _player.seek(position);
    }
    notifyListeners();
  }

  Future<void> setVolume(double volume) async {
    if (_target == AudioTarget.piSpeaker) {
      await _piService.setVolume(volume.toInt());
    } else {
      await _player.setVolume(volume / 100.0);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _proxy.stop();
    _playerStateController.close();
    _durationController.close();
    _positionController.close();
    _player.dispose();
    _ytService.dispose();
    super.dispose();
  }
}
