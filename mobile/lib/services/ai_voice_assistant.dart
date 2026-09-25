import 'dart:async';
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
  final Map<String, String>? parameters;

  AssistantMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.relatedTrack,
    this.relatedPlaylist,
    this.actionType,
    this.parameters,
  }) : timestamp = timestamp ?? DateTime.now();
}

class AiVoiceAssistant extends ChangeNotifier {
  static final AiVoiceAssistant instance = AiVoiceAssistant._internal();
  AiVoiceAssistant._internal() {
    _messages.add(
      AssistantMessage(
        id: 'msg_welcome',
        text:
            'Hello! I am your AI Music Intelligence Assistant. Ask me anything about music theory, acoustic DNA, BPM, song history, hardware DSP, or tell me what to play with custom parameters.',
        isUser: false,
        parameters: {
          'Engine': 'Acoustic Intelligence v2',
          'DSP': 'Hardware ALSA',
          'Codec Support': 'FLAC 24-bit / AAC',
        },
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
        text: 'Please tell me what you would like to listen to or ask a music question.',
        isUser: false,
      );
    }

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
      // 1. Playback State Commands
      if (lower.contains('pause') || lower.contains('stop playback')) {
        audioService.pause();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Playback paused. Say "resume" whenever you are ready.',
          isUser: false,
          actionType: 'pause',
        );
      } else if (lower.contains('resume') ||
          lower.contains('continue') ||
          lower == 'play' ||
          lower.contains('unpause')) {
        audioService.resume();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Resumed playback on ${audioService.target == AudioTarget.piSpeaker ? 'Raspberry Pi Speaker' : 'Device Audio'}.',
          isUser: false,
          actionType: 'resume',
        );
      } else if (lower.contains('skip') || lower.contains('next track') || lower == 'next') {
        audioService.skipToNext();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Skipping to the next track.',
          isUser: false,
          actionType: 'skip_next',
        );
      } else if (lower.contains('previous') || lower.contains('go back') || lower.contains('last song')) {
        audioService.skipToPrevious();
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Playing the previous track.',
          isUser: false,
          actionType: 'skip_previous',
        );
      }
      // 2. Hardware Bass Boost & Equalizer Commands
      else if (lower.contains('bass') || lower.contains('boost bass') || lower.contains('equalizer')) {
        EqualizerService.instance.setBassBoost(0.8);
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Hardware Bass Boost activated with low-frequency acoustic warmth (+6dB at 60Hz sub-bass filter).',
          isUser: false,
          actionType: 'bass_boost',
          parameters: {
            'Sub-Bass (60Hz)': '+6.0 dB',
            'Warmth (250Hz)': '+2.5 dB',
            'Filter Mode': 'Hardware ALSA DSP',
          },
        );
      }
      // 3. Collaborative Party Listening Command
      else if (lower.contains('party') || lower.contains('jam session') || lower.contains('listen together')) {
        final current = audioService.currentTrack;
        final ok = await PartyService.instance.createParty(initialTrack: current);
        final code = PartyService.instance.roomCode;
        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: ok
              ? 'Launched Music Party room! Share room code "$code" with peers on Wi-Fi for synchronized playback.'
              : 'You are currently in Music Party room "$code".',
          isUser: false,
          actionType: 'party_created',
          parameters: {
            'Room Code': code,
            'Sync Protocol': 'Sub-200ms Deadband',
            'Queue Mode': 'Democratic Upvoting',
          },
        );
      }
      // 4. "Why this song?" / Acoustic Recommendation Explanation
      else if (lower.contains('why') && (lower.contains('song') || lower.contains('recommend') || lower.contains('this track'))) {
        final current = audioService.currentTrack;
        if (current != null) {
          final explanation = AiMusicService.instance.explainRecommendation(current);
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: '${explanation.primaryReason}\n\nKey Acoustic Factors:\n• ${explanation.detailedReasons.join('\n• ')}',
            isUser: false,
            relatedTrack: current,
            actionType: 'why_recommended',
            parameters: {
              'Match Score': '${(explanation.matchPercentage * 100).toInt()}%',
              'Energy': '${(current.energy * 100).toInt()}%',
              'Valence': '${(current.valence * 100).toInt()}%',
              'Tempo': '${current.tempo.toInt()} BPM',
            },
          );
        } else {
          response = AssistantMessage(
            id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
            text: 'No song is currently active. Play any track and ask me again to inspect its acoustic coordinates.',
            isUser: false,
          );
        }
      }
      // 5. Questions & Answers / Parameter Inquiries
      else if (_isQuestionOrParameterQuery(lower)) {
        response = await _handleQuestionAndParameters(clean, lower, onPlayTrack);
      }
      // 6. Generate Playlist with Prompt
      else if (lower.contains('playlist') || lower.contains('generate mix') || lower.contains('create mix')) {
        final prompt = lower
            .replaceAll('generate a playlist for', '')
            .replaceAll('generate playlist', '')
            .replaceAll('make a playlist for', '')
            .replaceAll('create a playlist for', '')
            .replaceAll('create playlist', '')
            .replaceAll('make a mix', '')
            .trim();

        final effectivePrompt = prompt.isNotEmpty ? prompt : 'Cyberpunk late night focus';
        final playlist = await AiMusicService.instance.generatePlaylistFromPrompt(effectivePrompt);

        if (playlist.tracks.isNotEmpty && onPlayTrack != null) {
          onPlayTrack(playlist.tracks.first);
        }

        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Generated AI Playlist "${playlist.title}" with ${playlist.trackCount} tracks.\n${playlist.description}',
          isUser: false,
          relatedPlaylist: playlist,
          actionType: 'playlist_generated',
          parameters: {
            'Tracks': '${playlist.trackCount}',
            'Prompt': effectivePrompt,
            'Style': 'Monochrome Spotify Curated',
          },
        );
      }
      // 7. Mood Stations
      else if (lower.contains('relax') ||
          lower.contains('chill') ||
          lower.contains('workout') ||
          lower.contains('focus') ||
          lower.contains('energize') ||
          lower.contains('sad') ||
          lower.contains('melancholy')) {
        MoodCategory mood = MoodCategory.defaultMoods.first;
        if (lower.contains('relax') || lower.contains('chill')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'relax');
        } else if (lower.contains('workout') || lower.contains('gym')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'workout');
        } else if (lower.contains('focus') || lower.contains('study')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'focus');
        } else if (lower.contains('sad') || lower.contains('melancholy')) {
          mood = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'melancholy');
        }

        final tracks = AiMusicService.instance.getMoodRecommendations(mood);
        if (tracks.isNotEmpty && onPlayTrack != null) {
          onPlayTrack(tracks.first);
        }

        response = AssistantMessage(
          id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Tuning into the ${mood.title} mood station (${mood.subtitle}). Now playing "${tracks.first.title}" by ${tracks.first.artist}.',
          isUser: false,
          relatedTrack: tracks.isNotEmpty ? tracks.first : null,
          actionType: 'mood_station',
          parameters: {
            'Mood': mood.title,
            'Target Energy': '${(mood.targetEnergy * 100).toInt()}%',
            'Target Valence': '${(mood.targetValence * 100).toInt()}%',
          },
        );
      }
      // 8. Direct Song Play / Search
      else {
        String searchQuery = lower.replaceAll('play', '').trim();
        if (searchQuery.isEmpty) searchQuery = 'Top hit music';

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
            parameters: {
              'Codec': match.codec,
              'Tempo': '${match.tempo.toInt()} BPM',
              'Energy': '${(match.energy * 100).toInt()}%',
            },
          );
        } else {
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
              parameters: {
                'Source': 'YouTube Live Stream',
                'Title': t.title,
                'Artist': t.artist,
              },
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

  bool _isQuestionOrParameterQuery(String lower) {
    if (lower.contains('?') ||
        lower.startsWith('who') ||
        lower.startsWith('what') ||
        lower.startsWith('how') ||
        lower.startsWith('why') ||
        lower.startsWith('explain') ||
        lower.startsWith('analyze') ||
        lower.startsWith('breakdown') ||
        lower.startsWith('tell me') ||
        lower.startsWith('compare') ||
        lower.startsWith('recommend') ||
        lower.contains('structure') ||
        lower.contains('theory') ||
        lower.contains('bpm') ||
        lower.contains('tempo') ||
        lower.contains('flac') ||
        lower.contains('acoustic vector') ||
        lower.contains('taste vector') ||
        lower.contains('raspberry pi') ||
        lower.contains('chords') ||
        lower.contains('energy >') ||
        lower.contains('bpm >') ||
        lower.contains('bpm <')) {
      return true;
    }
    return false;
  }

  Future<AssistantMessage> _handleQuestionAndParameters(
    String raw,
    String lower,
    Function(Track)? onPlayTrack,
  ) async {
    // Autonomous On-Device Music Intelligence Knowledge Base (Zero-Config / 100% Local)

    // Category A: BPM / Tempo & Acoustic Parameter Search
    if (lower.contains('bpm') || lower.contains('tempo')) {
      // Check if user is asking for tracks matching BPM parameter
      final bpmMatch = RegExp(r'(\d{2,3})\s*bpm').firstMatch(lower);
      final targetBpm = bpmMatch != null ? int.tryParse(bpmMatch.group(1)!) : null;

      if (targetBpm != null || lower.contains('workout') || lower.contains('fast') || lower.contains('running')) {
        final effectiveBpm = targetBpm ?? 160;
        final matching = AiMusicService.instance.catalogTracks
            .where((t) => (t.tempo - effectiveBpm).abs() <= 25)
            .toList();

        final best = matching.isNotEmpty ? matching.first : AiMusicService.instance.catalogTracks[3]; // Blinding Lights (171 BPM)
        if (onPlayTrack != null) onPlayTrack(best);

        return AssistantMessage(
          id: 'ai_param_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Matched songs for target tempo ~$effectiveBpm BPM:\n'
              '• "${best.title}" by ${best.artist} (${best.tempo.toInt()} BPM, ${(best.energy * 100).toInt()}% energy)\n'
              'Ideal for rhythm synchronization and high-cadence listening.',
          isUser: false,
          relatedTrack: best,
          parameters: {
            'Target BPM': '$effectiveBpm',
            'Actual Tempo': '${best.tempo.toInt()} BPM',
            'Cadence': effectiveBpm >= 150 ? 'High Energy / Running' : 'Moderate Flow',
            'Key / Mode': 'Minor',
          },
        );
      }

      // Check specific song tempo inquiry
      if (lower.contains('yellow')) {
        return AssistantMessage(
          id: 'ai_tempo_${DateTime.now().millisecondsSinceEpoch}',
          text: '"Yellow" by Coldplay is performed at 120 BPM in 4/4 time signature. Key is B Major.',
          isUser: false,
          actionType: 'music_theory_query',
          parameters: {
            'Track': 'Yellow',
            'Tempo (BPM)': '120 BPM',
            'Time Signature': '4/4',
            'Key': 'B Major',
            'Acousticness': '40%',
          },
        );
      } else if (lower.contains('blinding lights')) {
        return AssistantMessage(
          id: 'ai_tempo_${DateTime.now().millisecondsSinceEpoch}',
          text: '"Blinding Lights" by The Weeknd runs at a high-speed 171 BPM with an 80s synth-pop syncopation in F Minor.',
          isUser: false,
          actionType: 'music_theory_query',
          parameters: {'BPM': '171', 'Key': 'F Minor', 'Energy': '88%', 'Genre': 'Synthwave'},
        );
      }
    }

    // Category B: Music Theory & Song Structure (Bohemian Rhapsody, Yellow)
    if (lower.contains('bohemian rhapsody')) {
      return AssistantMessage(
        id: 'ai_theory_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Composed by Freddie Mercury for Queen in 1975, "Bohemian Rhapsody" has no recurring chorus. It consists of 6 distinct sections:\n'
            '1. A cappella intro (Bb Major)\n'
            '2. Piano ballad\n'
            '3. Brian May guitar solo\n'
            '4. Operatic interlude (Galileo, Figaro, Scaramouche)\n'
            '5. Hard rock riff section\n'
            '6. Reflective outro ("Nothing really matters")',
        isUser: false,
        actionType: 'music_theory_query',
        parameters: {
          'Track': 'Bohemian Rhapsody',
          'Composer': 'Freddie Mercury',
          'Structure': 'Multi-Movement Suite',
          'Movements': 'Intro -> Ballad -> Opera -> Rock -> Outro',
          'Key Center': 'Bb Major / Eb Major',
        },
      );
    }

    if (lower.contains('yellow') && (lower.contains('chord') || lower.contains('written') || lower.contains('theory'))) {
      return AssistantMessage(
        id: 'ai_yellow_${DateTime.now().millisecondsSinceEpoch}',
        text: '"Yellow" was composed by Coldplay for their 2000 debut album "Parachutes".\n'
            '• Chords: B - F# - E - G#m\n'
            '• Special guitar tuning: E-A-B-G-B-d# (giving the acoustic guitar its shimmering, open resonance).\n'
            '• Acoustic Vector: Energy 0.70, Valence 0.85 (Uplifting and warm).',
        isUser: false,
        actionType: 'music_theory_query',
        parameters: {
          'Tuning': 'E-A-B-G-B-d#',
          'Key': 'B Major',
          'Chords': 'B, F#, E, G#m',
          'Acoustic Balance': 'Warm Indie Rock',
        },
      );
    }

    // Category C: Audio Formats & Codecs (FLAC vs AAC)
    if (lower.contains('flac') || lower.contains('aac') || lower.contains('codec') || lower.contains('24-bit') || lower.contains('lossless')) {
      return AssistantMessage(
        id: 'ai_codec_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Audio Codec Comparison for OpenAamps DSP:\n\n'
            '• FLAC 24-bit / 96kHz: Free Lossless Audio Codec. Bit-perfect studio master reproduction with up to 144 dB of dynamic range (vs 96 dB for 16-bit CD). Ideal for the Raspberry Pi HiFi DAC.\n'
            '• AAC 320kbps: Advanced Audio Coding. High-efficiency psychoacoustic lossy codec, offering transparent mobile listening at ~10x smaller file sizes.\n'
            '• OPUS 160kbps: Ultra-low latency voice and music codec with remarkable high-frequency preservation.',
        isUser: false,
        actionType: 'audio_dsp_query',
        parameters: {
          'FLAC Resolution': '24-bit / 96kHz (144 dB)',
          'AAC Bitrate': '320 kbps (Stereo)',
          'DSP Pipeline': 'Bit-perfect ALSA',
          'Target Output': 'Raspberry Pi DAC Hat',
        },
      );
    }

    // Category D: Acoustic Taste Vector & Preference Learning
    if (lower.contains('taste vector') || lower.contains('acoustic vector') || lower.contains('acoustic dna') || lower.contains('how do you learn') || lower.contains('how do acoustic')) {
      return AssistantMessage(
        id: 'ai_vector_${DateTime.now().millisecondsSinceEpoch}',
        text: 'OpenAamps Acoustic Preference Learning operates on a 5-dimensional coordinate vector:\n'
            '• [Energy, Valence, Danceability, Acousticness, Tempo]\n\n'
            'Algorithm Mechanics:\n'
            '1. Track Completion (>75%): +0.05 positive shift toward the song\'s acoustic coordinates.\n'
            '2. Early Skip (<30s): -0.08 negative penalty dampening unwanted frequencies.\n'
            '3. Cosine Similarity Matching: Computes Euclidean / Cosine distance between your profile vector and candidate tracks.',
        isUser: false,
        actionType: 'ai_system_query',
        parameters: {
          'Acoustic Dimensions': '5 (Energy, Valence, Danceability, Acousticness, Tempo)',
          'Scoring Metric': 'Euclidean Distance / Cosine Similarity',
          'Live Tracking': 'Dynamic EWMA Adaptation',
          'Completion Reward': '+0.05 shift',
        },
      );
    }

    // Category E: Raspberry Pi Hardware Streaming Architecture
    if (lower.contains('raspberry pi') || lower.contains('pi-aamps') || lower.contains('hardware stream') || lower.contains('alsa') || lower.contains('raspberry')) {
      return AssistantMessage(
        id: 'ai_pi_${DateTime.now().millisecondsSinceEpoch}',
        text: 'The OpenAamps Raspberry Pi Streamer connects via WebSocket/TCP to the Pi hardware daemon:\n'
            '• Output: Direct 3.5mm analog jack or I2S HiFi DAC Hat (PCM5102A/PCM5122).\n'
            '• Engine: ALSA hardware audio mixer with software equalizer and bass-boost filters.\n'
            '• Latency: Sub-200ms LAN buffer over Wi-Fi, supporting synchronized multi-room Party audio.',
        isUser: false,
        actionType: 'hardware_stream_query',
        parameters: {
          'Hardware Host': 'Raspberry Pi 4 / Pi 5',
          'Audio Subsystem': 'ALSA Linux / MPD Direct',
          'Sync Mechanism': 'Network RPC / WebSocket',
          'Buffer Latency': '<200ms',
        },
      );
    }

    // Default intelligent fallback for open-ended music questions
    return AssistantMessage(
      id: 'ai_answer_${DateTime.now().millisecondsSinceEpoch}',
      text: 'Here is what I analyzed regarding "$raw":\n'
          'Our acoustic intelligence engine evaluates music across tempo, mood, harmonic composition, and audio bitrates. '
          'You can ask me to find songs by BPM, tune equalizer bands, explain song chord structures, or generate customized playlists.',
      isUser: false,
      parameters: {
        'Status': 'Acoustic Intelligence Active',
        'Query Parameters': raw.length > 25 ? '${raw.substring(0, 25)}...' : raw,
        'Suggestion': 'Try: "What is the BPM of Blinding Lights?" or "Explain 24-bit FLAC"',
      },
    );
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
