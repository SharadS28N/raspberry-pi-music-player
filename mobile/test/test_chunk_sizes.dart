import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  final url = stream.url.toString();

  final sizes = [
    1024,
    10 * 1024,
    50 * 1024,
    100 * 1024,
    256 * 1024,
    512 * 1024,
    1024 * 1024,
    1661408,
  ];

  for (final sz in sizes) {
    final c = HttpClient();
    final r = await c.getUrl(Uri.parse(url));
    r.headers.set('Range', 'bytes=0-$sz');
    final res = await r.close();
    print("Range 0-$sz: status ${res.statusCode}");
    c.close();
  }
  yt.close();
}
