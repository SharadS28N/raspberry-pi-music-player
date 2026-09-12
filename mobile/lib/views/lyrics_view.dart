import 'package:flutter/material.dart';
import '../models/track.dart';

class LyricsView extends StatefulWidget {
  final Track track;

  const LyricsView({super.key, required this.track});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  bool _showRomanized = true;
  bool _showTranslation = true;

  final List<Map<String, String>> _lyricsLines = [
    {'kanji': 'しなんて', 'romaji': 'shinante', 'english': 'I don\'t think'},
    {'kanji': '期待していない', 'romaji': 'kitaishi te i nai', 'english': 'I\'m not expecting anything'},
    {'kanji': '期待したくもない', 'romaji': 'kitai shi taku mo nai', 'english': 'I don\'t even want to expect'},
    {'kanji': '君と巡り会った', 'romaji': 'kimito meguriat ta sore', 'english': 'Meeting you was more than'},
    {'kanji': 'それ以上の', 'romaji': 'ijou no', 'english': 'Anything else'},
    {'kanji': 'なんてないから', 'romaji': 'nante nai kara', 'english': 'There is nothing like that'},
  ];

  final int _currentLineIndex = 3;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.track.title,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.track.artist,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.translate_rounded,
              color: _showTranslation ? Colors.cyanAccent : Colors.white54,
            ),
            onPressed: () {
              setState(() {
                _showTranslation = !_showTranslation;
              });
            },
          ),
          IconButton(
            icon: Icon(
              Icons.subtitles_rounded,
              color: _showRomanized ? Colors.purpleAccent : Colors.white54,
            ),
            onPressed: () {
              setState(() {
                _showRomanized = !_showRomanized;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background blurred image
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(widget.track.artworkUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.85),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          // Synced Lyrics List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ListView.builder(
              itemCount: _lyricsLines.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentLineIndex;
                final line = _lyricsLines[index];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(vertical: 14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_showRomanized)
                        Text(
                          line['romaji']!,
                          style: TextStyle(
                            color: isCurrent
                                ? Colors.cyanAccent.withValues(alpha: 0.9)
                                : Colors.white30,
                            fontSize: isCurrent ? 14 : 12,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.5,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        line['kanji']!,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.white38,
                          fontSize: isCurrent ? 28 : 20,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      if (_showTranslation && isCurrent) ...[
                        const SizedBox(height: 6),
                        Text(
                          line['english']!,
                          style: TextStyle(
                            color: Colors.purpleAccent.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
