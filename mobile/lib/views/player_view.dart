import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import 'lyrics_view.dart';

class PlayerView extends StatefulWidget {
  final Track track;
  final AudioTarget currentTarget;
  final AudioPlayerService audioService;
  final PiAampsService piService;
  final VoidCallback onToggleTarget;

  const PlayerView({
    super.key,
    required this.track,
    required this.currentTarget,
    required this.audioService,
    required this.piService,
    required this.onToggleTarget,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool _isPlaying = true;
  double _currentPosition = 135.0; // 2:15
  final double _totalDuration = 198.0; // 3:18 (-1:03 remaining)
  double _volume = 80.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.track.album,
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
                  builder: (context) => LyricsView(track: widget.track),
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
          // Blurred Artwork Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.track.artworkUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.85),
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

                  // Album Artwork Box
                  Hero(
                    tag: 'player_artwork',
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: widget.currentTarget == AudioTarget.piSpeaker
                                ? Colors.purpleAccent.withValues(alpha: 0.3)
                                : Colors.cyanAccent.withValues(alpha: 0.3),
                            blurRadius: 25,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(widget.track.artworkUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Track Info & Like Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.track.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.track.artist,
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
                        icon: const Icon(Icons.favorite_rounded, color: Colors.cyanAccent, size: 28),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Progress Bar Slider (Matching Screenshot 2: 2:15 / -1:03)
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
                        const Text('2:15', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const Text('-1:03', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Playback Controls (Rewind, Play/Pause, Fast-Forward)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded, color: Colors.white54, size: 24),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 36),
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
                        icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 36),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.repeat_rounded, color: Colors.white54, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bottom Bar with Volume Slider & Cast Target Modal Trigger
                  Row(
                    children: [
                      const Icon(Icons.volume_mute_rounded, color: Colors.white54, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                            activeTrackColor: widget.currentTarget == AudioTarget.piSpeaker
                                ? Colors.purpleAccent
                                : Colors.cyanAccent,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: widget.currentTarget == AudioTarget.piSpeaker
                                ? Colors.purpleAccent
                                : Colors.cyanAccent,
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
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          widget.currentTarget == AudioTarget.piSpeaker
                              ? Icons.radio_rounded
                              : Icons.speaker_group_rounded,
                          color: widget.currentTarget == AudioTarget.piSpeaker
                              ? Colors.purpleAccent
                              : Colors.cyanAccent,
                        ),
                        onPressed: widget.onToggleTarget,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
