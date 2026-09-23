import 'track.dart';

class JamMember {
  final String uid;
  final String displayName;
  final String avatarUrl;
  final bool isHost;
  final bool isDj;
  final DateTime joinedAt;

  JamMember({
    required this.uid,
    required this.displayName,
    this.avatarUrl = '',
    this.isHost = false,
    this.isDj = false,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  factory JamMember.fromJson(Map<String, dynamic> json) {
    return JamMember(
      uid: json['uid'] ?? 'guest',
      displayName: json['display_name'] ?? 'Jammer',
      avatarUrl: json['avatar_url'] ?? '',
      isHost: json['is_host'] ?? false,
      isDj: json['is_dj'] ?? false,
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_host': isHost,
      'is_dj': isDj,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

class JamQueueItem {
  final String id;
  final Track track;
  final String addedByUid;
  final String addedByName;
  final int votes;
  final List<String> voterUids;
  final DateTime addedAt;

  JamQueueItem({
    required this.id,
    required this.track,
    required this.addedByUid,
    required this.addedByName,
    this.votes = 1,
    this.voterUids = const [],
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory JamQueueItem.fromJson(Map<String, dynamic> json) {
    return JamQueueItem(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      track: Track.fromJson(Map<String, dynamic>.from(json['track'] ?? {})),
      addedByUid: json['added_by_uid'] ?? '',
      addedByName: json['added_by_name'] ?? 'Friend',
      votes: json['votes'] ?? 1,
      voterUids: (json['voter_uids'] as List?)?.cast<String>() ?? [],
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'track': track.toJson(),
      'added_by_uid': addedByUid,
      'added_by_name': addedByName,
      'votes': votes,
      'voter_uids': voterUids,
      'added_at': addedAt.toIso8601String(),
    };
  }

  JamQueueItem copyWith({
    String? id,
    Track? track,
    String? addedByUid,
    String? addedByName,
    int? votes,
    List<String>? voterUids,
    DateTime? addedAt,
  }) {
    return JamQueueItem(
      id: id ?? this.id,
      track: track ?? this.track,
      addedByUid: addedByUid ?? this.addedByUid,
      addedByName: addedByName ?? this.addedByName,
      votes: votes ?? this.votes,
      voterUids: voterUids ?? this.voterUids,
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class JamRoom {
  final String roomId;
  final String roomCode; // 6-character room code like "JAM492"
  final String roomName;
  final String hostUid;
  final String hostName;
  final Track? currentTrack;
  final int currentPositionMs;
  final bool isPlaying;
  final List<JamQueueItem> queue;
  final List<JamMember> members;
  final DateTime updatedAt;

  JamRoom({
    required this.roomId,
    required this.roomCode,
    required this.roomName,
    required this.hostUid,
    required this.hostName,
    this.currentTrack,
    this.currentPositionMs = 0,
    this.isPlaying = false,
    this.queue = const [],
    this.members = const [],
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory JamRoom.fromJson(Map<String, dynamic> json) {
    return JamRoom(
      roomId: json['room_id'] ?? '',
      roomCode: json['room_code'] ?? 'JAM000',
      roomName: json['room_name'] ?? 'Music Jam Room',
      hostUid: json['host_uid'] ?? '',
      hostName: json['host_name'] ?? 'Host',
      currentTrack: json['current_track'] != null
          ? Track.fromJson(Map<String, dynamic>.from(json['current_track']))
          : null,
      currentPositionMs: json['current_position_ms'] ?? 0,
      isPlaying: json['is_playing'] ?? false,
      queue: (json['queue'] as List?)
              ?.map((item) => JamQueueItem.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      members: (json['members'] as List?)
              ?.map((item) => JamMember.fromJson(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room_id': roomId,
      'room_code': roomCode,
      'room_name': roomName,
      'host_uid': hostUid,
      'host_name': hostName,
      'current_track': currentTrack?.toJson(),
      'current_position_ms': currentPositionMs,
      'is_playing': isPlaying,
      'queue': queue.map((q) => q.toJson()).toList(),
      'members': members.map((m) => m.toJson()).toList(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
