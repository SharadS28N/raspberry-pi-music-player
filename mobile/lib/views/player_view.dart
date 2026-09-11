import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';

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
  double _volume = 80;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F19),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.currentTarget == AudioTarget.piSpeaker ? '📻 Playing on pi-aamps' : '📱 Playing on This Phone',
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.currentTarget == AudioTarget.piSpeaker ? Icons.radio_rounded : Icons.phone_android_rounded,
              color: widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
            ),
            onPressed: widget.onToggleTarget,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent).withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    widget.track.artworkUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF1E293B),
                      child: const Icon(Icons.music_note_rounded, size: 80, color: Colors.cyanAccent),
                    ),
                  ),
                ),
              ),

              Column(
                children: [
                  Text(
                    widget.track.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.track.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              Column(
                children: [
                  SliderTheme(
                    data: SliderThemeData(
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                    ),
                    child: Slider(
                      value: 0.3,
                      onChanged: (val) {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('01:15', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                        Text('03:45', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shuffle_rounded, color: Colors.white54, size: 24),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 36),
                    onPressed: () {},
                  ),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                      boxShadow: [
                        BoxShadow(
                          color: (widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent).withValues(alpha: 0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 40,
                      icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.black),
                      onPressed: () {
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
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 36),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.repeat_rounded, color: Colors.white54, size: 24),
                    onPressed: () {},
                  ),
                ],
              ),

              Row(
                children: [
                  const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 20),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      min: 0,
                      max: 100,
                      activeColor: widget.currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                      inactiveColor: Colors.white.withValues(alpha: 0.1),
                      onChanged: (val) {
                        setState(() {
                          _volume = val;
                        });
                        if (widget.currentTarget == AudioTarget.piSpeaker) {
                          widget.piService.setVolume(val.toInt());
                        } else {
                          widget.audioService.setVolume(val / 100.0);
                        }
                      },
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
