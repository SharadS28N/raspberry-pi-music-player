import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';
import '../services/settings_service.dart';
import 'output_target_modal.dart';

class NowPlayingBar extends StatelessWidget {
  final Track track;
  final AudioPlayerService audioService;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final bool isPlaying;
  final AudioTarget? currentTarget;

  const NowPlayingBar({
    super.key,
    required this.track,
    required this.audioService,
    required this.onTap,
    required this.onPlayPause,
    required this.isPlaying,
    this.currentTarget,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        final accent = SettingsService.instance.accentColor;
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.7),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            track.artworkUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 44,
                              height: 44,
                              color: const Color(0xFF222222),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white70, size: 20),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                style: const TextStyle(
                                  color: Color(0xFFA1A1AA),
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Target Switcher Button
                        IconButton(
                          icon: Icon(
                            audioService.target == AudioTarget.piSpeaker
                                ? Icons.radio_rounded
                                : Icons.phone_android_rounded,
                            color: audioService.target == AudioTarget.piSpeaker
                                ? accent
                                : Colors.white70,
                            size: 22,
                          ),
                          tooltip: audioService.target == AudioTarget.piSpeaker
                              ? 'Streaming to pi-aamps'
                              : 'Playing on this Phone',
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (modalCtx) => OutputTargetModal(
                                currentTarget: audioService.target,
                                onSelectTarget: (target) {
                                  audioService.setAudioTarget(target);
                                },
                                piService: audioService.piService,
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                            color: accent,
                            size: 36,
                          ),
                          onPressed: onPlayPause,
                        ),
                      ],
                    ),
                  ),

                  // Active Real-time Moving Progress Bar (Dynamic Accent)
                  StreamBuilder<Duration>(
                    stream: audioService.positionStream,
                    builder: (context, snapshot) {
                      final pos = snapshot.data ?? audioService.currentPosition;
                      final dur = audioService.currentDuration;
                      final maxSec = dur.inSeconds > 0 ? dur.inSeconds.toDouble() : 230.0;
                      final ratio = (pos.inSeconds / maxSec).clamp(0.0, 1.0);

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 2.5,
                            width: constraints.maxWidth,
                            color: Colors.white.withValues(alpha: 0.08),
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: constraints.maxWidth * ratio,
                              height: 2.5,
                              color: accent,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
