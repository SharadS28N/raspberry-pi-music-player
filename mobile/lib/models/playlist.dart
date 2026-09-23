import 'track.dart';

class Playlist {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final List<Track> tracks;
  final bool isAiGenerated;
  final String aiPrompt;
  final String mood;
  final DateTime createdAt;
  final String ownerUid;
  final bool isCollaborative;
  final int likesCount;

  Playlist({
    required this.id,
    required this.title,
    this.description = '',
    this.coverUrl = '',
    this.tracks = const [],
    this.isAiGenerated = false,
    this.aiPrompt = '',
    this.mood = 'General',
    DateTime? createdAt,
    this.ownerUid = 'current_user',
    this.isCollaborative = false,
    this.likesCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  int get trackCount => tracks.length;

  Duration get totalDuration {
    return tracks.fold(Duration.zero, (prev, track) => prev + track.duration);
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Playlist',
      description: json['description'] ?? '',
      coverUrl: json['cover_url'] ?? '',
      tracks: (json['tracks'] as List?)
              ?.map((t) => Track.fromJson(Map<String, dynamic>.from(t)))
              .toList() ??
          [],
      isAiGenerated: json['is_ai_generated'] ?? false,
      aiPrompt: json['ai_prompt'] ?? '',
      mood: json['mood'] ?? 'General',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at']) ?? DateTime.now()
          : DateTime.now(),
      ownerUid: json['owner_uid'] ?? 'current_user',
      isCollaborative: json['is_collaborative'] ?? false,
      likesCount: json['likes_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'tracks': tracks.map((t) => t.toJson()).toList(),
      'is_ai_generated': isAiGenerated,
      'ai_prompt': aiPrompt,
      'mood': mood,
      'created_at': createdAt.toIso8601String(),
      'owner_uid': ownerUid,
      'is_collaborative': isCollaborative,
      'likes_count': likesCount,
    };
  }

  Playlist copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<Track>? tracks,
    bool? isAiGenerated,
    String? aiPrompt,
    String? mood,
    DateTime? createdAt,
    String? ownerUid,
    bool? isCollaborative,
    int? likesCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverUrl: coverUrl ?? this.coverUrl,
      tracks: tracks ?? this.tracks,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      ownerUid: ownerUid ?? this.ownerUid,
      isCollaborative: isCollaborative ?? this.isCollaborative,
      likesCount: likesCount ?? this.likesCount,
    );
  }
}
