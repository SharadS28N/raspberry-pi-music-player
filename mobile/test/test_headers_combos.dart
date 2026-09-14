import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streams.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final s = manifest.audioOnly.first;

  // Test 1: No headers (just Range)
  final c1 = HttpClient();
  final r1 = await c1.getUrl(s.url);
  r1.headers.set('Range', 'bytes=0-1024');
  final res1 = await r1.close();
  print("1. No headers: status ${res1.statusCode}");
  c1.close();

  // Test 2: Chrome UA only (no Referer)
  final c2 = HttpClient();
  final r2 = await c2.getUrl(s.url);
  r2.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
  r2.headers.set('Range', 'bytes=0-1024');
  final res2 = await r2.close();
  print("2. Chrome UA only: status ${res2.statusCode}");
  c2.close();

  // Test 3: Chrome UA + Referer: https://www.youtube.com/
  final c3 = HttpClient();
  final r3 = await c3.getUrl(s.url);
  r3.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
  r3.headers.set('Referer', 'https://www.youtube.com/');
  r3.headers.set('Range', 'bytes=0-1024');
  final res3 = await r3.close();
  print("3. Chrome UA + Referer: status ${res3.statusCode}");
  c3.close();

  // Test 4: Android YouTube app UA: com.google.android.youtube/19.09.37 (Linux; U; Android 14)
  final c4 = HttpClient();
  final r4 = await c4.getUrl(s.url);
  r4.headers.set('User-Agent', 'com.google.android.youtube/19.09.37 (Linux; U; Android 14)');
  r4.headers.set('Range', 'bytes=0-1024');
  final res4 = await r4.close();
  print("4. Android YouTube UA: status ${res4.statusCode}");
  c4.close();

  yt.close();
}
