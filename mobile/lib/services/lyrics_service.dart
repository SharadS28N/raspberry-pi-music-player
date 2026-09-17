import 'dart:convert';
import 'package:http/http.dart' as http;

class WordToken {
  final String word;
  final Duration offset;

  WordToken({
    required this.word,
    required this.offset,
  });
}

class SyncedLine {
  final Duration timestamp;
  final String text;
  final String? translation;
  final List<WordToken> words;

  SyncedLine({
    required this.timestamp,
    required this.text,
    this.translation,
    this.words = const [],
  });
}

class LyricsData {
  final String? trackName;
  final String? artistName;
  final List<SyncedLine> lines;
  final String? plainLyrics;
  final bool isSynced;
  final bool hasTranslations;

  LyricsData({
    this.trackName,
    this.artistName,
    required this.lines,
    this.plainLyrics,
    required this.isSynced,
    this.hasTranslations = false,
  });
}

class LyricsService {
  static final LyricsService instance = LyricsService();
  final http.Client _client = http.Client();

  final Map<String, LyricsData> _cache = {};

  String _cleanQuery(String text) {
    return text
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'ft\..*|feat\..*', caseSensitive: false), '')
        .replaceAll(RegExp(r'official.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'video.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'audio.*', caseSensitive: false), '')
        .replaceAll(RegExp(r'remaster(ed)?.*', caseSensitive: false), '')
        .trim();
  }

  List<SyncedLine> _parseLrc(String lrcContent) {
    final rawLines = lrcContent.split('\n');
    final parsedLines = <SyncedLine>[];
    final lineRegex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (int i = 0; i < rawLines.length; i++) {
      final raw = rawLines[i].trim();
      final match = lineRegex.firstMatch(raw);
      if (match != null) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final msStr = (match.group(3) ?? '0').padRight(3, '0').substring(0, 3);
        final millis = int.tryParse(msStr) ?? 0;

        final duration = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: millis,
        );

        var content = (match.group(4) ?? '').trim();
        if (content.isNotEmpty) {
          // Parse word-level tokens if enhanced LRC tags <00:00.00> exist
          final wordTokens = <WordToken>[];
          final wordRegex = RegExp(r'<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*)');
          final wordMatches = wordRegex.allMatches(content);

          if (wordMatches.isNotEmpty) {
            for (final wm in wordMatches) {
              final wMin = int.tryParse(wm.group(1) ?? '0') ?? 0;
              final wSec = int.tryParse(wm.group(2) ?? '0') ?? 0;
              final wMs = int.tryParse((wm.group(3) ?? '0').padRight(3, '0').substring(0, 3)) ?? 0;
              final wOffset = Duration(minutes: wMin, seconds: wSec, milliseconds: wMs);
              final wText = wm.group(4) ?? '';
              wordTokens.add(WordToken(word: wText, offset: wOffset));
            }
            content = content.replaceAll(RegExp(r'<\d{2}:\d{2}\.\d{2,3}>'), '').trim();
          } else {
            // Auto-generate interpolated word tokens across average speech tempo
            final wordsList = content.split(' ');
            final wordStepMs = wordsList.isNotEmpty ? (1800 ~/ wordsList.length) : 300;
            for (int w = 0; w < wordsList.length; w++) {
              wordTokens.add(WordToken(
                word: wordsList[w],
                offset: duration + Duration(milliseconds: w * wordStepMs),
              ));
            }
          }

          // Check if next line contains translation tag (e.g. translated LRC format)
          String? translation;
          if (i + 1 < rawLines.length) {
            final nextRaw = rawLines[i + 1].trim();
            if (nextRaw.startsWith('[tr]') || nextRaw.startsWith('//')) {
              translation = nextRaw.replaceFirst(RegExp(r'^(\[tr\]|\/\/)\s*'), '');
            }
          }

          parsedLines.add(SyncedLine(
            timestamp: duration,
            text: content,
            translation: translation,
            words: wordTokens,
          ));
        }
      }
    }

    parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return parsedLines;
  }

  Future<LyricsData?> getLyrics(String title, String artist) async {
    final cacheKey = '$title::$artist'.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final cleanTitle = _cleanQuery(title);
    final cleanArtist = _cleanQuery(artist);

    // 1. Query LRCLIB API
    try {
      final uri = Uri.parse(
        'https://lrclib.net/api/get?track_name=${Uri.encodeComponent(cleanTitle)}&artist_name=${Uri.encodeComponent(cleanArtist)}',
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final syncedStr = data['syncedLyrics'] as String?;
        final plainStr = data['plainLyrics'] as String?;

        if (syncedStr != null && syncedStr.isNotEmpty) {
          final parsed = _parseLrc(syncedStr);
          if (parsed.isNotEmpty) {
            final res = LyricsData(
              trackName: data['trackName'] as String?,
              artistName: data['artistName'] as String?,
              lines: parsed,
              plainLyrics: plainStr,
              isSynced: true,
              hasTranslations: parsed.any((l) => l.translation != null),
            );
            _cache[cacheKey] = res;
            return res;
          }
        }

        if (plainStr != null && plainStr.isNotEmpty) {
          final plainLines = plainStr
              .split('\n')
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList();
          final lines = <SyncedLine>[];
          for (int i = 0; i < plainLines.length; i++) {
            lines.add(SyncedLine(
              timestamp: Duration(seconds: i * 5),
              text: plainLines[i],
            ));
          }
          final res = LyricsData(
            trackName: data['trackName'] as String?,
            artistName: data['artistName'] as String?,
            lines: lines,
            plainLyrics: plainStr,
            isSynced: false,
          );
          _cache[cacheKey] = res;
          return res;
        }
      }
    } catch (_) {}

    // Fallback: Search endpoint
    try {
      final searchUri = Uri.parse(
        'https://lrclib.net/api/search?q=${Uri.encodeComponent('$cleanTitle $cleanArtist')}',
      );
      final response = await _client.get(searchUri).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          final syncedStr = first['syncedLyrics'] as String?;
          final plainStr = first['plainLyrics'] as String?;

          if (syncedStr != null && syncedStr.isNotEmpty) {
            final parsed = _parseLrc(syncedStr);
            if (parsed.isNotEmpty) {
              final res = LyricsData(
                trackName: first['trackName'] as String?,
                artistName: first['artistName'] as String?,
                lines: parsed,
                plainLyrics: plainStr,
                isSynced: true,
                hasTranslations: parsed.any((l) => l.translation != null),
              );
              _cache[cacheKey] = res;
              return res;
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
