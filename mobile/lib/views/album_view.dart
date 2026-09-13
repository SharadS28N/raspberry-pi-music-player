import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class AlbumView extends StatelessWidget {
  final String albumTitle;
  final String artistName;
  final String coverUrl;
  final AudioPlayerService audioService;
  final Function(Track) onPlayTrack;

  const AlbumView({
    super.key,
    required this.albumTitle,
    required this.artistName,
    required this.coverUrl,
    required this.audioService,
    required this.onPlayTrack,
  });

  @override
  Widget build(BuildContext context) {
    final List<Track> albumTracks = [
      Track(
        id: '34Na4j8AVgA',
        title: 'Starboy',
        artist: artistName,
        album: albumTitle,
        duration: const Duration(minutes: 3, seconds: 50),
        artworkUrl: coverUrl,
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
      Track(
        id: '4NRXx6U8ABQ',
        title: 'Blinding Lights',
        artist: artistName,
        album: albumTitle,
        duration: const Duration(minutes: 3, seconds: 20),
        artworkUrl: coverUrl,
        streamUrl: '',
        codec: 'OPUS 160kbps',
      ),
      Track(
        id: 'LIIDh-OVElE',
        title: 'Save Your Tears',
        artist: artistName,
        album: albumTitle,
        duration: const Duration(minutes: 3, seconds: 35),
        artworkUrl: coverUrl,
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
      Track(
        id: 'KT-U-yL94-0',
        title: 'Stay',
        artist: 'The Kid LAROI & Justin Bieber',
        album: albumTitle,
        duration: const Duration(minutes: 2, seconds: 21),
        artworkUrl: coverUrl,
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
    ];

    final currentPlaying = audioService.currentTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: CustomScrollView(
        slivers: [
          // Album Hero Cover Header
          SliverAppBar(
            expandedHeight: 360,
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
                    coverUrl,
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
                          const Color(0xFF090D16).withValues(alpha: 0.85),
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
                          albumTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artistName,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '2018 • 11 songs • 42:23',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                        ),
                        const SizedBox(height: 18),

                        // Actions (Shuffle, Big Play, Add, Download)
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
                              onPressed: () => onPlayTrack(albumTracks.first),
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white12,
                              child: IconButton(
                                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                                onPressed: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.white12,
                              child: IconButton(
                                icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
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
                  const Text(
                    'Songs',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // Tracklist (Matching Screenshot 6)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: albumTracks.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final track = albumTracks[index];
                      final isPlaying = currentPlaying?.id == track.id;

                      return Container(
                        decoration: BoxDecoration(
                          color: isPlaying ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: isPlaying
                              ? const Icon(Icons.bar_chart_rounded, color: Colors.greenAccent, size: 26)
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              color: isPlaying ? Colors.greenAccent : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${track.artist} • 3:19',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white54),
                            onPressed: () {},
                          ),
                          onTap: () => onPlayTrack(track),
                        ),
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
