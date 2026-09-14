import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/integration_service.dart';

class SpotifyImportModal extends StatefulWidget {
  final IntegrationService integrationService;
  final Function(List<Track>) onImportSuccess;

  const SpotifyImportModal({
    super.key,
    required this.integrationService,
    required this.onImportSuccess,
  });

  @override
  State<SpotifyImportModal> createState() => _SpotifyImportModalState();
}

class _SpotifyImportModalState extends State<SpotifyImportModal> {
  final TextEditingController _urlController = TextEditingController();
  bool _isImporting = false;
  String? _errorMessage;

  void _handleImport() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Spotify playlist URL or URI';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _errorMessage = null;
    });

    try {
      final tracks = await widget.integrationService.importSpotifyPlaylist(url);
      if (mounted) {
        widget.onImportSuccess(tracks);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${tracks.length} tracks from Spotify!'),
            backgroundColor: const Color(0xFF141414),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to parse Spotify playlist. Please verify the URL.';
          _isImporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.library_music_rounded, color: Colors.white, size: 26),
              SizedBox(width: 10),
              Text(
                'Import Spotify Playlist',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Paste any public Spotify playlist link to match and stream tracks seamlessly.',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'https://open.spotify.com/playlist/...',
              hintStyle: const TextStyle(color: Color(0xFF71717A), fontSize: 13),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.link_rounded, color: Colors.white70),
              errorText: _errorMessage,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isImporting ? null : _handleImport,
              child: _isImporting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Import Playlist Tracks',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
