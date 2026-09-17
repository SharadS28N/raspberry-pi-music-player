import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/local_audio_service.dart';

class TagEditorModal extends StatefulWidget {
  final Track track;
  final VoidCallback? onSaved;

  const TagEditorModal({
    super.key,
    required this.track,
    this.onSaved,
  });

  @override
  State<TagEditorModal> createState() => _TagEditorModalState();
}

class _TagEditorModalState extends State<TagEditorModal> {
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _albumController;
  late TextEditingController _lyricsController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album);
    _lyricsController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _saveTags() {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();
    final lyrics = _lyricsController.text.trim();

    LocalAudioService.instance.updateTrackMetadata(
      widget.track.id,
      title: title.isNotEmpty ? title : null,
      artist: artist.isNotEmpty ? artist : null,
      album: album.isNotEmpty ? album : null,
      lyrics: lyrics.isNotEmpty ? lyrics : null,
    );

    widget.onSaved?.call();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Song tags updated successfully!'),
        backgroundColor: Color(0xFF222222),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.edit_note_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Built-in Tag Editor',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: _saveTags,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              children: [
                _buildField(controller: _titleController, label: 'Track Title', icon: Icons.music_note_rounded),
                const SizedBox(height: 12),
                _buildField(controller: _artistController, label: 'Artist / Performer', icon: Icons.person_rounded),
                const SizedBox(height: 12),
                _buildField(controller: _albumController, label: 'Album Name', icon: Icons.album_rounded),
                const SizedBox(height: 12),
                _buildField(
                  controller: _lyricsController,
                  label: 'Embedded Lyrics (LRC or Plain)',
                  icon: Icons.lyrics_rounded,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                if (widget.track.localPath != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('FILE LOCATION', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        const SizedBox(height: 4),
                        Text(widget.track.localPath!, style: const TextStyle(color: Colors.white70, fontSize: 11)),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: const Color(0xFF1A1A1C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
