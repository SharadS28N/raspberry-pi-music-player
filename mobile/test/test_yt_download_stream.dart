import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  print("Getting manifest for Yellow...");
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final audioStream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  print("Found audio stream: tag=${audioStream.tag}, bitrate=${audioStream.bitrate}, size=${audioStream.size.totalBytes} bytes");

  final sw = Stopwatch()..start();
  final file = File('test/yellow_sample.m4a');
  final sink = file.openWrite();

  int total = 0;
  await for (final chunk in yt.videos.streamsClient.get(audioStream)) {
    sink.add(chunk);
    total += chunk.length;
    if (total >= 128 * 1024 && sw.elapsedMilliseconds > 0) {
      print("Received first 128KB in ${sw.elapsedMilliseconds}ms! Continuing in background...");
      break;
    }
  }
  await sink.flush();
  await sink.close();
  print("Downloaded ${file.lengthSync()} bytes to ${file.path}");
  yt.close();
}
