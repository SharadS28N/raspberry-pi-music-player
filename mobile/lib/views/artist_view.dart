import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class ArtistView extends StatelessWidget {
  final String artistName;
  final String avatarUrl;
  final AudioPlayerService audioService;
  final Function(Track) onPlayTrack;

  const ArtistView({
    super.key,
    required this.artistName,
    required this.avatarUrl,
    required this.audioService,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    final List<Track> topSongs = [
      Track(
        id: 'artist_song_1',
        title: '瞬間、シンフォニー。 - A Symphony',
        artist: artistName,
        album: "Dreamer's Beat",
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
        streamUrl: '',
      ),
      Track(
        id: 'artist_song_2',
        title: 'ハイ・スパック - High Spec Neet',
        artist: artistName,
        album: 'The Problem Einstein Couldn\'t Solve',
        duration: const Duration(minutes: 3, seconds: 19),
        artworkUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
        streamUrl: '',
      ),
      Track(
        id: 'artist_song_3',
        title: 'はじまりの未来 (Ergo ver) - The Future',
        artist: artistName,
        album: 'Ergo World',
        duration: const Duration(minutes: 4, seconds: 12),
        artworkUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        streamUrl: '',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: CustomScrollView(
        slivers: [
          // Hero Header Image & Artist Info
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: const Color(0xFF090D16),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          const Color(0xFF090D16).withValues(alpha: 0.8),
                          const Color(0xFF090D16),
                        ],
                        stops: const [0.0, 0.4, 0.85, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      children: [
                        Text(
                          artistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '1.7M Monthly listeners • 611K Subscribers\n15+ Songs • 13+ Albums',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Actions Row (Shuffle, Play, Follow Check, Radio)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white12,
                              child: IconButton(
                                icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 28),
                              label: const Text('Play', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              onPressed: () => onPlayTrack(topSongs.first),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white12,
                              child: IconButton(
                                icon: const Icon(Icons.check_rounded, color: Colors.white, size: 22),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white12,
                              child: IconButton(
                                icon: const Icon(Icons.sensors_rounded, color: Colors.white, size: 22),
                                onPressed: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Latest Release Section (Matching Screenshot 5)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LATEST RELEASE',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Dreamer's Beat",
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Album • 2026',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Top Songs Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Top songs',
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white70),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Top Songs List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: topSongs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final track = topSongs[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            track.artworkUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          track.artist,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                          onPressed: () {},
                        ),
                        onTap: () => onPlayTrack(track),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
