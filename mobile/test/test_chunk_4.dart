import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  final url = stream.url.toString();

  // Test chunk 4 directly
  final c = HttpClient();
  final req = await c.getUrl(Uri.parse(url));
  req.headers.set('Range', 'bytes=393216-524287');
  final res = await req.close();
  print("Direct request for chunk 4 (393216-524287): status ${res.statusCode}");
  c.close();
  yt.close();
}
