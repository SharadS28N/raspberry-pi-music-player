import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import 'youtube_service.dart';
import 'local_stream_proxy.dart';

enum AudioTarget { phoneLocal, piSpeaker }

class AudioPlayerService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final YoutubeService _ytService = YoutubeService();
  final LocalStreamProxy _proxy = LocalStreamProxy();
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

  AudioPlayer get player => _player;
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

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get positionStream => _player.positionStream;

  AudioPlayerService() {
    _loadHistoryAndLikes();
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_player.loopMode == LoopMode.one) {
          seek(Duration.zero);
          _player.play();
        } else {
          skipToNext();
        }
      }
    });
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
    }
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

  Future<void> _playThroughProxy(String streamUrl, int totalBytes, String container, Track track) async {
    await _proxy.start();
    _proxy.setStream(streamUrl, totalBytes);
    final ext = container.isEmpty ? 'mp4' : container;
    final proxyUrl = _proxy.getProxyUrl('stream.$ext');
    final audioSource = AudioSource.uri(
      Uri.parse(proxyUrl),
      tag: _mediaItemForTrack(track),
    );
    await _player.setAudioSource(audioSource);
  }

  Future<void> playTrack(Track track) async {
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

    try {
      bool playedLocal = false;
      if (track.localPath != null && track.localPath!.isNotEmpty) {
        final file = File(track.localPath!);
        if (file.existsSync()) {
          final audioSource = AudioSource.uri(
            Uri.file(track.localPath!),
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

        try {
          final audioSource = AudioSource.uri(
            Uri.parse(streamData.url),
            headers: {'User-Agent': 'com.google.android.youtube/19.29.37 (Linux; U; Android 14)'},
            tag: _mediaItemForTrack(track),
          );
          await _player.setAudioSource(audioSource);
        } catch (_) {
          await _playThroughProxy(streamData.url, streamData.totalBytes, streamData.container, track);
        }
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

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTicker?.cancel();
    _proxy.stop();
    _player.dispose();
    _ytService.dispose();
    super.dispose();
  }
}
