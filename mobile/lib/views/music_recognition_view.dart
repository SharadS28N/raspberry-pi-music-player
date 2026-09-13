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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    widget.integrationService.recognizeSong();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecognizing = widget.integrationService.isRecognizing;
    final recognizedTrack = widget.integrationService.recognizedTrack;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRecognizing) ...[
                ScaleTransition(
                  scale: Tween<double>(begin: 0.85, end: 1.15).animate(
                    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                  ),
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.cyanAccent.withValues(alpha: 0.8),
                          Colors.purpleAccent.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.cyanAccent.withValues(alpha: 0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.graphic_eq_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Listening to audio around you...',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hold your device close to the music source',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                ),
              ] else if (recognizedTrack != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.network(
                          recognizedTrack.artworkUrl,
                          width: 180,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        recognizedTrack.title,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        recognizedTrack.artist,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 16),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                          label: const Text('Play Recognized Song', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          onPressed: () {
                            widget.onPlayTrack(recognizedTrack);
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
