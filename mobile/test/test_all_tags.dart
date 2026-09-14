import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);

  for (final s in manifest.audioOnly) {
    print("Testing tag ${s.tag} (${s.container.name}, ${s.bitrate})...");
    final c = HttpClient();
    final req = await c.getUrl(s.url);
    req.headers.set('Range', 'bytes=393216-524287');
    final res = await req.close();
    print("  -> Status at 393KB: ${res.statusCode}");
    c.close();

    // Also test at 1MB
    final c2 = HttpClient();
    final req2 = await c2.getUrl(s.url);
    req2.headers.set('Range', 'bytes=1048576-1179647');
    final res2 = await req2.close();
    print("  -> Status at 1MB: ${res2.statusCode}");
    c2.close();
  }
  yt.close();
}
