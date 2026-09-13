import 'package:flutter/material.dart';
import '../models/track.dart';

class LyricsView extends StatefulWidget {
  final Track track;

  const LyricsView({
    super.key,
    required this.track,
  });

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  bool _showRomaji = true;
  bool _showTranslation = true;
  int _activeLineIndex = 3;

  final List<Map<String, String>> _lyricsData = [
    {
      'kanji': 'なんて 期待していない',
      'romaji': 'nante kitaishi te i nai',
      'translation': 'I don\'t expect anything like that',
    },
    {
      'kanji': '期待したくもない',
      'romaji': 'kitai shi taku mo nai',
      'translation': 'I don\'t even want to expect it',
    },
    {
      'kanji': '君と巡り 会った',
      'romaji': 'kimito meguriat ta sore',
      'translation': 'When I met you and crossed paths',
    },
    {
      'kanji': 'それ以上の',
      'romaji': 'ijou no',
      'translation': 'More than that',
    },
    {
      'kanji': 'どんでん返しなんてないから',
      'romaji': 'dondengaeshi nante nai kara',
      'translation': 'Because there is no plot twist coming',
    },
    {
      'kanji': 'しなんてないから',
      'romaji': 'shi nante nai kara',
      'translation': 'Because nothing will change',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final track = widget.track;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // Blurred Artwork Backdrop
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(track.artworkUrl),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withValues(alpha: 0.88),
                    BlendMode.darken,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  // Top Header (Matching screenshot_2.jpg)
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          track.artworkUrl,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              track.artist,
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                            ),
                          ],
                        ),
                      ),

                      // Romaji Toggle Button
                      IconButton(
                        icon: Icon(
                          Icons.translate_rounded,
                          color: _showRomaji ? Colors.cyanAccent : Colors.white54,
                          size: 22,
                        ),
                        tooltip: 'Toggle Romaji Romanization',
                        onPressed: () => setState(() => _showRomaji = !_showRomaji),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Synced Lyrics Center View (Matching screenshot_2.jpg)
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: _lyricsData.length,
                      itemBuilder: (context, index) {
                        final line = _lyricsData[index];
                        final isActive = index == _activeLineIndex;

                        return GestureDetector(
                          onTap: () => setState(() => _activeLineIndex = index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_showRomaji && line['romaji'] != null)
                                  Text(
                                    line['romaji']!,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.cyanAccent.withValues(alpha: 0.9)
                                          : Colors.white.withValues(alpha: 0.35),
                                      fontSize: 13,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  line['kanji']!,
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.35),
                                    fontSize: isActive ? 28 : 22,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                if (_showTranslation && line['translation'] != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    line['translation']!,
                                    style: TextStyle(
                                      color: isActive
                                          ? Colors.white.withValues(alpha: 0.7)
                                          : Colors.white.withValues(alpha: 0.25),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Progress Bar & Controls (Matching screenshot_2.jpg)
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
                      activeTrackColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                    child: Slider(
                      value: 135.0,
                      min: 0.0,
                      max: 198.0,
                      onChanged: (val) {},
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('2:15', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('-1:03', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 36),
                        onPressed: () {},
                      ),
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.pause_rounded, color: Colors.black, size: 36),
                      ),
                      IconButton(
                        icon: const Icon(Icons.fast_forward_rounded, color: Colors.white, size: 36),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bottom Volume Slider (Matching screenshot_2.jpg)
                  Row(
                    children: [
                      const Icon(Icons.volume_mute_rounded, color: Colors.white54, size: 20),
                      Expanded(
                        child: SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                            activeTrackColor: Colors.white,
                            inactiveTrackColor: Colors.white12,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: 40.0,
                            min: 0.0,
                            max: 100.0,
                            onChanged: (val) {},
                          ),
                        ),
                      ),
                      const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
