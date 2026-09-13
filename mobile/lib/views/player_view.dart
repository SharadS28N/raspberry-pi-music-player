import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import 'lyrics_view.dart';
import 'settings_view.dart';

class PlayerView extends StatefulWidget {
  final Track track;
  final AudioTarget currentTarget;
  final AudioPlayerService audioService;
  final PiAampsService piService;
  final VoidCallback onToggleTarget;
  final PlayerStyle playerStyle;

  const PlayerView({
    super.key,
    required this.track,
    required this.currentTarget,
    required this.audioService,
    required this.piService,
    required this.onToggleTarget,
    this.playerStyle = PlayerStyle.modern,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  double _currentPosition = 38.0; // 0:38 (Matching screenshot_7.jpg)
  final double _totalDuration = 198.0; // 3:18
  double _volume = 80.0;
  bool _isLiked = false;

  late AnimationController _vinylController;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.currentTarget == AudioTarget.piSpeaker ? 'PLAYING ON PI-AAMPS' : 'PLAYING ON THIS PHONE',
              style: TextStyle(
                color: widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              track.album,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lyrics_outlined, color: Colors.white),
            tooltip: 'Live Synced Lyrics',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LyricsView(track: track),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          // Blurred Backdrop Image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(track.artworkUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: widget.playerStyle == PlayerStyle.glassmorphism ? 0.75 : 0.90),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  const Spacer(),

                  // Artwork View (Matching screenshot_7.jpg & custom styles)
                  _buildArtworkWidget(track),

                  const Spacer(),

                  // Track Info & Like Button (Matching screenshot_7.jpg)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              track.artist,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isLiked ? Colors.redAccent : Colors.white70,
                          size: 26,
                        ),
                        onPressed: () {
                          setState(() => _isLiked = !_isLiked);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Bar Slider + Codec Pill (Matching screenshot_7.jpg)
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: _currentPosition,
                      min: 0.0,
                      max: _totalDuration,
                      onChanged: (val) {
                        setState(() {
                          _currentPosition = val;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0:38', style: TextStyle(color: Colors.white70, fontSize: 12)),

                        // Audio Codec Format Pill (Matching screenshot_7.jpg)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.graphic_eq_rounded, color: Colors.white70, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                track.codec,
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),

                        const Text('3:18', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Playback Controls (Rewind, Play/Pause, Fast-Forward)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 40),
                        onPressed: () {},
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                          if (widget.currentTarget == AudioTarget.piSpeaker) {
                            widget.piService.togglePlayPause();
                          } else {
                            if (_isPlaying) {
                              widget.audioService.resume();
                            } else {
                              widget.audioService.pause();
                            }
                          }
                        },
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.black,
                            size: 38,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 40),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Volume Slider
                  Row(
                    children: [
                      const Icon(Icons.volume_mute_rounded, color: Colors.white54, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            activeTrackColor: Colors.white70,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 100.0,
                            onChanged: (val) {
                              setState(() {
                                _volume = val;
                              });
                              if (widget.currentTarget == AudioTarget.piSpeaker) {
                                widget.piService.setVolume(val.toInt());
                              }
                            },
                          ),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Action Bar (Queue List, Lyrics, Sleep Timer, Cast Target Pill)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.format_list_bulleted_rounded, color: Colors.white70, size: 22),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white70, size: 22),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LyricsView(track: track),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.bedtime_outlined, color: Colors.white70, size: 22),
                        onPressed: () {},
                      ),

                      // Cast Target Speaker Pill (Matching screenshot_7.jpg)
                      GestureDetector(
                        onTap: widget.onToggleTarget,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                widget.currentTarget == AudioTarget.piSpeaker
                                    ? Icons.radio_rounded
                                    : Icons.speaker_rounded,
                                color: widget.currentTarget == AudioTarget.piSpeaker
                                    ? Colors.purpleAccent
                                    : Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.currentTarget == AudioTarget.piSpeaker ? 'pi-aamps' : 'Speaker',
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkWidget(Track track) {
    if (widget.playerStyle == PlayerStyle.vinyl) {
      return RotationTransition(
        turns: _vinylController,
        child: Container(
          width: 270,
          height: 270,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            border: Border.all(color: Colors.white24, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                spreadRadius: 4,
              ),
            ],
            image: DecorationImage(
              image: NetworkImage(track.artworkUrl),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 290,
      height: 290,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: widget.currentTarget == AudioTarget.piSpeaker
                ? Colors.purpleAccent.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(track.artworkUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
