import 'package:flutter/material.dart';
import 'track.dart';

class MoodCategory {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final double targetEnergy;
  final double targetValence;
  final double targetAcousticness;
  final double targetTempo;

  const MoodCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.targetEnergy,
    required this.targetValence,
    required this.targetAcousticness,
    required this.targetTempo,
  });

  static const List<MoodCategory> defaultMoods = [
    MoodCategory(
      id: 'energize',
      title: 'Energize',
      subtitle: 'High energy & vibrant vibes',
      icon: Icons.bolt_rounded,
      gradientColors: [Color(0xFFFF512F), Color(0xFFDD2476)],
      targetEnergy: 0.90,
      targetValence: 0.82,
      targetAcousticness: 0.15,
      targetTempo: 130.0,
    ),
    MoodCategory(
      id: 'relax',
      title: 'Relax',
      subtitle: 'Chill, peaceful & atmospheric',
      icon: Icons.spa_rounded,
      gradientColors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
      targetEnergy: 0.28,
      targetValence: 0.60,
      targetAcousticness: 0.75,
      targetTempo: 85.0,
    ),
    MoodCategory(
      id: 'focus',
      title: 'Focus',
      subtitle: 'Instrumentals & deep concentration',
      icon: Icons.psychology_rounded,
      gradientColors: [Color(0xFF11998e), Color(0xFF38ef7d)],
      targetEnergy: 0.40,
      targetValence: 0.50,
      targetAcousticness: 0.80,
      targetTempo: 95.0,
    ),
    MoodCategory(
      id: 'party',
      title: 'Party',
      subtitle: 'Dance, bass-heavy & upbeat grooves',
      icon: Icons.celebration_rounded,
      gradientColors: [Color(0xFF8A2387), Color(0xFFE94057), Color(0xFFF27121)],
      targetEnergy: 0.95,
      targetValence: 0.90,
      targetAcousticness: 0.08,
      targetTempo: 128.0,
    ),
    MoodCategory(
      id: 'melancholy',
      title: 'Melancholy',
      subtitle: 'Emotional, deep & reflective',
      icon: Icons.cloudy_snowing,
      gradientColors: [Color(0xFF3a6073), Color(0xFF16222a)],
      targetEnergy: 0.32,
      targetValence: 0.20,
      targetAcousticness: 0.70,
      targetTempo: 78.0,
    ),
    MoodCategory(
      id: 'workout',
      title: 'Workout',
      subtitle: 'Driving rhythms & pure motivation',
      icon: Icons.fitness_center_rounded,
      gradientColors: [Color(0xFFf857a6), Color(0xFFff5858)],
      targetEnergy: 0.96,
      targetValence: 0.78,
      targetAcousticness: 0.05,
      targetTempo: 142.0,
    ),
  ];
}

class AiRecommendationResult {
  final Track track;
  final double matchPercentage;
  final String primaryReason;
  final List<String> detailedReasons;
  final String targetMood;
  final Map<String, double> acousticMatches;

  AiRecommendationResult({
    required this.track,
    required this.matchPercentage,
    required this.primaryReason,
    this.detailedReasons = const [],
    this.targetMood = 'Personalized',
    this.acousticMatches = const {},
  });
}
