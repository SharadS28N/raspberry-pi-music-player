import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  final url = stream.url.toString();
  final totalBytes = stream.size.totalBytes;
  print("Total bytes of stream: $totalBytes");

  // Test with range: bytes=0-(totalBytes - 1)
  final c = HttpClient();
  final r = await c.getUrl(Uri.parse(url));
  r.headers.set('Range', 'bytes=0-${totalBytes - 1}');
  final res = await r.close();
  print("Status with bytes=0-${totalBytes - 1}: ${res.statusCode}");
  print("Content-Range: ${res.headers.value('content-range')}");
  print("Content-Length: ${res.headers.value('content-length')}");
  c.close();
  yt.close();
}
