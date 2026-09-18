class Account {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final bool isPremium;
  final int playlistsCount;
  final int likedSongsCount;
  final int subscriptionsCount;
  final bool isCoupleProfile;
  final String partnerName;
  final String partnerAvatarUrl;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    this.isPremium = true,
    this.playlistsCount = 0,
    this.likedSongsCount = 0,
    this.subscriptionsCount = 0,
    this.isCoupleProfile = false,
    this.partnerName = '',
    this.partnerAvatarUrl = '',
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? 'user_default',
      name: json['name'] ?? 'OpenAamps User',
      email: json['email'] ?? 'user@open-aamps.org',
      avatarUrl: json['avatar_url'] ?? '',
      isPremium: json['is_premium'] ?? true,
      playlistsCount: json['playlists_count'] ?? 12,
      likedSongsCount: json['liked_songs_count'] ?? 148,
      subscriptionsCount: json['subscriptions_count'] ?? 24,
      isCoupleProfile: json['is_couple_profile'] ?? false,
      partnerName: json['partner_name'] ?? '',
      partnerAvatarUrl: json['partner_avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
      'playlists_count': playlistsCount,
      'liked_songs_count': likedSongsCount,
      'subscriptions_count': subscriptionsCount,
      'is_couple_profile': isCoupleProfile,
      'partner_name': partnerName,
      'partner_avatar_url': partnerAvatarUrl,
    };
  }
}
