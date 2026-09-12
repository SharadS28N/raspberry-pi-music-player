import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/track.dart';
import 'services/audio_player_service.dart';
import 'services/pi_aamps_service.dart';
import 'views/home_view.dart';
import 'views/search_view.dart';
import 'views/player_view.dart';
import 'views/pi_hub_view.dart';
import 'views/library_view.dart';
import 'widgets/now_playing_bar.dart';
import 'widgets/output_target_modal.dart';

void main() {
  runApp(const OpenAampsApp());
}

class OpenAampsApp extends StatelessWidget {
  const OpenAampsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAamps',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.purpleAccent,
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  AudioTarget _currentTarget = AudioTarget.phoneLocal;
  final AudioPlayerService _audioService = AudioPlayerService();
  final PiAampsService _piService = PiAampsService();

  Track _activeTrack = Track(
    id: 'dQw4w9WgXcQ',
    title: 'Never Gonna Give You Up',
    artist: 'Rick Astley',
    album: 'Whenever You Need Somebody',
    artworkUrl: 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    streamUrl: '',
  );

  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _piService.checkConnection();
  }

  void _onPlayTrack(Track track) {
    setState(() {
      _activeTrack = track;
      _isPlaying = true;
    });

    if (_currentTarget == AudioTarget.piSpeaker) {
      _piService.playTrackOnPi(track);
    } else {
      _audioService.playTrack(track);
    }
  }

  void _toggleTarget() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => OutputTargetModal(
        currentTarget: _currentTarget,
        onSelectTarget: (target) {
          setState(() {
            _currentTarget = target;
            _audioService.setAudioTarget(target);
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    _audioService.dispose();
    _piService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeView(
        onPlayTrack: _onPlayTrack,
        currentTarget: _currentTarget,
        piService: _piService,
      ),
      SearchView(onPlayTrack: _onPlayTrack),
      LibraryView(onPlayTrack: _onPlayTrack),
      PiHubView(piService: _piService),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 70.0),
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NowPlayingBar(
                  track: _activeTrack,
                  currentTarget: _currentTarget,
                  isPlaying: _isPlaying,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PlayerView(
                          track: _activeTrack,
                          currentTarget: _currentTarget,
                          audioService: _audioService,
                          piService: _piService,
                          onToggleTarget: _toggleTarget,
                        ),
                      ),
                    );
                  },
                  onPlayPause: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                    if (_currentTarget == AudioTarget.piSpeaker) {
                      _piService.togglePlayPause();
                    } else {
                      if (_isPlaying) {
                        _audioService.resume();
                      } else {
                        _audioService.pause();
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF0F172A),
        indicatorColor: _currentTarget == AudioTarget.piSpeaker
            ? Colors.purpleAccent.withValues(alpha: 0.2)
            : Colors.cyanAccent.withValues(alpha: 0.2),
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Colors.cyanAccent),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: Colors.cyanAccent),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_music_outlined),
            selectedIcon: Icon(Icons.library_music_rounded, color: Colors.cyanAccent),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.radio_outlined),
            selectedIcon: Icon(Icons.radio_rounded, color: Colors.purpleAccent),
            label: 'pi-aamps',
          ),
        ],
      ),
    );
  }
}
