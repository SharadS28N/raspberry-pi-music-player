import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  print("Fetching Yellow (yKNxeF4KMsY)...");
  
  // Try different clients
  final clients = [
    [YoutubeApiClient.ios],
    [YoutubeApiClient.android],
    [YoutubeApiClient.androidMusic],
    [YoutubeApiClient.tv],
    [YoutubeApiClient.mweb],
  ];

  for (final c in clients) {
    try {
      print("Testing client: ${c.first.runtimeType}");
      final manifest = await yt.videos.streams.getManifest('yKNxeF4KMsY', ytClients: c);
      print("Got ${manifest.audioOnly.length} audio streams");
      for (final s in manifest.audioOnly.take(2)) {
        final url = s.url.toString();
        print("Container: ${s.container.name}, bitrate: ${s.bitrate}, url length: ${url.length}");
        
        // Test HTTP GET
        final client = HttpClient();
        final req = await client.getUrl(Uri.parse(url));
        req.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        req.headers.set('Referer', 'https://www.youtube.com/');
        req.headers.set('Range', 'bytes=0-1024');
        final res = await req.close();
        print("  -> Status code: ${res.statusCode}");
        client.close();
      }
    } catch (e) {
      print("  -> Client error: $e");
    }
  }
  yt.close();
}
