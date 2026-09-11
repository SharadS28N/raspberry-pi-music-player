import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/audio_player_service.dart';

class NowPlayingBar extends StatelessWidget {
  final Track track;
  final AudioTarget currentTarget;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final bool isPlaying;

  const NowPlayingBar({
    super.key,
    required this.track,
    required this.currentTarget,
    required this.onTap,
    required this.onPlayPause,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                  color: Colors.cyanAccent.withValues(alpha: 0.2),
                  child: const Icon(Icons.music_note_rounded, color: Colors.cyanAccent, size: 20),
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
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        currentTarget == AudioTarget.piSpeaker ? Icons.radio_rounded : Icons.phone_android_rounded,
                        size: 12,
                        color: currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        currentTarget == AudioTarget.piSpeaker ? 'pi-aamps' : 'This Phone',
                        style: TextStyle(
                          color: currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        ' • ${track.artist}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                color: currentTarget == AudioTarget.piSpeaker ? Colors.purpleAccent : Colors.cyanAccent,
                size: 36,
              ),
              onPressed: onPlayPause,
            ),
          ],
        ),
      ),
    );
  }
}
