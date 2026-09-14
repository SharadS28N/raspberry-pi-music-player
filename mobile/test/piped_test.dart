import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  test('Test piped API for audio streams', () async {
    final videoId = 'yKNxeF4KMsY'; // Yellow
    final instances = [
      'https://pipedapi.kavin.rocks',
      'https://api.piped.privacydev.net',
      'https://piped-api.lunar.icu',
    ];
    for (var inst in instances) {
      try {
        final res = await http.get(Uri.parse('$inst/streams/$videoId')).timeout(const Duration(seconds: 4));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final audioStreams = data['audioStreams'] as List<dynamic>?;
          if (audioStreams != null && audioStreams.isNotEmpty) {
            print('Found audio streams on $inst: ${audioStreams.length}');
            final url = audioStreams.first['url'] as String;
            print('Sample URL: $url');
            return;
          }
        }
      } catch (e) {
        print('Error on $inst: $e');
      }
    }
  });
}
