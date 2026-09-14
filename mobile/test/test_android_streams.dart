import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  print("Fetching streams with YoutubeApiClient.android...");
  final manifest = await yt.videos.streams.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  print("Found ${manifest.audioOnly.length} audio-only streams");
  
  for (final s in manifest.audioOnly) {
    print("Stream tag: ${s.tag}, container: ${s.container.name}, bitrate: ${s.bitrate}");
    
    // Test with Android ExoPlayer default user agent (no headers at all)
    final client1 = HttpClient();
    final req1 = await client1.getUrl(s.url);
    req1.headers.set('Range', 'bytes=0-1024');
    final res1 = await req1.close();
    print("  -> Raw (no UA) status: ${res1.statusCode}");
    client1.close();

    // Test with Chrome user agent
    final client2 = HttpClient();
    final req2 = await client2.getUrl(s.url);
    req2.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
    req2.headers.set('Range', 'bytes=0-1024');
    final res2 = await req2.close();
    print("  -> With Chrome UA status: ${res2.statusCode}");
    client2.close();
  }
  yt.close();
}
