import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import '../services/account_service.dart';
import '../services/integration_service.dart';
import '../services/youtube_service.dart';
import '../services/settings_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';
import '../widgets/output_target_modal.dart';
import 'stats_view.dart';
import '../widgets/app_alert.dart';
import '../services/party_service.dart';
import 'party_view.dart';
import '../models/ai_recommendation.dart';
import '../services/ai_music_service.dart';
import 'ai/ai_assistant_view.dart';
import 'ai/ai_playlist_maker.dart';
import 'ai/why_recommended_modal.dart';
import 'auth/profile_view.dart';

class HomeView extends StatefulWidget {
  final Function(Track) onPlayTrack;
  final AudioTarget? currentTarget;
  final PiAampsService? piService;
  final AudioPlayerService? audioService;

  const HomeView({
    super.key,
    required this.onPlayTrack,
    this.currentTarget,
    this.piService,
    this.audioService,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String _selectedCategory = 'Feel good';
  bool _isLoadingCategory = false;
  bool _showAllQuickPicks = false;

  final List<String> _categories = [
    'Feel good',
    'Sad',
    'Energize',
    'Relax',
    'Romance',
    'Focus',
    'Pop',
    'Rock',
    'Hip Hop',
  ];

  final List<Map<String, String>> _artists = [
    {
      'name': 'Coldplay',
      'url': 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=200',
    },
    {
      'name': 'The Weeknd',
      'url': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200',
    },
    {
      'name': 'Dua Lipa',
      'url': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    },
    {
      'name': 'Harry Styles',
      'url': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    },
    {
      'name': 'Taylor Swift',
      'url': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
    },
    {
      'name': 'Queen',
      'url': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200',
    },
  ];

  final Map<String, List<Track>> _categoryCache = {};

  final Map<String, List<Track>> _seedCategories = {
    'Feel good': [
      Track(
        id: 'yKNxeF4KMsY',
        title: 'Yellow',
        artist: 'Coldplay',
        album: 'Parachutes',
        duration: const Duration(minutes: 4, seconds: 29),
        artworkUrl: 'https://i.ytimg.com/vi/yKNxeF4KMsY/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
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
      ),
      Track(
        id: 'fJ9rUzIMcZQ',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: const Duration(minutes: 5, seconds: 55),
        artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
    ],
    'Sad': [
      Track(
        id: 'rYEDA3JcQqw',
        title: 'Rolling in the Deep',
        artist: 'Adele',
        album: '21',
        duration: const Duration(minutes: 3, seconds: 48),
        artworkUrl: 'https://i.ytimg.com/vi/rYEDA3JcQqw/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
      Track(
        id: 'bCuhuePlP8o',
        title: 'Someone You Loved',
        artist: 'Lewis Capaldi',
        album: 'Divinely Uninspired',
        duration: const Duration(minutes: 3, seconds: 2),
        artworkUrl: 'https://i.ytimg.com/vi/bCuhuePlP8o/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
      Track(
        id: 'HUHC9tYz8ik',
        title: 'When the Party\'s Over',
        artist: 'Billie Eilish',
        album: 'WHEN WE ALL FALL ASLEEP',
        duration: const Duration(minutes: 3, seconds: 16),
        artworkUrl: 'https://i.ytimg.com/vi/HUHC9tYz8ik/hqdefault.jpg',
        streamUrl: '',
        codec: 'OPUS 160kbps',
      ),
      Track(
        id: 'RBumgq5yVrA',
        title: 'Let Her Go',
        artist: 'Passenger',
        album: 'All the Little Lights',
        duration: const Duration(minutes: 4, seconds: 12),
        artworkUrl: 'https://i.ytimg.com/vi/RBumgq5yVrA/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
    ],
    'Energize': [
      Track(
        id: '34Na4j8AVgA',
        title: 'Starboy',
        artist: 'The Weeknd ft. Daft Punk',
        album: 'Starboy (Deluxe)',
        duration: const Duration(minutes: 3, seconds: 50),
        artworkUrl: 'https://i.ytimg.com/vi/34Na4j8AVgA/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
      Track(
        id: '_ovdm2yX4MA',
        title: 'Wake Me Up',
        artist: 'Avicii',
        album: 'True',
        duration: const Duration(minutes: 4, seconds: 9),
        artworkUrl: 'https://i.ytimg.com/vi/_ovdm2yX4MA/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
      Track(
        id: 'kXYiU_JCYtU',
        title: 'Numb',
        artist: 'Linkin Park',
        album: 'Meteora',
        duration: const Duration(minutes: 3, seconds: 7),
        artworkUrl: 'https://i.ytimg.com/vi/kXYiU_JCYtU/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
    ],
    'Relax': [
      Track(
        id: 'jfKfPfyJRdk',
        title: 'Lofi Hip Hop Beats - Chill Session',
        artist: 'Lofi Girl',
        album: 'Chilled Beats 2026',
        duration: const Duration(minutes: 3, seconds: 45),
        artworkUrl: 'https://i.ytimg.com/vi/jfKfPfyJRdk/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
      Track(
        id: '5yx6BWlEVcY',
        title: 'Stay With Me',
        artist: 'Miki Matsubara',
        album: 'Pocket Park',
        duration: const Duration(minutes: 4, seconds: 59),
        artworkUrl: 'https://i.ytimg.com/vi/5yx6BWlEVcY/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
    ],
    'Romance': [
      Track(
        id: 'lp-EO5I60KA',
        title: 'Thinking Out Loud',
        artist: 'Ed Sheeran',
        album: 'x (Deluxe)',
        duration: const Duration(minutes: 4, seconds: 41),
        artworkUrl: 'https://i.ytimg.com/vi/lp-EO5I60KA/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
      Track(
        id: 'JGwWNGJdvx8',
        title: 'Shape of You',
        artist: 'Ed Sheeran',
        album: '÷ (Divide)',
        duration: const Duration(minutes: 3, seconds: 53),
        artworkUrl: 'https://i.ytimg.com/vi/JGwWNGJdvx8/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
    ],
    'Focus': [
      Track(
        id: 'pUZa33hSYWg',
        title: 'Experience',
        artist: 'Ludovico Einaudi',
        album: 'In a Time Lapse',
        duration: const Duration(minutes: 5, seconds: 15),
        artworkUrl: 'https://i.ytimg.com/vi/pUZa33hSYWg/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
      Track(
        id: '1d4C1ZQKfq4',
        title: 'Interstellar Main Theme',
        artist: 'Hans Zimmer',
        album: 'Interstellar OST',
        duration: const Duration(minutes: 4, seconds: 5),
        artworkUrl: 'https://i.ytimg.com/vi/1d4C1ZQKfq4/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
    ],
    'Pop': [
      Track(
        id: 'b1kbLwvqugk',
        title: 'Anti-Hero',
        artist: 'Taylor Swift',
        album: 'Midnights',
        duration: const Duration(minutes: 3, seconds: 20),
        artworkUrl: 'https://i.ytimg.com/vi/b1kbLwvqugk/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
    ],
    'Rock': [
      Track(
        id: 'hTWKbfoikeg',
        title: 'Smells Like Teen Spirit',
        artist: 'Nirvana',
        album: 'Nevermind',
        duration: const Duration(minutes: 5, seconds: 1),
        artworkUrl: 'https://i.ytimg.com/vi/hTWKbfoikeg/hqdefault.jpg',
        streamUrl: '',
        codec: 'FLAC 24-bit',
      ),
    ],
    'Hip Hop': [
      Track(
        id: 'tvTRZJ-4EyI',
        title: 'HUMBLE.',
        artist: 'Kendrick Lamar',
        album: 'DAMN.',
        duration: const Duration(minutes: 2, seconds: 57),
        artworkUrl: 'https://i.ytimg.com/vi/tvTRZJ-4EyI/hqdefault.jpg',
        streamUrl: '',
        codec: 'OPUS 160kbps',
      ),
    ],
  };

  List<Track> _quickPicks = [];

  @override
  void initState() {
    super.initState();
    AccountService.instance.addListener(_refresh);
    SettingsService.instance.addListener(_refresh);
    _quickPicks = List.from(_seedCategories['Feel good']!);
    _fetchCategoryFromYoutube('Feel good');
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    AccountService.instance.removeListener(_refresh);
    SettingsService.instance.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _selectCategory(String cat) async {
    setState(() {
      _selectedCategory = cat;
      _quickPicks = List.from(_categoryCache[cat] ?? _seedCategories[cat] ?? _seedCategories['Feel good']!);
    });

    if (!_categoryCache.containsKey(cat)) {
      await _fetchCategoryFromYoutube(cat);
    }
  }

  Future<void> _fetchCategoryFromYoutube(String category) async {
    if (_isLoadingCategory) return;
    setState(() => _isLoadingCategory = true);

    try {
      final query = '$category top music hits playlist';
      final tracks = await YoutubeService().searchTracks(query);
      if (tracks.isNotEmpty && mounted) {
        setState(() {
          _categoryCache[category] = tracks;
          if (_selectedCategory == category) {
            _quickPicks = tracks;
          }
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingCategory = false);
    }
  }

  Future<void> _playArtist(String artistName) async {
    AppAlert.show(context, 'Loading $artistName tracks...', icon: Icons.music_note_rounded);
    try {
      final tracks = await YoutubeService().searchTracks('$artistName greatest hits');
      if (tracks.isNotEmpty && mounted) {
        widget.onPlayTrack(tracks.first);
        return;
      }
    } catch (_) {}

    final match = _quickPicks.where((t) => t.artist.toLowerCase().contains(artistName.toLowerCase())).firstOrNull;
    if (match != null) {
      widget.onPlayTrack(match);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    final showAmbientWallpaper = settings.showWallpaperOnHome && settings.customWallpaperUrl.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Ambient Wallpaper Header Backdrop (Spotify Style)
          if (showAmbientWallpaper)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 260,
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                    stops: [0.0, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: Opacity(
                  opacity: 0.28,
                  child: Image.network(
                    settings.customWallpaperUrl,
                    fit: BoxFit.cover,
                    headers: const {
                      'User-Agent':
                          'Mozilla/5.0 (Linux; Android 14; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0 Mobile Safari/537.36',
                    },
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

          SafeArea(
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
                            child: Center(
                              child: Icon(Icons.graphic_eq_rounded, color: settings.accentColor, size: 20),
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
                            icon: const Icon(Icons.wallpaper_rounded, color: Colors.white),
                            tooltip: 'Wallpaper & Canvas',
                            onPressed: () => _showWallpaperSwitcher(context),
                          ),
                          ListenableBuilder(
                            listenable: PartyService.instance,
                            builder: (context, _) {
                              final inParty = PartyService.instance.isInParty;
                              final membersCount = PartyService.instance.members.length;
                              return Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      inParty ? Icons.hub_rounded : Icons.groups_rounded,
                                      color: inParty ? Colors.greenAccent : const Color(0xFFA1A1AA),
                                    ),
                                    tooltip: inParty ? 'Music Party ($membersCount)' : 'Start or Join Music Party',
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const PartyView()),
                                      );
                                    },
                                  ),
                                  if (inParty)
                                    Positioned(
                                      right: 6,
                                      top: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: Colors.greenAccent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '$membersCount',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
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
                          IconButton(
                            icon: const Icon(Icons.auto_awesome, color: Colors.white),
                            tooltip: 'AI Music Assistant',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AiAssistantView(
                                    audioService: widget.audioService ?? AudioPlayerService(),
                                    onPlayTrack: widget.onPlayTrack,
                                  ),
                                ),
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
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileView()),
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
                  return GestureDetector(
                    onTap: () {
                      final audio = widget.audioService;
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        builder: (modalCtx) => OutputTargetModal(
                          currentTarget: audio?.target ?? AudioTarget.phoneLocal,
                          onSelectTarget: (target) {
                            audio?.setAudioTarget(target);
                          },
                          piService: PiAampsService.instance,
                        ),
                      );
                    },
                    child: Container(
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
                                      : 'Tap here to configure or connect to Raspberry Pi DAC streamer',
                                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  pi.isConnected ? 'READY' : 'OFFLINE',
                                  style: TextStyle(
                                    color: pi.isConnected ? Colors.white : Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Music Party / Jam Live Session Banner
              ListenableBuilder(
                listenable: PartyService.instance,
                builder: (context, _) {
                  final inParty = PartyService.instance.isInParty;
                  final party = PartyService.instance;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PartyView()),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: inParty ? const Color(0xFF0F1B14) : const Color(0xFF141416),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: inParty ? Colors.greenAccent.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: inParty ? Colors.greenAccent.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              inParty ? Icons.hub_rounded : Icons.groups_rounded,
                              color: inParty ? Colors.greenAccent : Colors.white70,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inParty
                                      ? 'Live Music Party • ${party.roomCode}'
                                      : 'Music Party / Group Listening',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  inParty
                                      ? '${party.members.length} members listening in sync (drift: ${party.driftMs.abs()}ms)'
                                      : 'Listen together on individual earbuds with drift sync',
                                  style: TextStyle(
                                    color: inParty ? Colors.greenAccent : const Color(0xFFA1A1AA),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: inParty ? Colors.greenAccent.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  inParty ? 'LIVE SYNC' : 'JOIN / HOST',
                                  style: TextStyle(
                                    color: inParty ? Colors.greenAccent : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: inParty ? Colors.greenAccent : Colors.white54,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // AI Music Intelligence Hub & Recommendations
              _buildAiIntelligenceHub(),
              _buildAiRecommendationsSection(),
              _buildAiMoodStationsSection(),

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
                      onSelected: (selected) => _selectCategory(cat),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Quick Picks Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Quick picks',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_quickPicks.length} tracks',
                          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (_isLoadingCategory) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        ),
                      ],
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _showAllQuickPicks = !_showAllQuickPicks);
                    },
                    child: Text(
                      _showAllQuickPicks ? 'Show less' : 'See all (${_quickPicks.length})',
                      style: const TextStyle(color: Color(0xFFA1A1AA)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _showAllQuickPicks ? _quickPicks.length : (_quickPicks.length > 5 ? 5 : _quickPicks.length),
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final track = _quickPicks[index];
                  return Material(
                    color: const Color(0xFF141414),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
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
                      onTap: () => _playArtist(artist['name']!),
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
    ],
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

  Widget _buildAiIntelligenceHub() {
    final accent = SettingsService.instance.accentColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: accent, size: 13),
                    const SizedBox(width: 6),
                    const Text(
                      'AI MUSIC INTELLIGENCE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileView()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.insights_rounded, color: Colors.white70, size: 13),
                      SizedBox(width: 4),
                      Text('Acoustic DNA', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Personalized Acoustic Intelligence',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
          ),
          const SizedBox(height: 4),
          const Text(
            'Dynamic preference learning adapts to your listening completions, skips, and volume dynamics in real time.',
            style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                    backgroundColor: const Color(0xFF242424),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.mic_none_rounded, color: Colors.white, size: 16),
                  label: const Text('Voice / AI Assistant', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AiAssistantView(
                          audioService: widget.audioService ?? AudioPlayerService(),
                          onPlayTrack: widget.onPlayTrack,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent == Colors.white ? Colors.white : accent,
                    foregroundColor: accent == Colors.white ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: Icon(
                    Icons.playlist_add_rounded,
                    color: accent == Colors.white ? Colors.black : Colors.white,
                    size: 18,
                  ),
                  label: const Text('Prompt Playlist', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => AiPlaylistMakerModal(
                        onPlayTrack: widget.onPlayTrack,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendationsSection() {
    final recommendations = AiMusicService.instance.getPersonalizedRecommendations(limit: 6);
    if (recommendations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Made For You • AI Match',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AiPlaylistMakerModal(onPlayTrack: widget.onPlayTrack),
                );
              },
              child: const Text('Make Mix', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommendations.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final track = recommendations[i];
              final matchPct = (track.aiRecommendationScore * 100).toInt();
              return GestureDetector(
                onTap: () => widget.onPlayTrack(track),
                child: Container(
                  width: 135,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141416),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              track.artworkUrl,
                              width: 119,
                              height: 105,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                width: 119,
                                height: 105,
                                color: Colors.white10,
                                child: const Icon(Icons.music_note, color: Colors.white),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                              ),
                              child: Text(
                                '$matchPct% AI',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: GestureDetector(
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (ctx) => WhyRecommendedModal(
                                    track: track,
                                    onPlay: () => widget.onPlayTrack(track),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.help_outline_rounded, color: Colors.white70, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  Widget _buildAiMoodStationsSection() {
    final moods = MoodCategory.defaultMoods;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Mood Stations',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: moods.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final mood = moods[i];
              return GestureDetector(
                onTap: () {
                  final tracks = AiMusicService.instance.getMoodRecommendations(mood);
                  if (tracks.isNotEmpty) {
                    AppAlert.show(
                      context,
                      'Tuning to ${mood.title} Station...',
                      icon: mood.icon,
                    );
                    widget.onPlayTrack(tracks.first);
                  }
                },
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: mood.gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: mood.gradientColors.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(mood.icon, color: Colors.white, size: 20),
                          const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                      Text(
                        mood.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  void _showWallpaperSwitcher(BuildContext context) {
    final settings = SettingsService.instance;
    final urlCtrl = TextEditingController(text: settings.customWallpaperUrl);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  top: 16.0,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wallpaper & Visual Canvas',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Select or customize your player and home wallpaper',
                              style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 12),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Colors.white70),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active Wallpaper Preview Thumbnail Card
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        image: DecorationImage(
                          image: NetworkImage(settings.customWallpaperUrl),
                          fit: BoxFit.cover,
                          onError: (_, _) {},
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.75),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVE CANVAS',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 10,
                            right: 10,
                            child: Text(
                              settings.customWallpaperUrl,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Presets Horizontal List
                    const Text(
                      'PRESETS (1-TAP SWITCH)',
                      style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: SettingsService.defaultWallpapers.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final wp = SettingsService.defaultWallpapers[i];
                          final isSelected = settings.customWallpaperUrl == wp['url'];
                          return ActionChip(
                            label: Text(wp['name'] ?? ''),
                            backgroundColor: isSelected ? Colors.white : const Color(0xFF242424),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.black : Colors.white,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? Colors.white : Colors.white12,
                              ),
                            ),
                            onPressed: () {
                              final url = wp['url'] ?? '';
                              settings.setCustomWallpaperUrl(url);
                              urlCtrl.text = url;
                              setModalState(() {});
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Custom URL Input
                    const Text(
                      'CUSTOM WALLPAPER IMAGE / REDDIT URL',
                      style: TextStyle(color: Color(0xFFB3B3B3), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF242424),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: urlCtrl,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'https://i.redd.it/... or direct image link',
                          hintStyle: TextStyle(color: Color(0xFF727272), fontSize: 12),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          if (urlCtrl.text.trim().isNotEmpty) {
                            settings.setCustomWallpaperUrl(urlCtrl.text);
                            Navigator.pop(ctx);
                            setState(() {});
                            AppAlert.show(context, 'Wallpaper updated and applied!', icon: Icons.wallpaper_rounded);
                          }
                        },
                        child: const Text('Apply Wallpaper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
