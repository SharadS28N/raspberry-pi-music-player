import 'package:flutter/material.dart';
import '../../models/track.dart';
import '../../services/ai_music_service.dart';

class WhyRecommendedModal extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;

  const WhyRecommendedModal({
    super.key,
    required this.track,
    this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final analysis = AiMusicService.instance.explainRecommendation(track);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121214),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header with AI Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'AI ACOUSTIC DNA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Track Card
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: track.artworkUrl.isNotEmpty
                    ? Image.network(
                        track.artworkUrl,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 58,
                          height: 58,
                          color: const Color(0xFF222226),
                          child: const Icon(Icons.music_note, color: Colors.white54),
                        ),
                      )
                    : Container(
                        width: 58,
                        height: 58,
                        color: const Color(0xFF222226),
                        child: const Icon(Icons.music_note, color: Colors.white54),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${track.artist} • ${track.genre}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${(analysis.matchPercentage * 100).toInt()}% Match',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Primary Reasoning Headline
          Text(
            analysis.primaryReason,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),

          // Acoustic Feature Compatibility Bars
          ...analysis.acousticMatches.entries.map((entry) {
            final pct = (entry.value * 100).toInt();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      backgroundColor: Colors.white10,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        entry.value > 0.75
                            ? Colors.greenAccent
                            : (entry.value > 0.5 ? Colors.amberAccent : Colors.lightBlueAccent),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 14),

          // Reasoning Bullets
          ...analysis.detailedReasons.map((bullet) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bullet,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 20),

          // Action Buttons
          if (onPlay != null)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                label: const Text('Play Track Now', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(context);
                  onPlay!();
                },
              ),
            ),
        ],
      ),
    );
  }
}
