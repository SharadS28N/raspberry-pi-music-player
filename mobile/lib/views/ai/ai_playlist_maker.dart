import 'package:flutter/material.dart';
import '../../models/playlist.dart';
import '../../models/track.dart';
import '../../services/ai_music_service.dart';

class AiPlaylistMakerModal extends StatefulWidget {
  final Function(Track)? onPlayTrack;

  const AiPlaylistMakerModal({super.key, this.onPlayTrack});

  @override
  State<AiPlaylistMakerModal> createState() => _AiPlaylistMakerModalState();
}

class _AiPlaylistMakerModalState extends State<AiPlaylistMakerModal> {
  final TextEditingController _promptController = TextEditingController();
  bool _isGenerating = false;
  Playlist? _generatedPlaylist;

  final List<String> _examplePrompts = [
    'Late night cyberpunk coding beats',
    '90s rainy day acoustic rock',
    'High energy gym workout motivation',
    'Peaceful Sunday morning lo-fi chill',
    'Upbeat dance party festival anthems',
  ];

  Future<void> _generatePlaylist(String prompt) async {
    if (prompt.trim().isEmpty) return;
    setState(() {
      _isGenerating = true;
      _generatedPlaylist = null;
    });

    try {
      final playlist = await AiMusicService.instance.generatePlaylistFromPrompt(prompt);
      if (mounted) {
        setState(() {
          _generatedPlaylist = playlist;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Generation failed: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Color(0xFF101012),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF242424),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Center(
                    child: Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Playlist Studio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Prompt-driven acoustic synthesis',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Text Prompt Input
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF18181B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.psychology_rounded, color: Colors.white70, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _promptController,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Describe your vibe or occasion...',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                              border: InputBorder.none,
                            ),
                            onSubmitted: (val) => _generatePlaylist(val),
                          ),
                        ),
                        if (_isGenerating)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                            onPressed: () => _generatePlaylist(_promptController.text),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Prompt Idea Chips
                  const Text(
                    'Try these prompts:',
                    style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _examplePrompts.map((example) {
                      return ActionChip(
                        label: Text(example, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        backgroundColor: const Color(0xFF1E1E24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: Colors.white10),
                        ),
                        onPressed: () {
                          _promptController.text = example;
                          _generatePlaylist(example);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Loading State
                  if (_isGenerating) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFF242424),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                            child: const Center(
                              child: Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'AI is synthesizing acoustic harmony...',
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Matching energy, valence, and tempo coordinates',
                            style: TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Generated Playlist Result
                  if (_generatedPlaylist != null && !_isGenerating) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  _generatedPlaylist!.coverUrl,
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.white10,
                                    child: const Icon(Icons.music_note, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF242424),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white12),
                                      ),
                                      child: Text(
                                        _generatedPlaylist!.mood.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _generatedPlaylist!.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_generatedPlaylist!.trackCount} tracks synthesized',
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _generatedPlaylist!.description,
                            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, color: Colors.black),
                              label: const Text('Play Generated Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
                              onPressed: () {
                                if (_generatedPlaylist!.tracks.isNotEmpty && widget.onPlayTrack != null) {
                                  Navigator.pop(context);
                                  widget.onPlayTrack!(_generatedPlaylist!.tracks.first);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Synthesized Track List:',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    ..._generatedPlaylist!.tracks.map((track) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            track.artworkUrl,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: 44,
                              height: 44,
                              color: Colors.white10,
                              child: const Icon(Icons.music_note, color: Colors.white38),
                            ),
                          ),
                        ),
                        title: Text(
                          track.title,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${track.artist} • ${track.tempo.toInt()} BPM',
                          style: const TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 24),
                          onPressed: () {
                            if (widget.onPlayTrack != null) {
                              Navigator.pop(context);
                              widget.onPlayTrack!(track);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
