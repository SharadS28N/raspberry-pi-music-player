import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import '../services/account_service.dart';
import '../services/integration_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';
import 'stats_view.dart';

class HomeView extends StatefulWidget {
  final Function(Track) onPlayTrack;
  final AudioTarget currentTarget;
  final PiAampsService piService;

  const HomeView({
    super.key,
    required this.onPlayTrack,
    required this.currentTarget,
    required this.piService,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _selectedCategory = 'Feel good';

  final List<String> _categories = [
    'Feel good',
    'Sad',
    'Energize',
    'Relax',
    'Romance',
    'Focus',
  ];

  final List<Map<String, String>> _artists = [
    {
      'name': 'The Weeknd',
      'url': 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
    },
    {
      'name': 'Taylor Swift',
      'url': 'https://i.ytimg.com/vi/ic8j13g5JTQ/hqdefault.jpg',
    },
    {
      'name': 'Dua Lipa',
      'url': 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
    },
    {
      'name': 'Billie Eilish',
      'url': 'https://i.ytimg.com/vi/d5g8WkHthvA/hqdefault.jpg',
    },
    {
      'name': 'Harry Styles',
      'url': 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg',
    },
  ];

  final List<Track> _quickPicks = [
    Track(
      id: '34Na4j8AVgA',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      album: 'Starboy (Deluxe)',
      artworkUrl: 'https://i.ytimg.com/vi/34Na4j8AVgA/hqdefault.jpg',
      streamUrl: '',
      codec: 'FLAC 24-bit',
      loudnessGain: -14.2,
    ),
    Track(
      id: '4NRXx6U8ABQ',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      artworkUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
      streamUrl: '',
      codec: 'OPUS 160kbps',
      loudnessGain: -13.8,
    ),
    Track(
      id: 'H5v3kku4y6Q',
      title: 'As It Was',
      artist: 'Harry Styles',
      album: "Harry's House",
      artworkUrl: 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg',
      streamUrl: '',
      codec: 'AAC 320kbps',
      loudnessGain: -14.0,
    ),
    Track(
      id: 'TUVcZfQe-Kw',
      title: 'Levitating',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      artworkUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
      streamUrl: '',
      codec: 'OPUS 160kbps',
      loudnessGain: -14.1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Branding & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/logo.jpg',
                          width: 34,
                          height: 34,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 34,
                            height: 34,
                            decoration: const BoxDecoration(
                              color: Colors.cyanAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'प',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'OpenAamps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.cyanAccent),
                        tooltip: 'Import Spotify Playlist',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => SpotifyImportModal(
                              integrationService: IntegrationService.instance,
                              onImportSuccess: (importedTracks) {
                                if (importedTracks.isNotEmpty) {
                                  widget.onPlayTrack(importedTracks.first);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.access_time_rounded, color: Colors.white70),
                        tooltip: 'Stats',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const StatsView()),
                          );
                        },
                      ),
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AccountSwitcherModal(
                              accountService: AccountService.instance,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.pinkAccent.withValues(alpha: 0.3),
                            child: const Icon(Icons.person_rounded, size: 18, color: Colors.pinkAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category / Mood Filter Chips
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Colors.white,
                      backgroundColor: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Quick Picks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quick picks',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See all', style: TextStyle(color: Colors.cyanAccent)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _quickPicks.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final track = _quickPicks[index];
                  return Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.artworkUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 48,
                            height: 48,
                            color: Colors.cyanAccent.withValues(alpha: 0.2),
                            child: const Icon(Icons.music_note_rounded, color: Colors.cyanAccent),
                          ),
                        ),
                      ),
                      title: Text(
                        track.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        track.artist,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.cyanAccent, size: 28),
                            onPressed: () => widget.onPlayTrack(track),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Keep Listening (Circular Artist Avatars)
              const Text(
                'Keep listening',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                height: 130,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _artists.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final artist = _artists[index];
                    return Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(artist['url']!),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3), width: 2),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artist['name']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Pi-aamps Dedicated Engine Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade900.withValues(alpha: 0.5),
                      Colors.indigo.shade900.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radio_rounded, color: Colors.purpleAccent, size: 36),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'pi-aamps Speaker Hub',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.currentTarget == AudioTarget.piSpeaker
                                ? 'Active: Casted to Raspberry Pi Speaker'
                                : 'Local mode: Connect to Pi Speaker anytime',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
