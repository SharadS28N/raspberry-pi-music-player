import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_aamps/models/track.dart';
import 'package:open_aamps/models/user_profile.dart';
import 'package:open_aamps/repositories/auth_repository.dart';
import 'package:open_aamps/services/firebase_service.dart';
import 'package:open_aamps/services/ai_voice_assistant.dart';
import 'package:open_aamps/services/audio_player_service.dart';
import 'package:open_aamps/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Architecture & Clean Separation Verification', () {
    test('Verify no direct Firebase imports exist in frontend views', () {
      final viewsDir = Directory('lib/views');
      expect(viewsDir.existsSync(), isTrue);

      final dartFiles = viewsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains("package:firebase_core") ||
            content.contains("package:firebase_auth") ||
            content.contains("package:cloud_firestore") ||
            content.contains("services/firebase_service.dart")) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty,
          reason: 'Frontend views should NOT directly import Firebase. Violations: $violations');
    });

    test('Verify no direct Firebase imports exist in frontend widgets', () {
      final widgetsDir = Directory('lib/widgets');
      expect(widgetsDir.existsSync(), isTrue);

      final dartFiles = widgetsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violations = <String>[];
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        if (content.contains("package:firebase_core") ||
            content.contains("package:firebase_auth") ||
            content.contains("package:cloud_firestore") ||
            content.contains("services/firebase_service.dart")) {
          violations.add(file.path);
        }
      }

      expect(violations, isEmpty,
          reason: 'Frontend widgets should NOT directly import Firebase. Violations: $violations');
    });
  });

  group('Authentication Repository & Evaluator Demo Verification', () {
    test('AppAuthRepository provides initial auth state stream and singleton', () {
      final repo = AppAuthRepository.instance;
      expect(repo, isNotNull);
      expect(repo.isInitialized, isTrue);
    });

    test('Sign in as Evaluator creates a functional session without network dependency', () async {
      final repo = AppAuthRepository.instance;
      final profile = await repo.signInAsEvaluator(name: 'Professor Smith');

      expect(profile, isNotNull);
      expect(profile.displayName, equals('Professor Smith'));
      expect(profile.email, equals('evaluator@openaamps.ai'));
      expect(repo.currentUser, isNotNull);
      expect(repo.currentUser!.displayName, equals('Professor Smith'));
    });

    test('Sign in with invalid email throws descriptive validation error', () async {
      final repo = AppAuthRepository.instance;
      expect(
        () => repo.signInWithEmail('invalid-email', '123456'),
        throwsA(predicate((e) => e.toString().contains('valid email'))),
      );
    });

    test('Sign in with short password throws descriptive validation error', () async {
      final repo = AppAuthRepository.instance;
      expect(
        () => repo.signInWithEmail('test@example.com', '123'),
        throwsA(predicate((e) => e.toString().contains('at least 6 characters'))),
      );
    });

    test('Sign out cleanly resets current user session', () async {
      final repo = AppAuthRepository.instance;
      await repo.signOut();
      expect(repo.currentUser, isNull);
    });
  });

  group('Backend FirebaseService Verification', () {
    test('FirebaseService reports active backend configuration and status', () {
      final service = FirebaseService.instance;
      expect(service.isConfigured, isTrue);
      expect(service.projectId, isNotEmpty);
      expect(service.statusMessage, isNotEmpty);
    });

    test('Firestore write gracefully handles unauthenticated user without crash', () async {
      final service = FirebaseService.instance;
      final result = await service.syncDocumentToFirestore(
        collection: 'test_sync',
        documentId: 'doc_1',
        fields: {'timestamp': DateTime.now().toIso8601String()},
      );
      expect(result, isFalse);
    });
  });

  group('AI Music Intelligence & Preferences Learning Verification', () {
    test('AcousticTasteVector dynamically learns from positive listening habits', () {
      const initial = AcousticTasteVector(
        energy: 0.5,
        valence: 0.5,
        danceability: 0.5,
        acousticness: 0.5,
        tempo: 110.0,
      );

      final updated = initial.shiftTowards(
        targetEnergy: 0.9,
        targetValence: 0.85,
        targetDanceability: 0.8,
        targetAcousticness: 0.1,
        targetTempo: 140.0,
        learningRate: 0.16,
      );

      expect(updated.energy, greaterThan(initial.energy));
      expect(updated.valence, greaterThan(initial.valence));
      expect(updated.tempo, greaterThan(initial.tempo));
      expect(updated.acousticness, lessThan(initial.acousticness));
    });

    test('AcousticTasteVector similarity score correctly measures track match', () {
      const target = AcousticTasteVector(
        energy: 0.8,
        valence: 0.7,
        danceability: 0.75,
        acousticness: 0.2,
        tempo: 125.0,
      );

      final track = Track(
        id: 't1',
        title: 'Cyberpunk Drive',
        artist: 'Synth Master',
        artworkUrl: '',
        streamUrl: '',
        energy: 0.82,
        valence: 0.72,
        danceability: 0.76,
        acousticness: 0.18,
        tempo: 126.0,
      );

      final score = target.similarityScore(
        trackEnergy: track.energy,
        trackValence: track.valence,
        trackDanceability: track.danceability,
        trackAcousticness: track.acousticness,
        trackTempo: track.tempo,
      );

      expect(score, greaterThan(0.90));
    });

    test('AI Voice Assistant processes conversational theory and audio queries', () async {
      final assistant = AiVoiceAssistant.instance;
      final audioService = AudioPlayerService();

      final response = await assistant.processInput(
        input: 'what is the bpm of yellow by coldplay',
        audioService: audioService,
      );

      expect(response.isUser, isFalse);
      expect(response.actionType, equals('music_theory_query'));
      expect(response.parameters!['Tempo (BPM)'], equals('120 BPM'));
    });
  });

  group('Acoustic DSP & Settings Service Verification', () {
    test('SettingsService maintains accent vibe and acoustic equalizer preferences', () {
      final settings = SettingsService.instance;
      settings.setAccentVibe(AccentVibe.spotifyGreen);
      expect(settings.accentVibe, equals(AccentVibe.spotifyGreen));

      settings.setEqualizerPreset(EqualizerPreset.bassBoost);
      expect(settings.equalizerPreset, equals(EqualizerPreset.bassBoost));

      settings.setPlaybackSpeed(1.25);
      expect(settings.playbackSpeed, equals(1.25));

      settings.setCrossfade(4.0);
      expect(settings.crossfadeDuration, equals(4.0));
    });
  });
}
