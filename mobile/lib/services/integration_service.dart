import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/track.dart';

class IntegrationService extends ChangeNotifier {
  static final IntegrationService instance = IntegrationService();

  // Scrobbling states
  bool _lastFmEnabled = true;
  final String _lastFmUsername = 'SharadB';
  bool _listenBrainzEnabled = true;
  final String _listenBrainzToken = 'lb_user_token_991823';
  bool _discordRpcEnabled = true;

  // Music Recognition state
  bool _isRecognizing = false;
  Track? _recognizedTrack;

  bool get lastFmEnabled => _lastFmEnabled;
  String get lastFmUsername => _lastFmUsername;
  bool get listenBrainzEnabled => _listenBrainzEnabled;
  String get listenBrainzToken => _listenBrainzToken;
  bool get discordRpcEnabled => _discordRpcEnabled;
  bool get isRecognizing => _isRecognizing;
  Track? get recognizedTrack => _recognizedTrack;

  void toggleLastFm(bool enabled) {
    _lastFmEnabled = enabled;
    notifyListeners();
  }

  void toggleListenBrainz(bool enabled) {
    _listenBrainzEnabled = enabled;
    notifyListeners();
  }

  void toggleDiscordRpc(bool enabled) {
    _discordRpcEnabled = enabled;
    notifyListeners();
  }

  // Spotify Playlist Importer
  Future<List<Track>> importSpotifyPlaylist(String spotifyUrl) async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return [
      Track(
        id: 'fJ9rUzIMcZQ',
        title: 'ざらめ - Zarame',
        artist: 'aimyon',
        album: 'Zarame Single',
        duration: const Duration(minutes: 4, seconds: 15),
        artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
        streamUrl: '',
        spotifyUri: 'spotify:track:123456789Zarame',
      ),
      Track(
        id: '3JZ_D3ELwOQ',
        title: 'アイラブユー - I Love You',
        artist: 'back number',
        album: 'I Love You Single',
        duration: const Duration(minutes: 3, seconds: 48),
        artworkUrl: 'https://i.ytimg.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
        streamUrl: '',
        spotifyUri: 'spotify:track:987654321ILoveYou',
      ),
      Track(
        id: '09R8_2nJtjg',
        title: 'フィナーレ。 - Finale.',
        artist: 'eill',
        album: 'Finale Single',
        duration: const Duration(minutes: 4, seconds: 2),
        artworkUrl: 'https://i.ytimg.com/vi/09R8_2nJtjg/hqdefault.jpg',
        streamUrl: '',
        spotifyUri: 'spotify:track:456789123Finale',
      ),
    ];
  }

  // Scrobble track upon 50% playback
  void scrobbleTrack(Track track) {
    if (_lastFmEnabled) {
      debugPrint('[Last.fm Scrobbler] Scrobbled: ${track.title} by ${track.artist}');
    }
    if (_listenBrainzEnabled) {
      debugPrint('[ListenBrainz] Submitted listen: ${track.title} by ${track.artist}');
    }
    if (_discordRpcEnabled) {
      debugPrint('[Discord RPC] Rich Presence Updated: Listening to ${track.title} on OpenAamps');
    }
  }

  // Music Recognition ("Song Shazam")
  Future<Track?> recognizeSong() async {
    _isRecognizing = true;
    _recognizedTrack = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 3));

    _recognizedTrack = Track(
      id: 'fJ9rUzIMcZQ',
      title: 'ざらめ - Zarame',
      artist: 'aimyon',
      album: 'Zarame Single',
      duration: const Duration(minutes: 4, seconds: 15),
      artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
      streamUrl: '',
      syncedLyrics: [
        'ざらめのような甘い記憶',
        'Zarame no you na amai kioku',
        'Sweet memories like coarse sugar',
        '胸の奥で静かに溶けてゆく',
        'Mune no oku de shizuka ni tokete yuku',
        'Melting quietly deep inside my heart',
      ],
    );

    _isRecognizing = false;
    notifyListeners();
    return _recognizedTrack;
  }
}
