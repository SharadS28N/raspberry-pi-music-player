import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/account_service.dart';
import '../services/local_audio_service.dart';
import 'album_view.dart';

class LibraryView extends StatefulWidget {
  final AccountService accountService;
  final LocalAudioService localAudioService;
  final Function(Track) onPlayTrack;

  const LibraryView({
    super.key,
    required this.accountService,
    required this.localAudioService,
    required this.onPlayTrack,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Library', 'Playlists', 'Songs', 'Albums', 'Artists'];

  @override
  Widget build(BuildContext context) {
    final localTracks = widget.localAudioService.localTracks;
    final activeAccount = widget.accountService.activeAccount;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Top Bar with App Logo
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      'प',
                      style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'ArchiveTune',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white70),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal Filter Pills (Matching screenshot_8.jpg)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedFilterIndex;
                  return ChoiceChip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFFC4E0B8), // Soft Light Sage (Matching screenshot_8)
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilterIndex = index);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Featured "MOST PLAYED" Banner (Matching screenshot_8.jpg)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumView(
                      albumTitle: 'The Problem Einstein Couldn\'t Solve',
                      artistName: '40mP',
                      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
                      audioService: widget.onPlayTrack as dynamic,
                      onPlayTrack: widget.onPlayTrack,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '☆ MOST PLAYED',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'The Problem Einstein couldn\'t solve',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '11 songs',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4E0B8),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                          label: const Text('Play all', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {},
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white12,
                          child: IconButton(
                            icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid Cards (Matching screenshot_8.jpg)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildLibraryCard(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.pinkAccent,
                  title: 'Liked songs',
                  subtitle: '${activeAccount.likedSongsCount} tracks',
                ),
                _buildLibraryCard(
                  icon: Icons.offline_pin_rounded,
                  iconColor: Colors.cyanAccent,
                  title: 'Offline',
                  subtitle: 'Downloaded',
                ),
                _buildLibraryCard(
                  icon: Icons.cached_rounded,
                  iconColor: Colors.purpleAccent,
                  title: 'Cached',
                  subtitle: 'Instant playback',
                ),
                _buildLibraryCard(
                  icon: Icons.folder_rounded,
                  iconColor: Colors.amberAccent,
                  title: 'Local Files',
                  subtitle: '${localTracks.length} On device',
                ),
                _buildLibraryCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.greenAccent,
                  title: 'My top 50',
                  subtitle: 'All time',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: iconColor.withValues(alpha: 0.15),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
