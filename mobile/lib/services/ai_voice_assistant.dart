import 'package:flutter/foundation.dart';
import '../models/track.dart';
import '../models/playlist.dart';
import '../models/ai_recommendation.dart';
import 'audio_player_service.dart';
import 'equalizer_service.dart';
import 'party_service.dart';
import 'ai_music_service.dart';
import 'youtube_service.dart';

class AssistantMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final Track? relatedTrack;
  final Playlist? relatedPlaylist;
  final String? actionType;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.relatedTrack,
    this.relatedPlaylist,
    this.actionType,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiVoiceAssistant extends ChangeNotifier {
  static final AiVoiceAssistant instance = AiVoiceAssistant._internal();
  AiVoiceAssistant._internal() {
    _messages.add(
      AssistantMessage(
        id: 'msg_welcome',
        text:
            'Hello! I am your AI Music Intelligence Assistant. You can ask me to play songs, generate tailored playlists, switch audio moods, trigger bass boost, or explain your music recommendations.',
        isUser: false,
      ),
    );
  }

  final List<AssistantMessage> _messages = [];
  bool _isProcessing = false;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  Future<AssistantMessage> processInput({
    required String input,
    required AudioPlayerService audioService,
    Function(Track)? onPlayTrack,
  }) async {
    final clean = input.trim();
    if (clean.isEmpty) {
      return AssistantMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Please tell me what you would like to listen to or control.',
        isUser: false,
      );
    }

    // Add user message
    _messages.add(
      AssistantMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        text: clean,
        isUser: true,
      ),
    );
    _isProcessing = true;
    notifyListeners();

    final lower = clean.toLowerCase();
    AssistantMessage response;

    try {
      // 1. Pause Intent
      if (lower.contains('pause') || lower.contains('stop playback')) {
        audioService.pause();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Playback paused. Say "resume" whenever you are ready.',
          isUser: false,
          actionType: 'pause',
        );
      }
      // 2. Resume Intent
      else if (lower.contains('resume') || lower.contains('continue') || lower == 'play' || lower.contains('unpause')) {
        audioService.resume();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Resumed playback.',
          isUser: false,
          actionType: 'resume',
        );
      }
      // 3. Skip Next Intent
      else if (lower.contains('skip') || lower.contains('next')) {
        audioService.skipToNext();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Skipping to the next track.',
          isUser: false,
          actionType: 'skip_next',
        );
      }
      // 4. Skip Previous Intent
      else if (lower.contains('previous') || lower.contains('go back') || lower.contains('last song')) {
        audioService.skipToPrevious();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Playing the previous track.',
          isUser: false,
          actionType: 'skip_previous',
        );
      }
      // 5. Equalizer & Bass Boost Intent
      else if (lower.contains('bass') || lower.contains('boost bass') || lower.contains('equalizer')) {
        EqualizerService.instance.setBassBoost(0.8);
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Hardware Bass Boost activated with low-frequency acoustic warmth (+6dB at 60Hz).',
          isUser: false,
          actionType: 'bass_boost',
        );
      }
      // 6. Collaborative Party / Jam Session Intent
      else if (lower.contains('party') || lower.contains('jam') || lower.contains('together')) {
        final current = audioService.currentTrack;
        final ok = await PartyService.instance.createParty(initialTrack: current);
        if (ok) {
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Launched Music Party! Room code: ${PartyService.instance.roomCode}. Your peers on Wi-Fi can now join and control the shared queue.',
            isUser: false,
            actionType: 'party_created',
          );
        } else {
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: 'You are already in a collaborative party room. Code: ${PartyService.instance.roomCode}',
            isUser: false,
            actionType: 'party_active',
          );
        }
      }
      // 7. "Why this song?" / Recommendation Explanation Intent
      else if (lower.contains('why') && (lower.contains('song') || lower.contains('recommend') || lower.contains('this'))) {
        final current = audioService.currentTrack;
        if (current != null) {
          final explanation = AiMusicService.instance.explainRecommendation(current);
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: '${explanation.primaryReason}:\n• ${explanation.detailedReasons.join('\n• ')}',
            isUser: false,
            relatedTrack: current,
            actionType: 'why_recommended',
          );
        } else {
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: 'No track is currently playing. Start a song and ask me again to analyze its acoustic DNA.',
            isUser: false,
          );
        }
      }
      // 8. Generate Playlist Intent
      else if (lower.contains('playlist') || lower.contains('generate') || lower.contains('make a mix')) {
        final prompt = lower
            .replaceAll('generate a playlist for', '')
            .replaceAll('generate playlist', '')
            .replaceAll('make a playlist for', '')
            .replaceAll('create a playlist for', '')
            .replaceAll('create playlist', '')
            .trim();

        final effectivePrompt = prompt.isNotEmpty ? prompt : 'Cyberpunk late night focus';
        final playlist = await AiMusicService.instance.generatePlaylistFromPrompt(effectivePrompt);

        if (playlist.tracks.isNotEmpty && onPlayTrack != null) {
          onPlayTrack(playlist.tracks.first);
        }

        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Created AI Playlist "${playlist.title}" with ${playlist.trackCount} tracks! ${playlist.description}',
          isUser: false,
          relatedPlaylist: playlist,
          actionType: 'playlist_generated',
        );
      }
      // 9. Mood Station Intent
      else if (lower.contains('relax') ||
          lower.contains('chill') ||
          lower.contains('workout') ||
          lower.contains('focus') ||
          lower.contains('energize') ||
          lower.contains('sad')) {
        MoodCategory mood = MoodCategory.defaultMoods.first;
        if (lower.contains('relax') || lower.contains('chill')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'relax');
        } else if (lower.contains('workout')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'workout');
        } else if (lower.contains('focus')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'focus');
        } else if (lower.contains('sad')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'melancholy');
        }

        final tracks = AiMusicService.instance.getMoodRecommendations(mood);
        if (tracks.isNotEmpty && onPlayTrack != null) {
          onPlayTrack(tracks.first);
        }

        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Tuning into the ${mood.title} mood station (${mood.subtitle}). Playing "${tracks.first.title}" by ${tracks.first.artist}.',
          isUser: false,
          relatedTrack: tracks.isNotEmpty ? tracks.first : null,
          actionType: 'mood_station',
        );
      }
      // 10. Play Song / Search Intent
      else {
        String searchQuery = lower.replaceAll('play', '').trim();
        if (searchQuery.isEmpty) searchQuery = 'Top hit music';

        // Check catalog first for instant response
        final match = AiMusicService.instance.catalogTracks
            .where((t) =>
                t.title.toLowerCase().contains(searchQuery) ||
                t.artist.toLowerCase().contains(searchQuery))
            .firstOrNull;

        if (match != null && onPlayTrack != null) {
          onPlayTrack(match);
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: 'Now playing "${match.title}" by ${match.artist}.',
            isUser: false,
            relatedTrack: match,
            actionType: 'play_track',
          );
        } else {
          // Query YouTube live
          final ytTracks = await YoutubeService().searchTracks(searchQuery);
          if (ytTracks.isNotEmpty && onPlayTrack != null) {
            final t = ytTracks.first;
            onPlayTrack(t);
            response = AssistantMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              text: 'Found and playing "${t.title}" by ${t.artist}.',
              isUser: false,
              relatedTrack: t,
              actionType: 'play_track',
            );
          } else {
            response = AssistantMessage(
              id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
              text: 'Could not find any tracks matching "$searchQuery". Try asking for another title or artist.',
              isUser: false,
            );
          }
        }
      }
    } catch (e) {
      response = AssistantMessage(
        id: 'ai_err_${DateTime.now().millisecondsSinceEpoch}',
        text: 'I encountered an error processing your request: $e',
        isUser: false,
      );
    } finally {
      _isProcessing = false;
    }

    _messages.add(response);
    notifyListeners();
    return response;
  }

  void clearConversation() {
    _messages.clear();
    _messages.add(
      AssistantMessage(
        id: 'msg_welcome',
        text: 'Conversation reset. How can I assist your music listening?',
        isUser: false,
      ),
    );
    notifyListeners();
  }
}
