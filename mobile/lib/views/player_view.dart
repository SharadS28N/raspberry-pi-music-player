import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import '../services/download_service.dart';
import '../services/youtube_service.dart';
import 'lyrics_view.dart';
import 'settings_view.dart';

class PlayerView extends StatefulWidget {
  final Track track;
  final AudioPlayerService audioService;
  final PlayerStyle playerStyle;
  final AudioTarget? currentTarget;
  final PiAampsService? piService;
  final VoidCallback? onToggleTarget;

  const PlayerView({
    super.key,
    required this.track,
    required this.audioService,
    this.playerStyle = PlayerStyle.modern,
    this.currentTarget,
    this.piService,
    this.onToggleTarget,
  });

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 80.0;
  bool _isLiked = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _isShuffle = false;
  LoopMode _loopMode = LoopMode.off;
  Timer? _sleepTimer;

  late AnimationController _vinylController;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.audioService.player.playing;
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (_isPlaying) {
      _vinylController.repeat();
    }

    _position = widget.audioService.player.position;
    _duration = widget.audioService.player.duration ?? widget.track.duration;

    _positionSub = widget.audioService.positionStream.listen((pos) {
      if (mounted && !_isDragging) {
        setState(() {
          _position = pos;
        });
      }
    });

    _durationSub = widget.audioService.durationStream.listen((dur) {
      if (mounted && dur != null && dur > Duration.zero) {
        setState(() {
          _duration = dur;
        });
      }
    });

    _stateSub = widget.audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
        if (state.playing) {
          if (!_vinylController.isAnimating) _vinylController.repeat();
        } else {
          if (_vinylController.isAnimating) _vinylController.stop();
        }
      }
    });

    if (widget.audioService.player.audioSource == null || widget.audioService.currentTrack?.id != widget.track.id) {
      widget.audioService.playTrack(widget.track);
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _vinylController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 32),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'NOW PLAYING',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              track.album,
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white),
            tooltip: 'Download Offline',
            onPressed: () {
              DownloadService.instance.downloadTrack(track, YoutubeService());
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading "${track.title}" for offline playback...'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: const Color(0xFF141414),
                ),
              );
            },
          ),
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
            tooltip: 'Track Options',
            onPressed: () => _showTrackOptionsModal(context, track),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            children: [
              const Spacer(),

              // Artwork View
              _buildArtworkWidget(track),

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
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          track.artist,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _isLiked ? Colors.white : Colors.white60,
                      size: 26,
                    ),
                    onPressed: () {
                      setState(() => _isLiked = !_isLiked);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress Bar Slider + Codec Pill (Pure White & Zinc)
              Builder(
                builder: (context) {
                  final fallbackSec = widget.track.duration.inSeconds > 0
                      ? widget.track.duration.inSeconds.toDouble()
                      : 230.0;
                  final maxSec = _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : fallbackSec;
                  final currentSec = _isDragging
                      ? _dragValue.clamp(0.0, maxSec)
                      : _position.inSeconds.toDouble().clamp(0.0, maxSec);

                  return Column(
                    children: [
                      SliderTheme(
                        data: const SliderThemeData(
                          trackHeight: 3.5,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Color(0xFF27272A),
                          thumbColor: Colors.white,
                        ),
                        child: Slider(
                          value: currentSec,
                          min: 0.0,
                          max: maxSec,
                          onChanged: (val) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = val;
                            });
                          },
                          onChangeEnd: (val) {
                            setState(() {
                              _isDragging = false;
                              _position = Duration(seconds: val.toInt());
                            });
                            widget.audioService.seek(Duration(seconds: val.toInt()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_isDragging ? Duration(seconds: _dragValue.toInt()) : _position),
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                            ),

                            // Audio Codec Format Pill
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141414),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    track.codec,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),

                            Text(
                              _formatDuration(_duration > Duration.zero ? _duration : Duration(seconds: maxSec.toInt())),
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),

              // Playback Controls (Shuffle, Rewind 10s, Play/Pause, Fast-Forward 10s, Repeat)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      color: _isShuffle ? Colors.white : Colors.white38,
                      size: 26,
                    ),
                    tooltip: _isShuffle ? 'Shuffle On' : 'Shuffle Off',
                    onPressed: () {
                      setState(() => _isShuffle = !_isShuffle);
                      widget.audioService.setShuffleModeEnabled(_isShuffle);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isShuffle ? 'Shuffle enabled' : 'Shuffle disabled'),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF141414),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 34),
                    tooltip: 'Rewind 10s',
                    onPressed: () {
                      final target = _position - const Duration(seconds: 10);
                      widget.audioService.seek(target < Duration.zero ? Duration.zero : target);
                    },
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_isPlaying) {
                        widget.audioService.pause();
                      } else {
                        if (widget.audioService.player.audioSource == null) {
                          widget.audioService.playTrack(widget.track);
                        } else {
                          widget.audioService.resume(fallbackTrack: widget.track);
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
                      child: Center(
                        child: (widget.audioService.isLoading && !_isPlaying && !widget.audioService.player.playing)
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                              )
                            : Icon(
                                (_isPlaying || widget.audioService.player.playing)
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 38,
                              ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 34),
                    tooltip: 'Forward 10s',
                    onPressed: () {
                      final target = _position + const Duration(seconds: 10);
                      widget.audioService.seek(target > _duration ? _duration : target);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      _loopMode == LoopMode.one
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      color: _loopMode != LoopMode.off ? Colors.white : Colors.white38,
                      size: 26,
                    ),
                    tooltip: _loopMode == LoopMode.off
                        ? 'Repeat Off'
                        : (_loopMode == LoopMode.one ? 'Repeat Track' : 'Repeat All'),
                    onPressed: () {
                      setState(() {
                        if (_loopMode == LoopMode.off) {
                          _loopMode = LoopMode.all;
                        } else if (_loopMode == LoopMode.all) {
                          _loopMode = LoopMode.one;
                        } else {
                          _loopMode = LoopMode.off;
                        }
                      });
                      widget.audioService.setLoopMode(_loopMode);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            _loopMode == LoopMode.one
                                ? 'Loop current track'
                                : (_loopMode == LoopMode.all ? 'Loop all tracks' : 'Loop disabled'),
                          ),
                          duration: const Duration(seconds: 1),
                          backgroundColor: const Color(0xFF141414),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Volume Slider (Monochrome)
              Row(
                children: [
                  const Icon(Icons.volume_mute_rounded, color: Color(0xFF71717A), size: 20),
                  Expanded(
                    child: SliderTheme(
                      data: const SliderThemeData(
                        trackHeight: 3,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Color(0xFF27272A),
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
                          widget.audioService.setVolume(val);
                        },
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded, color: Color(0xFF71717A), size: 20),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Action Bar (Queue List, Lyrics, Sleep Timer, Equalizer/DSP)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFFA1A1AA), size: 22),
                    tooltip: 'Queue',
                    onPressed: () => _showQueueModal(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFA1A1AA), size: 22),
                    tooltip: 'Lyrics',
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
                    icon: const Icon(Icons.bedtime_outlined, color: Color(0xFFA1A1AA), size: 22),
                    tooltip: 'Sleep Timer',
                    onPressed: () => _showSleepTimerModal(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.equalizer_rounded, color: Color(0xFFA1A1AA), size: 22),
                    tooltip: 'Audio Settings & Equalizer',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SettingsView()),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
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
                color: Colors.black.withValues(alpha: 0.8),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
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

  void _showQueueModal(BuildContext context) {
    final upcomingQueue = [
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
        id: 'H5v3kku4y6Q',
        title: 'As It Was',
        artist: 'Harry Styles',
        album: "Harry's House",
        duration: const Duration(minutes: 2, seconds: 47),
        artworkUrl: 'https://i.ytimg.com/vi/H5v3kku4y6Q/hqdefault.jpg',
        streamUrl: '',
        codec: 'AAC 320kbps',
      ),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Now Playing & Queue',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'NOW PLAYING',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(widget.track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  title: Text(widget.track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(widget.track.artist, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                  trailing: const Icon(Icons.volume_up_rounded, color: Colors.white),
                ),
                const Divider(color: Colors.white12),
                const Text(
                  'UP NEXT',
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: upcomingQueue.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 6),
                    itemBuilder: (c, i) {
                      final qTrack = upcomingQueue[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(qTrack.artworkUrl, width: 40, height: 40, fit: BoxFit.cover),
                        ),
                        title: Text(qTrack.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                        subtitle: Text(qTrack.artist, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                        trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                        onTap: () {
                          Navigator.pop(ctx);
                          widget.audioService.playTrack(qTrack);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerView(
                                track: qTrack,
                                audioService: widget.audioService,
                                playerStyle: widget.playerStyle,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSleepTimerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = [15, 30, 45, 60];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sleep Timer',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...options.map((mins) => ListTile(
                      leading: const Icon(Icons.access_time_rounded, color: Colors.white),
                      title: Text('$mins minutes', style: const TextStyle(color: Colors.white)),
                      onTap: () {
                        _sleepTimer?.cancel();
                        _sleepTimer = Timer(Duration(minutes: mins), () {
                          widget.audioService.pause();
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Playback will stop in $mins minutes'),
                            backgroundColor: const Color(0xFF141414),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    )),
                ListTile(
                  leading: const Icon(Icons.timer_off_outlined, color: Colors.white70),
                  title: const Text('Turn Off Timer', style: TextStyle(color: Colors.white70)),
                  onTap: () {
                    _sleepTimer?.cancel();
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sleep timer disabled'),
                        backgroundColor: Color(0xFF141414),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTrackOptionsModal(BuildContext context, Track track) {
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
                    child: Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover),
                  ),
                  title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${track.artist} • ${track.album}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.download_rounded, color: Colors.white),
                  title: const Text('Download for Offline', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    DownloadService.instance.downloadTrack(track, YoutubeService());
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${track.title}" offline...'),
                        backgroundColor: const Color(0xFF141414),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.playlist_add_rounded, color: Colors.white),
                  title: const Text('Add to Playlist', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added "${track.title}" to Favorites'),
                        backgroundColor: const Color(0xFF141414),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.equalizer_rounded, color: Colors.white),
                  title: const Text('Audio Settings & DSP', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsView()),
                    );
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
