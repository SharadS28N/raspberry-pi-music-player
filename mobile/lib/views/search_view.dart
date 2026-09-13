import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/youtube_service.dart';
import '../services/integration_service.dart';
import 'music_recognition_view.dart';

class SearchView extends StatefulWidget {
  final Function(Track) onPlayTrack;

  const SearchView({super.key, required this.onPlayTrack});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final YoutubeService _ytService = YoutubeService();
  late TabController _tabController;
  List<Track> _searchResults = [];
  bool _isLoading = false;

  final List<Track> _uniqueSongs = [
    Track(
      id: 'harunohi_1',
      title: 'ハルノヒ - Harunohi',
      artist: 'aimyon',
      album: 'Harunohi Single',
      artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
      streamUrl: '',
    ),
    Track(
      id: 'kimiwa_2',
      title: '君はロックを聴かない - Kimi Wa Rock Wo Kikanai',
      artist: 'aimyon',
      album: 'Kimi Wa Rock Single',
      artworkUrl: 'https://i.ytimg.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
      streamUrl: '',
    ),
    Track(
      id: 'cherry_3',
      title: '桜が降る夜は - On a Cherry Blossom Night',
      artist: 'aimyon',
      album: 'Cherry Night Single',
      artworkUrl: 'https://i.ytimg.com/vi/09R8_2nJtjg/hqdefault.jpg',
      streamUrl: '',
    ),
    Track(
      id: 'track_3636',
      title: '3636',
      artist: 'aimyon',
      album: '3636 Single',
      artworkUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      streamUrl: '',
    ),
    Track(
      id: 'letthenight_5',
      title: '今夜このまま - Let the Night',
      artist: 'aimyon',
      album: 'Let the Night Single',
      artworkUrl: 'https://i.ytimg.com/vi/fJ9rUzIMcZQ/hqdefault.jpg',
      streamUrl: '',
    ),
    Track(
      id: 'herblue_6',
      title: '空の青さを知る人よ - Her Blue Sky',
      artist: 'aimyon',
      album: 'Her Blue Sky Single',
      artworkUrl: 'https://i.ytimg.com/vi/3JZ_D3ELwOQ/hqdefault.jpg',
      streamUrl: '',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final results = await _ytService.searchTracks(query);

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    _ytService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayList = _searchResults.isNotEmpty ? _searchResults : _uniqueSongs;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Bar (Pill shape matching Screenshot 3)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _performSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search YouTube Music or local tracks',
                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.graphic_eq_rounded, color: Colors.cyanAccent),
                          tooltip: 'Identify Song (Shazam)',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MusicRecognitionView(
                                  integrationService: IntegrationService.instance,
                                  onPlayTrack: widget.onPlayTrack,
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.language_rounded, color: Colors.white70),
                          onPressed: _performSearch,
                        ),
                      ],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Explore / Suggestions Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFD4E157),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.explore_outlined, size: 20),
                    text: 'Explore',
                  ),
                  Tab(
                    icon: Icon(Icons.auto_awesome_outlined, size: 20),
                    text: 'Suggestions',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Section Title: Unique Songs
              const Text(
                'Unique Songs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: displayList.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final track = displayList[index];
                      final trackNumber = index + 1;

                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: SizedBox(
                            width: 24,
                            child: Text(
                              '$trackNumber',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          title: Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            track.artist,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.cyanAccent, size: 32),
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}
