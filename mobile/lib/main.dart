import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/track.dart';
import 'services/audio_player_service.dart';
import 'services/account_service.dart';
import 'services/local_audio_service.dart';
import 'services/firebase_service.dart';
import 'services/ai_music_service.dart';
import 'services/settings_service.dart';
import 'views/auth/auth_gate.dart';
import 'views/home_view.dart';
import 'views/search_view.dart';
import 'views/player_view.dart';
import 'views/pi_hub_view.dart';
import 'views/library_view.dart';
import 'views/ai/ai_assistant_view.dart';
import 'widgets/now_playing_bar.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with generated options
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseService.instance.initialize();
  } catch (e) {
    debugPrint('[Firebase] Initialization skipped or error: $e');
  }

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.openaamps.open_aamps.channel.audio',
    androidNotificationChannelName: 'OpenAamps Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: true,
    androidNotificationIcon: 'drawable/ic_bg_service_small',
  );
  runApp(const OpenAampsApp());
}

class OpenAampsApp extends StatelessWidget {
  const OpenAampsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final accent = SettingsService.instance.accentColor;
        return MaterialApp(
          title: 'OpenAamps',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF000000),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.dark(
              primary: accent,
              secondary: Colors.white70,
              surface: const Color(0xFF121212),
            ),
          ),
          home: const AuthGate(),
        );
      },
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
  final AudioPlayerService _audioService = AudioPlayerService();

  Track _activeTrack = Track(
    id: 'yKNxeF4KMsY',
    title: 'Yellow',
    artist: 'Coldplay',
    album: 'Parachutes',
    artworkUrl: 'https://i.ytimg.com/vi/yKNxeF4KMsY/hqdefault.jpg',
    streamUrl: '',
    codec: 'AAC 320kbps',
  );

  bool _isPlaying = false;
  StreamSubscription<PlayerState>? _playerStateSub;

  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
    _playerStateSub = _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
      if (state.processingState == ProcessingState.completed) {
        AiMusicService.instance.onTrackCompleted(
          _activeTrack,
          _activeTrack.duration.inSeconds > 0
              ? _activeTrack.duration.inSeconds.toDouble()
              : 180.0,
        );
      }
    });
  }

  void _requestNotificationPermission() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final status = await Permission.notification.status;
        if (!status.isGranted) {
          await Permission.notification.request();
        }
      } catch (e) {
        debugPrint('Notification permission request error: $e');
      }
    });
  }

  void _onPlayTrack(Track track) {
    setState(() {
      _activeTrack = track;
      _isPlaying = true;
    });
    _audioService.playTrack(track);
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeView(
        onPlayTrack: _onPlayTrack,
        audioService: _audioService,
      ),
      SearchView(onPlayTrack: _onPlayTrack),
      AiAssistantView(
        audioService: _audioService,
        onPlayTrack: _onPlayTrack,
      ),
      LibraryView(
        accountService: AccountService.instance,
        localAudioService: LocalAudioService(),
        onPlayTrack: _onPlayTrack,
        audioService: _audioService,
      ),
      PiHubView(piService: _audioService.piService),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 74.0),
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: NowPlayingBar(
              track: _activeTrack,
              audioService: _audioService,
              isPlaying: _isPlaying,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlayerView(
                      track: _activeTrack,
                      audioService: _audioService,
                    ),
                  ),
                );
              },
              onPlayPause: () {
                if (_isPlaying) {
                  _audioService.pause();
                } else {
                  _audioService.resume(fallbackTrack: _activeTrack);
                }
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.8)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: const Color(0xFF000000),
          indicatorColor: Colors.white.withValues(alpha: 0.14),
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.search_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.search_rounded, color: Colors.white),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.auto_awesome, color: Colors.white),
              label: 'AI Studio',
            ),
            NavigationDestination(
              icon: Icon(Icons.library_music_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.library_music_rounded, color: Colors.white),
              label: 'Library',
            ),
            NavigationDestination(
              icon: Icon(Icons.radio_outlined, color: Colors.white60),
              selectedIcon: Icon(Icons.radio_rounded, color: Colors.white),
              label: 'pi-aamps',
            ),
          ],
        ),
      ),
    );
  }
}
