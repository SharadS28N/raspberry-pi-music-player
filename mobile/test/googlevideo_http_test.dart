import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:open_aamps/services/youtube_service.dart';

void main() {
  test('Test googlevideo HTTP response with different headers', () async {
    final yt = YoutubeService();
    final url = await yt.getAudioStreamUrl('yKNxeF4KMsY'); // Coldplay - Yellow
    expect(url != null, true);
    print('Testing URL: $url\n');

    // Test 1: No custom headers (like default ExoPlayer)
    try {
      final res1 = await http.get(Uri.parse(url!), headers: {});
      print('Test 1 (Default): Status = ${res1.statusCode}, length = ${res1.bodyBytes.length}');
    } catch (e) {
      print('Test 1 error: $e');
    }

    // Test 2: ExoPlayer default User-Agent
    try {
      final res2 = await http.get(Uri.parse(url!), headers: {
        'User-Agent': 'AndroidXMedia3/1.4.1 (ExoPlayerLib)',
      });
      print('Test 2 (ExoPlayer UA): Status = ${res2.statusCode}');
    } catch (e) {
      print('Test 2 error: $e');
    }

    // Test 3: Range request with User-Agent and Referer
    try {
      final res3 = await http.get(Uri.parse(url!), headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Range': 'bytes=0-1024',
      });
      print('Test 3 (Browser UA + Range): Status = ${res3.statusCode}, bytes = ${res3.bodyBytes.length}');
    } catch (e) {
      print('Test 3 error: $e');
    }

    // Test 4: Android YouTube app User-Agent
    try {
      final res4 = await http.get(Uri.parse(url!), headers: {
        'User-Agent': 'com.google.android.youtube/19.09.37 (Linux; U; Android 11) gzip',
        'Range': 'bytes=0-1024',
      });
      print('Test 4 (YouTube App UA + Range): Status = ${res4.statusCode}, bytes = ${res4.bodyBytes.length}');
    } catch (e) {
      print('Test 4 error: $e');
    }

    yt.dispose();
  });
}
