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
      id: '34Na4j8AVgA',
      title: 'Starboy',
      artist: 'The Weeknd ft. Daft Punk',
      album: 'Starboy (Deluxe)',
      artworkUrl: 'https://i.ytimg.com/vi/34Na4j8AVgA/hqdefault.jpg',
      streamUrl: '',
      codec: 'FLAC 24-bit',
    ),
    Track(
      id: '4NRXx6U8ABQ',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      artworkUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
      streamUrl: '',
      codec: 'OPUS 160kbps',
    ),
    Track(
      id: 'H5v3kku4y6Q',
      title: 'As It Was',
      artist: 'Harry Styles',
      album: "Harry's House",
      artworkUrl: 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg',
      streamUrl: '',
      codec: 'AAC 320kbps',
    ),
    Track(
      id: 'TUVcZfQe-Kw',
      title: 'Levitating',
      artist: 'Dua Lipa',
      album: 'Future Nostalgia',
      artworkUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
      streamUrl: '',
      codec: 'OPUS 160kbps',
    ),
    Track(
      id: 'G7KNmW9a75Y',
      title: 'Flowers',
      artist: 'Miley Cyrus',
      album: 'Endless Summer Vacation',
      artworkUrl: 'https://i.ytimg.com/vi/G7KNmW9a75Y/hqdefault.jpg',
      streamUrl: '',
      codec: 'FLAC 24-bit',
    ),
    Track(
      id: 'ic8j13g5JTQ',
      title: 'Cruel Summer',
      artist: 'Taylor Swift',
      album: 'Lover',
      artworkUrl: 'https://i.ytimg.com/vi/ic8j13g5JTQ/hqdefault.jpg',
      streamUrl: '',
      codec: 'AAC 320kbps',
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
