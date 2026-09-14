import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.tag == 140);
  final url = stream.url.toString();
  print("Testing sequential stream on itag 140 (total size: ${stream.size.totalBytes})...");

  const chunkSize = 128 * 1024;
  int current = 0;
  int successChunks = 0;

  final client = HttpClient();
  while (current < 1024 * 1024) {
    final end = current + chunkSize - 1;
    final req = await client.getUrl(Uri.parse(url));
    req.headers.set('Range', 'bytes=$current-$end');
    final res = await req.close();
    print("Chunk $current-$end: status ${res.statusCode}");
    if (res.statusCode != 206) {
      print("Failed at $current!");
      break;
    }
    // Read the chunk bytes
    await res.drain();
    successChunks++;
    current = end + 1;
  }
  client.close();
  print("Successfully read $successChunks chunks ($current bytes) sequentially!");
  yt.close();
}
