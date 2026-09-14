import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:open_aamps/services/local_stream_proxy.dart';

void main() async {
  final yt = YoutubeExplode();
  print("Getting manifest for Yellow...");
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.container.name == 'mp4');
  print("Stream URL obtained.");

  final proxy = LocalStreamProxy();
  await proxy.start();
  proxy.setStream(stream.url.toString(), stream.size.totalBytes);
  final proxyUrl = proxy.getProxyUrl('audio.mp4');
  print("Proxy URL: $proxyUrl");

  // Test an HTTP client request to the proxy
  final client = HttpClient();
  final req = await client.getUrl(Uri.parse(proxyUrl));
  req.headers.set('Range', 'bytes=0-2048');
  final res = await req.close();
  print("Proxy response status: ${res.statusCode}");
  print("Proxy response Content-Type: ${res.headers.value('content-type')}");
  print("Proxy response Content-Range: ${res.headers.value('content-range')}");
  
  int bytesRead = 0;
  await for (final chunk in res) {
    bytesRead += chunk.length;
  }
  print("Successfully received $bytesRead bytes through LocalStreamProxy!");

  client.close();
  await proxy.stop();
  yt.close();
}
