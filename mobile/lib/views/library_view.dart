import 'package:flutter/material.dart';
import '../models/track.dart';

class LibraryView extends StatelessWidget {
  final Function(Track) onPlayTrack;

  const LibraryView({super.key, required this.onPlayTrack});

  @override
  Widget build(BuildContext context) {
    final localSongs = [
      Track(
        id: 'local_1',
        title: 'High Spec Neet',
        artist: '40mP',
        album: 'Local Device Audio',
        artworkUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
        streamUrl: '',
        isDownloaded: true,
      ),
      Track(
        id: 'local_2',
        title: 'Marigold - マリーゴールド',
        artist: 'aimyon',
        album: 'Local Device Audio',
        artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
        streamUrl: '',
        isDownloaded: true,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Library',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Playlists, liked songs, downloaded tracks & local device audio',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Categories Row
              Row(
                children: [
                  _buildLibraryCategory(Icons.playlist_play_rounded, 'Playlists', '2 playlists'),
                  const SizedBox(width: 12),
                  _buildLibraryCategory(Icons.download_done_rounded, 'Downloaded', '2 songs'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildLibraryCategory(Icons.favorite_rounded, 'Liked Songs', '14 songs'),
                  const SizedBox(width: 12),
                  _buildLibraryCategory(Icons.sd_card_rounded, 'Local Device Files', '3 files'),
                ],
              ),
              const SizedBox(height: 28),

              const Text(
                'Recent Downloads',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.separated(
                  itemCount: localSongs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final track = localSongs[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            track.artworkUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          track.artist,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.cyanAccent, size: 34),
                          onPressed: () => onPlayTrack(track),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryCategory(IconData icon, String title, String subtitle) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.cyanAccent, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
