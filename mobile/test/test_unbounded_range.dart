import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  final url = stream.url.toString();

  // Test 1: Bounded range: bytes=0-1024
  final c1 = HttpClient();
  final r1 = await c1.getUrl(Uri.parse(url));
  r1.headers.set('Range', 'bytes=0-1024');
  final res1 = await r1.close();
  print("1. Bounded range (0-1024): ${res1.statusCode}");
  c1.close();

  // Test 2: Bounded full range: bytes=0-${stream.size.totalBytes - 1}
  final c2 = HttpClient();
  final r2 = await c2.getUrl(Uri.parse(url));
  r2.headers.set('Range', 'bytes=0-${stream.size.totalBytes - 1}');
  r2.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
  final res2 = await r2.close();
  print("2. Bounded full range (bytes=0-${stream.size.totalBytes - 1}): ${res2.statusCode}");
  c2.close();

  // Test 3: No Range header
  final c3 = HttpClient();
  final r3 = await c3.getUrl(Uri.parse(url));
  final res3 = await r3.close();
  print("3. No range header: ${res3.statusCode}");
  c3.close();

  yt.close();
}
