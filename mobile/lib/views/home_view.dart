import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import '../services/account_service.dart';
import '../services/integration_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';
import 'stats_view.dart';
import '../widgets/app_alert.dart';

class HomeView extends StatefulWidget {
  final Function(Track) onPlayTrack;
  final AudioTarget? currentTarget;
  final PiAampsService? piService;

  const HomeView({
    super.key,
    required this.onPlayTrack,
    this.currentTarget,
    this.piService,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _selectedCategory = 'Feel good';

  @override
  void initState() {
    super.initState();
    AccountService.instance.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AccountService.instance.removeListener(_refresh);
    super.dispose();
  }

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
      'name': 'Coldplay',
      'url': 'https://i.ytimg.com/vi/yKNxeF4KMsY/hqdefault.jpg',
    },
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
      'name': 'Harry Styles',
      'url': 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg',
    },
  ];

  final List<Track> _quickPicks = [
    Track(
      id: 'yKNxeF4KMsY',
      title: 'Yellow',
      artist: 'Coldplay',
      album: 'Parachutes',
      duration: const Duration(minutes: 4, seconds: 29),
      artworkUrl: 'https://i.ytimg.com/vi/yKNxeF4KMsY/hqdefault.jpg',
      streamUrl: '',
      codec: 'AAC 320kbps',
      loudnessGain: -14.0,
    ),
    Track(
      id: '34Na4j8AVgA',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      album: 'Starboy (Deluxe)',
      duration: const Duration(minutes: 3, seconds: 50),
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
      duration: const Duration(minutes: 3, seconds: 20),
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
      duration: const Duration(minutes: 2, seconds: 47),
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
      duration: const Duration(minutes: 3, seconds: 23),
      artworkUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
      streamUrl: '',
      codec: 'OPUS 160kbps',
      loudnessGain: -14.1,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header with Monochrome Branding & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                        child: const Center(
                          child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'OpenAamps',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download_for_offline_rounded, color: Colors.white),
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
                        icon: const Icon(Icons.access_time_rounded, color: Color(0xFFA1A1AA)),
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
                            backgroundColor: const Color(0xFF222222),
                            backgroundImage: AccountService.instance.activeAccount.avatarUrl.isNotEmpty
                                ? NetworkImage(AccountService.instance.activeAccount.avatarUrl)
                                : null,
                            child: AccountService.instance.activeAccount.avatarUrl.isEmpty
                                ? const Icon(Icons.person_rounded, size: 18, color: Colors.white)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Pi-Aamps Live Hardware Connectivity Banner
              ListenableBuilder(
                listenable: PiAampsService.instance,
                builder: (context, _) {
                  final pi = PiAampsService.instance.currentState;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141416),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: pi.isConnected ? Colors.white.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: pi.isConnected ? Colors.greenAccent : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pi.isConnected ? 'pi-aamps Hardware Streamer Active' : 'pi-aamps Streamer Disconnected',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                pi.isConnected
                                    ? '${pi.ipAddress} • ${pi.activeDac} • ${pi.tempCelsius.toStringAsFixed(0)}°C'
                                    : 'Tap pi-aamps in bottom bar to connect and stream to Raspberry Pi DAC',
                                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (pi.isConnected)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('READY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Category / Mood Filter Chips (Monochrome)
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
                      backgroundColor: const Color(0xFF141414),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.1),
                        ),
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
                    child: const Text('See all', style: TextStyle(color: Color(0xFFA1A1AA))),
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
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      onTap: () => widget.onPlayTrack(track),
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
                            color: const Color(0xFF222222),
                            child: const Icon(Icons.music_note_rounded, color: Colors.white70),
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
                        style: const TextStyle(
                          color: Color(0xFFA1A1AA),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                            tooltip: 'Play',
                            onPressed: () => widget.onPlayTrack(track),
                          ),
                          IconButton(
                            icon: const Icon(Icons.more_vert_rounded, color: Colors.white54, size: 20),
                            tooltip: 'Options',
                            onPressed: () => _showTrackOptions(context, track),
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
                    return GestureDetector(
                      onTap: () {
                        final matching = _quickPicks.where((t) => t.artist.contains(artist['name']!)).toList();
                        if (matching.isNotEmpty) {
                          widget.onPlayTrack(matching.first);
                        } else {
                          widget.onPlayTrack(_quickPicks[index % _quickPicks.length]);
                        }
                      },
                      child: Column(
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
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
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
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showTrackOptions(BuildContext context, Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      track.artworkUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note_rounded, color: Colors.white),
                    ),
                  ),
                  title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${track.artist} • ${track.album}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                  title: const Text('Play Track', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    widget.onPlayTrack(track);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Color(0xFFA1A1AA)),
                  title: const Text('Download Offline', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    AppAlert.show(
                      context,
                      'Downloading "${track.title}" offline...',
                      icon: Icons.download_rounded,
                    );
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
