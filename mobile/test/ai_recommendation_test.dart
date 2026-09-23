import 'package:flutter_test/flutter_test.dart';
import 'package:open_aamps/models/track.dart';
import 'package:open_aamps/models/user_profile.dart';
import 'package:open_aamps/models/ai_recommendation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AI Acoustic Taste Vector & Preference Learning Tests', () {
    test('AcousticTasteVector shifts positively when user likes high energy rock', () {
      const initialVector = AcousticTasteVector(
        energy: 0.50,
        valence: 0.50,
        danceability: 0.50,
        acousticness: 0.50,
        tempo: 100.0,
      );

      final rockTrack = Track(
        id: 'rock_1',
        title: 'High Voltage Rock',
        artist: 'Test Band',
        artworkUrl: '',
        streamUrl: '',
        energy: 0.90,
        valence: 0.80,
        danceability: 0.70,
        acousticness: 0.10,
        tempo: 140.0,
      );

      // Shift toward track with positive learning rate (+0.16)
      final updated = initialVector.shiftTowards(
        targetEnergy: rockTrack.energy,
        targetValence: rockTrack.valence,
        targetDanceability: rockTrack.danceability,
        targetAcousticness: rockTrack.acousticness,
        targetTempo: rockTrack.tempo,
        learningRate: 0.16,
      );

      expect(updated.energy, greaterThan(initialVector.energy));
      expect(updated.valence, greaterThan(initialVector.valence));
      expect(updated.acousticness, lessThan(initialVector.acousticness));
      expect(updated.tempo, greaterThan(initialVector.tempo));
    });

    test('AcousticTasteVector applies negative penalty when user skips track early', () {
      const initialVector = AcousticTasteVector(
        energy: 0.80,
        valence: 0.70,
        danceability: 0.75,
        acousticness: 0.20,
        tempo: 130.0,
      );

      final unwantedTrack = Track(
        id: 'slow_1',
        title: 'Unwanted Slow Track',
        artist: 'Boring Band',
        artworkUrl: '',
        streamUrl: '',
        energy: 0.95,
        valence: 0.85,
        danceability: 0.80,
        acousticness: 0.05,
        tempo: 150.0,
      );

      // Negative penalty for skip (-0.08)
      final penalized = initialVector.shiftTowards(
        targetEnergy: unwantedTrack.energy,
        targetValence: unwantedTrack.valence,
        targetDanceability: unwantedTrack.danceability,
        targetAcousticness: unwantedTrack.acousticness,
        targetTempo: unwantedTrack.tempo,
        learningRate: -0.08,
      );

      expect(penalized.energy, lessThanOrEqualTo(initialVector.energy));
    });

    test('Similarity score computes high match for matching acoustic coordinates', () {
      const vector = AcousticTasteVector(
        energy: 0.85,
        valence: 0.80,
        danceability: 0.75,
        acousticness: 0.15,
        tempo: 125.0,
      );

      final similarTrack = Track(
        id: 'sim_1',
        title: 'Anthem of Joy',
        artist: 'Pop Star',
        artworkUrl: '',
        streamUrl: '',
        energy: 0.88,
        valence: 0.82,
        danceability: 0.78,
        acousticness: 0.12,
        tempo: 128.0,
      );

      final dissimilarTrack = Track(
        id: 'dis_1',
        title: 'Quiet Ambient Drone',
        artist: 'Sleep Waves',
        artworkUrl: '',
        streamUrl: '',
        energy: 0.15,
        valence: 0.20,
        danceability: 0.10,
        acousticness: 0.95,
        tempo: 60.0,
      );

      final matchSimilar = vector.similarityScore(
        trackEnergy: similarTrack.energy,
        trackValence: similarTrack.valence,
        trackDanceability: similarTrack.danceability,
        trackAcousticness: similarTrack.acousticness,
        trackTempo: similarTrack.tempo,
      );

      final matchDissimilar = vector.similarityScore(
        trackEnergy: dissimilarTrack.energy,
        trackValence: dissimilarTrack.valence,
        trackDanceability: dissimilarTrack.danceability,
        trackAcousticness: dissimilarTrack.acousticness,
        trackTempo: dissimilarTrack.tempo,
      );

      expect(matchSimilar, greaterThan(0.85));
      expect(matchDissimilar, lessThan(0.50));
      expect(matchSimilar, greaterThan(matchDissimilar));
    });

    test('MoodCategory correctly categorizes acoustic dimensions', () {
      final energize = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'energize');
      final relax = MoodCategory.defaultMoods.firstWhere((m) => m.id == 'relax');

      expect(energize.targetEnergy, greaterThan(relax.targetEnergy));
      expect(relax.targetAcousticness, greaterThan(energize.targetAcousticness));
    });
  });
}
