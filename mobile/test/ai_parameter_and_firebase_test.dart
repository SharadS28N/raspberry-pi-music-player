import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_aamps/services/ai_voice_assistant.dart';
import 'package:open_aamps/services/audio_player_service.dart';
import 'package:open_aamps/services/firebase_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AI Voice Assistant Multi-Parameter Testing', () {
    late AiVoiceAssistant assistant;
    late AudioPlayerService audioService;

    setUp(() {
      audioService = AudioPlayerService();
      assistant = AiVoiceAssistant.instance;
    });

    test('BPM and Tempo Query returns structured parameters', () async {
      final msg = await assistant.processInput(
        input: 'what is the bpm of yellow by coldplay',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('music_theory_query'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!['Track'], equals('Yellow'));
      expect(msg.parameters!['Tempo (BPM)'], equals('120 BPM'));
      expect(msg.parameters!['Time Signature'], equals('4/4'));
      expect(msg.parameters!['Key'], contains('B Major'));
    });

    test('Song Structure Analysis for Bohemian Rhapsody returns multi-movement parameters', () async {
      final msg = await assistant.processInput(
        input: 'analyze bohemian rhapsody song structure',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('music_theory_query'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!['Structure'], equals('Multi-Movement Suite'));
      expect(msg.parameters!['Movements'], equals('Intro -> Ballad -> Opera -> Rock -> Outro'));
      expect(msg.parameters!['Key Center'], contains('Bb Major'));
    });

    test('Audio Codec and Bitrate Comparison query returns technical parameters', () async {
      final msg = await assistant.processInput(
        input: 'compare flac vs aac audio quality and bitrate',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('audio_dsp_query'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!['FLAC Resolution'], contains('24-bit / 96kHz'));
      expect(msg.parameters!['AAC Bitrate'], contains('320 kbps'));
      expect(msg.parameters!['DSP Pipeline'], equals('Bit-perfect ALSA'));
    });

    test('Acoustic Taste Vector query returns vector coordinates', () async {
      final msg = await assistant.processInput(
        input: 'how do acoustic taste vectors work',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('ai_system_query'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!['Acoustic Dimensions'], equals('5 (Energy, Valence, Danceability, Acousticness, Tempo)'));
      expect(msg.parameters!['Scoring Metric'], contains('Euclidean Distance'));
      expect(msg.parameters!['Live Tracking'], equals('Dynamic EWMA Adaptation'));
    });

    test('Hardware Raspberry Pi audio streaming query returns architecture specs', () async {
      final msg = await assistant.processInput(
        input: 'explain raspberry pi audio hardware output',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('hardware_stream_query'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!['Hardware Host'], equals('Raspberry Pi 4 / Pi 5'));
      expect(msg.parameters!['Audio Subsystem'], equals('ALSA Linux / MPD Direct'));
      expect(msg.parameters!['Sync Mechanism'], equals('Network RPC / WebSocket'));
    });

    test('Party Mode command returns room code parameters', () async {
      final msg = await assistant.processInput(
        input: 'start music party with friends',
        audioService: audioService,
      );
      expect(msg.isUser, isFalse);
      expect(msg.actionType, equals('party_created'));
      expect(msg.parameters, isNotNull);
      expect(msg.parameters!.containsKey('Room Code'), isTrue);
      expect(msg.parameters!['Sync Protocol'], equals('Sub-200ms Deadband'));
    });
  });

  group('Firebase Cloud REST Integration & Credentials Testing', () {
    late FirebaseService firebase;

    setUp(() async {
      firebase = FirebaseService.instance;
      await firebase.initialize();
    });

    test('Unconfigured Firebase defaults to safe local cache mode', () {
      expect(firebase.isConfigured, isFalse);
      expect(firebase.isConnected, isFalse);
      expect(firebase.statusMessage, contains('Local Cache Mode'));
    });

    test('FirebaseConfig validation correctly distinguishes valid vs empty keys', () {
      const emptyConfig = FirebaseConfig(projectId: '', apiKey: '');
      expect(emptyConfig.isValid, isFalse);

      const validConfig = FirebaseConfig(
        projectId: 'openaamps-music-player',
        apiKey: 'AIzaSyFakeTestKeyForValidation12345',
      );
      expect(validConfig.isValid, isTrue);
      expect(validConfig.projectId, equals('openaamps-music-player'));
    });

    test('Updating credentials persists to state and toggles configured flag', () async {
      await firebase.updateCredentials(
        projectId: 'test-project-123',
        apiKey: 'AIzaSyTestKey00000',
      );
      expect(firebase.projectId, equals('test-project-123'));
      expect(firebase.apiKey, equals('AIzaSyTestKey00000'));
      expect(firebase.isConfigured, isTrue);
    });

    test('Resetting credentials returns to local cache mode safely', () async {
      await firebase.updateCredentials(projectId: '', apiKey: '');
      expect(firebase.isConfigured, isFalse);
      expect(firebase.isConnected, isFalse);
      expect(firebase.statusMessage, equals('Local Cache Mode'));
    });
  });
}
