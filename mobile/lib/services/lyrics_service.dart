import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class SyncedLine {
  final Duration timestamp;
  final String text;

  SyncedLine({
    required this.timestamp,
    required this.text,
  });
}

class LyricsData {
  final String? trackName;
  final String? artistName;
  final List<SyncedLine> lines;
  final String? plainLyrics;
  final bool isSynced;

  LyricsData({
    this.trackName,
    this.artistName,
    required this.lines,
    this.plainLyrics,
    required this.isSynced,
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
    final lines = <SyncedLine>[];
    final regex = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final rawLine in lrcContent.split('\n')) {
      final match = regex.firstMatch(rawLine.trim());
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

        final text = (match.group(4) ?? '').trim();
        if (text.isNotEmpty) {
          lines.add(SyncedLine(timestamp: duration, text: text));
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return lines;
  }

  Future<LyricsData?> getLyrics(String title, String artist) async {
    final cacheKey = '$title::$artist'.toLowerCase();
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey];
    }

    final cleanTitle = _cleanQuery(title);
    final cleanArtist = _cleanQuery(artist);

    // 1. Direct get
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
              timestamp: Duration(seconds: i * 4),
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

    // 2. Search fallback
    try {
      final searchUri = Uri.parse(
        'https://lrclib.net/api/search?q=${Uri.encodeComponent('$cleanTitle $cleanArtist')}',
      );
      final searchResp = await _client.get(searchUri).timeout(const Duration(seconds: 4));
      if (searchResp.statusCode == 200) {
        final list = jsonDecode(searchResp.body) as List<dynamic>;
        for (var item in list) {
          final map = item as Map<String, dynamic>;
          final syncedStr = map['syncedLyrics'] as String?;
          final plainStr = map['plainLyrics'] as String?;

          if (syncedStr != null && syncedStr.isNotEmpty) {
            final parsed = _parseLrc(syncedStr);
            if (parsed.isNotEmpty) {
              final res = LyricsData(
                trackName: map['trackName'] as String?,
                artistName: map['artistName'] as String?,
                lines: parsed,
                plainLyrics: plainStr,
                isSynced: true,
              );
              _cache[cacheKey] = res;
              return res;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Lyrics search fallback error: $e');
    }

    return null;
  }
}
