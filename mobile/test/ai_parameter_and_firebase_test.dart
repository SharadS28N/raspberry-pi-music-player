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

  group('Firebase Cloud Integration & Service Testing', () {
    late FirebaseService firebase;

    setUp(() {
      firebase = FirebaseService.instance;
    });

    test('FirebaseService singleton maintains valid instance and status message', () {
      expect(firebase, isNotNull);
      expect(firebase.statusMessage, isNotEmpty);
      expect(firebase.isConfigured, isTrue);
    });

    test('Firestore sync handles unauthenticated session safely without exception', () async {
      final syncResult = await firebase.syncDocumentToFirestore(
        collection: 'test_collection',
        documentId: 'test_doc',
        fields: {'key': 'value'},
      );
      // When not authenticated, it safely returns false rather than throwing
      expect(syncResult, isFalse);
    });

    test('Acoustic preferences sync handles unauthenticated session safely', () async {
      final result = await firebase.syncAcousticPreferences({
        'accent_vibe': 'ambient',
        'equalizer_preset': 'bass_boost',
      });
      expect(result, isFalse);
    });
  });
}
