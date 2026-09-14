import 'dart:async';
import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/lyrics_service.dart';

class LyricsView extends StatefulWidget {
  final Track track;
  final AudioPlayerService? audioService;

  const LyricsView({
    super.key,
    required this.track,
    this.audioService,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  LyricsData? _lyricsData;
  bool _isLoading = true;
  int _activeLineIndex = -1;

  StreamSubscription<Duration>? _posSub;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _fetchLyrics();
    _initAudioListeners();
  }

  void _initAudioListeners() {
    final service = widget.audioService;
    if (service != null) {
      _isPlaying = service.player.playing;
      _currentPosition = service.player.position;
      _totalDuration = service.player.duration ?? widget.track.duration;

      _posSub = service.positionStream.listen((pos) {
        if (!mounted) return;
        setState(() {
          _currentPosition = pos;
        });
        _updateActiveLine(pos);
      });

      service.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });
        }
      });

      service.durationStream.listen((dur) {
        if (mounted && dur != null) {
          setState(() {
            _totalDuration = dur;
          });
        }
      });
    }
  }

  Future<void> _fetchLyrics() async {
    setState(() => _isLoading = true);
    final data = await LyricsService.instance.getLyrics(
      widget.track.title,
      widget.track.artist,
    );
    if (mounted) {
      setState(() {
        _lyricsData = data;
        _isLoading = false;
      });
      if (widget.audioService != null) {
        _updateActiveLine(widget.audioService!.player.position);
      }
    }
  }

  void _updateActiveLine(Duration pos) {
    if (_lyricsData == null || _lyricsData!.lines.isEmpty) return;
    final lines = _lyricsData!.lines;

    int newIndex = -1;
    for (int i = 0; i < lines.length; i++) {
      if (pos >= lines[i].timestamp) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _activeLineIndex && newIndex >= 0) {
      setState(() {
        _activeLineIndex = newIndex;
      });
      if (_scrollController.hasClients) {
        final targetOffset = (newIndex * 70.0) - 140.0;
        _scrollController.animateTo(
          targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;
    final lines = _lyricsData?.lines ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          // Blurred Artwork Backdrop
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(track.artworkUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.92),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.artworkUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 44,
                            height: 44,
                            color: const Color(0xFF181818),
                            child: const Icon(Icons.music_note, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (_lyricsData?.isSynced == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sync_rounded, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                // Lyrics Body
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              SizedBox(height: 16),
                              Text(
                                'Loading synchronized lyrics...',
                                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                              ),
                            ],
                          ),
                        )
                      : lines.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.lyrics_outlined, color: Colors.white38, size: 48),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No lyrics found for "${track.title}"',
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Lyrics will update automatically as community databases synchronize.',
                                      style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                              itemCount: lines.length,
                              itemBuilder: (context, index) {
                                final line = lines[index];
                                final isActive = index == _activeLineIndex;

                                return GestureDetector(
                                  onTap: () {
                                    widget.audioService?.seek(line.timestamp);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                                    child: Text(
                                      line.text,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : Colors.white.withValues(alpha: 0.32),
                                        fontSize: isActive ? 26 : 19,
                                        fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                ),

                // Player Controls & Progress Bar Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212).withValues(alpha: 0.95),
                    border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Seek Bar
                      SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 3,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Color(0xFF27272A),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: _currentPosition.inSeconds.toDouble().clamp(
                                0.0,
                                (_totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1).toDouble(),
                              ),
                          min: 0.0,
                          max: (_totalDuration.inSeconds > 0 ? _totalDuration.inSeconds : 1).toDouble(),
                          onChanged: (val) {
                            widget.audioService?.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Control Buttons Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              final newPos = _currentPosition - const Duration(seconds: 10);
                              widget.audioService?.seek(newPos < Duration.zero ? Duration.zero : newPos);
                            },
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isPlaying) {
                                widget.audioService?.pause();
                              } else {
                                widget.audioService?.resume(fallbackTrack: widget.track);
                              }
                            },
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.white,
                              child: Icon(
                                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 30,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                            onPressed: () {
                              final newPos = _currentPosition + const Duration(seconds: 10);
                              widget.audioService?.seek(newPos > _totalDuration ? _totalDuration : newPos);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
