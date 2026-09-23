import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_aamps/services/ai_voice_assistant.dart';
import 'package:open_aamps/services/audio_player_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Voice & Natural Language Parser Intent Tests', () {
    late AudioPlayerService audioService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      audioService = AudioPlayerService();
    });

    test('Parses pause playback command correctly', () async {
      final res = await AiVoiceAssistant.instance.processInput(
        input: 'pause the music',
        audioService: audioService,
      );

      expect(res.actionType, equals('pause'));
      expect(res.text.toLowerCase(), contains('paused'));
    });

    test('Parses resume command correctly', () async {
      final res = await AiVoiceAssistant.instance.processInput(
        input: 'resume playing',
        audioService: audioService,
      );

      expect(res.actionType, equals('resume'));
      expect(res.text.toLowerCase(), contains('resumed'));
    });

    test('Parses skip next command correctly', () async {
      final res = await AiVoiceAssistant.instance.processInput(
        input: 'skip this song',
        audioService: audioService,
      );

      expect(res.actionType, equals('skip_next'));
    });

    test('Parses hardware bass boost command correctly', () async {
      final res = await AiVoiceAssistant.instance.processInput(
        input: 'boost the bass',
        audioService: audioService,
      );

      expect(res.actionType, equals('bass_boost'));
      expect(res.text.toLowerCase(), contains('bass boost'));
    });

    test('Parses mood station command correctly', () async {
      final res = await AiVoiceAssistant.instance.processInput(
        input: 'play some chill relax music',
        audioService: audioService,
      );

      expect(res.actionType, equals('mood_station'));
      expect(res.text.toLowerCase(), contains('relax'));
    });
  });
}
