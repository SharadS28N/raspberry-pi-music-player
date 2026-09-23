import 'track.dart';

class ListeningSession {
  final String id;
  final Track track;
  final DateTime playedAt;
  final int durationPlayedSeconds;
  final double completedRate;
  final bool wasSkippedEarly;
  final bool wasLiked;
  final String contextSource;

  ListeningSession({
    required this.id,
    required this.track,
    DateTime? playedAt,
    this.durationPlayedSeconds = 0,
    this.completedRate = 0.0,
    this.wasSkippedEarly = false,
    this.wasLiked = false,
    this.contextSource = 'home',
  }) : playedAt = playedAt ?? DateTime.now();

  factory ListeningSession.fromJson(Map<String, dynamic> json) {
    return ListeningSession(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      track: Track.fromJson(Map<String, dynamic>.from(json['track'] ?? {})),
      playedAt: json['played_at'] != null
          ? DateTime.tryParse(json['played_at']) ?? DateTime.now()
          : DateTime.now(),
      durationPlayedSeconds: json['duration_played_seconds'] ?? 0,
      completedRate: (json['completed_rate'] as num?)?.toDouble() ?? 0.0,
      wasSkippedEarly: json['was_skipped_early'] ?? false,
      wasLiked: json['was_liked'] ?? false,
      contextSource: json['context_source'] ?? 'home',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track': track.toJson(),
      'played_at': playedAt.toIso8601String(),
      'duration_played_seconds': durationPlayedSeconds,
      'completed_rate': completedRate,
      'was_skipped_early': wasSkippedEarly,
      'was_liked': wasLiked,
      'context_source': contextSource,
    };
  }
}
