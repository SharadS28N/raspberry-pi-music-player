import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/integration_service.dart';
import 'app_alert.dart';

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
  final TextEditingController _userController = TextEditingController();
  bool _isImporting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userController.text = widget.integrationService.spotifyUsername.isNotEmpty
        ? widget.integrationService.spotifyUsername
        : 'sharad_music';
  }

  void _handleImport([String? directQuery]) async {
    final url = directQuery ?? _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid Spotify playlist URL or search query';
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
        AppAlert.show(
          context,
          'Loaded ${tracks.length} tracks from Spotify playlist',
          icon: Icons.check_circle_rounded,
          isSuccess: true,
        );
        Navigator.pop(context);
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
    final isConnected = widget.integrationService.spotifyConnected;

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.library_music_rounded, color: Colors.white, size: 26),
                const SizedBox(width: 10),
                const Text(
                  'Spotify Sync & Playlist Import',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Connect your Spotify account to sync saved tracks and import public playlists.',
              style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
            ),
            const SizedBox(height: 16),

            // Spotify Account Connection Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected ? Colors.white30 : Colors.white10,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isConnected ? Icons.check_circle_rounded : Icons.account_circle_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isConnected
                            ? 'Connected as @${widget.integrationService.spotifyUsername}'
                            : 'Spotify Account Not Linked',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const Spacer(),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                        onPressed: () {
                          if (isConnected) {
                            widget.integrationService.disconnectSpotify();
                            setState(() {});
                          } else {
                            widget.integrationService.connectSpotify(_userController.text.trim());
                            setState(() {});
                          }
                        },
                        child: Text(
                          isConnected ? 'Disconnect' : 'Connect',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  if (!isConnected) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: _userController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Enter Spotify Username or ID',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.04),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Quick Preset Sync Chips
            const Text(
              'QUICK SYNC SPOTIFY PLAYLISTS',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text("Today's Top Hits", style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF222222),
                  onPressed: () => _handleImport("Today's Top Hits"),
                ),
                ActionChip(
                  label: const Text('Pop Hits', style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF222222),
                  onPressed: () => _handleImport('Pop Hits'),
                ),
                ActionChip(
                  label: const Text('Classic Rock', style: TextStyle(color: Colors.white, fontSize: 12)),
                  backgroundColor: const Color(0xFF222222),
                  onPressed: () => _handleImport('Classic Rock'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'OR PASTE SPOTIFY PLAYLIST LINK',
              style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isImporting ? null : () => _handleImport(),
                child: _isImporting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Import & Stream Tracks',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
