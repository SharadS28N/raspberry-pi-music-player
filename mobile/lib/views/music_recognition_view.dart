import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/integration_service.dart';

class MusicRecognitionView extends StatefulWidget {
  final IntegrationService integrationService;
  final Function(Track) onPlayTrack;

  const MusicRecognitionView({
    super.key,
    required this.integrationService,
    required this.onPlayTrack,
  });

  @override
  State<MusicRecognitionView> createState() => _MusicRecognitionViewState();
}

class _MusicRecognitionViewState extends State<MusicRecognitionView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _lyricsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    widget.integrationService.recognizeSong();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _searchByLyrics() {
    final query = _lyricsController.text.trim();
    if (query.isNotEmpty) {
      widget.integrationService.recognizeSong(searchHint: query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.integrationService,
      builder: (context, _) {
        final isRecognizing = widget.integrationService.isRecognizing;
        final recognizedTrack = widget.integrationService.recognizedTrack;

        return Scaffold(
          backgroundColor: const Color(0xFF000000),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Music Recognition',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                if (isRecognizing) ...[
                  ScaleTransition(
                    scale: Tween<double>(begin: 0.88, end: 1.12).animate(
                      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                    ),
                    child: Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.28),
                            Colors.white.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.12),
                            blurRadius: 45,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.graphic_eq_rounded,
                        color: Colors.white,
                        size: 68,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  const Text(
                    'Listening to audio around you...',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hold your device close to the audio source',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 14),
                  ),
                ] else if (recognizedTrack != null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF141414),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'MATCH IDENTIFIED',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                          ),
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            recognizedTrack.artworkUrl,
                            width: 190,
                            height: 190,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 190,
                              height: 190,
                              color: const Color(0xFF222222),
                              child: const Icon(Icons.music_note_rounded, color: Colors.white54, size: 64),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          recognizedTrack.title,
                          style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          recognizedTrack.artist,
                          style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                            label: const Text('Play Recognized Song', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            onPressed: () {
                              widget.onPlayTrack(recognizedTrack);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
                          label: const Text('Listen Again', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          onPressed: () => widget.integrationService.recognizeSong(),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const Icon(Icons.search_off_rounded, color: Colors.white38, size: 60),
                  const SizedBox(height: 14),
                  const Text('No audio detected', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.mic_rounded, color: Colors.black),
                    label: const Text('Retry Listening'),
                    onPressed: () => widget.integrationService.recognizeSong(),
                  ),
                ],

                const SizedBox(height: 36),
                // Or Search By Heard Lyrics / Hummed Tune
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'OR RECOGNIZE BY HEARD LYRICS / TITLE',
                        style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lyricsController,
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              onSubmitted: (_) => _searchByLyrics(),
                              decoration: InputDecoration(
                                hintText: 'Enter heard lyrics, humming or title...',
                                hintStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.05),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                            onPressed: _searchByLyrics,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
