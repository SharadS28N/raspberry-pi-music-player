import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  
  final clients = {
    'androidVr': YoutubeApiClient.androidVr,
    'mweb': YoutubeApiClient.mweb,
    'tv': YoutubeApiClient.tv,
    'safari': YoutubeApiClient.safari,
    'webCreator': YoutubeApiClient.webCreator,
  };

  for (final entry in clients.entries) {
    try {
      print("\nTesting ${entry.key}...");
      final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [entry.value]);
      print("  Found ${manifest.audioOnly.length} audio streams");
      if (manifest.audioOnly.isNotEmpty) {
        final s = manifest.audioOnly.first;
        print("  Testing 1MB range request on ${s.container.name} stream (tag: ${s.tag})...");
        final c = HttpClient();
        final req = await c.getUrl(s.url);
        req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        req.headers.set('Range', 'bytes=0-1048576'); // 1MB
        final res = await req.close();
        print("  -> Status: ${res.statusCode}");
        c.close();

        // Also test unbounded range
        final c2 = HttpClient();
        final req2 = await c2.getUrl(s.url);
        req2.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        final res2 = await req2.close();
        print("  -> Unbounded Status: ${res2.statusCode}");
        c2.close();
      }
    } catch (e) {
      print("  Error: $e");
    }
  }
  yt.close();
}
