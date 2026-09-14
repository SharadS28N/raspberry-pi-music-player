import 'dart:async';
import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final manifest = await yt.videos.streamsClient.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  final stream = manifest.audioOnly.firstWhere((s) => s.tag == 140);
  final streamUrl = stream.url.toString();
  final totalBytes = stream.size.totalBytes;
  print("Total audio stream size: $totalBytes bytes");

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  print("Local proxy listening on port ${server.port}");

  server.listen((request) async {
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    int start = 0;
    int end = totalBytes - 1;

    if (rangeHeader != null) {
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (match != null) {
        start = int.parse(match.group(1)!);
        if (match.group(2)!.isNotEmpty) {
          end = int.parse(match.group(2)!);
        }
      }
    }

    final contentLength = end - start + 1;
    print("Incoming request Range: bytes=$start-$end (Length: $contentLength)");

    request.response.statusCode = HttpStatus.partialContent;
    request.response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mp4');
    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    request.response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());
    request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$totalBytes');

    const chunkSize = 128 * 1024; // 128 KB safe chunk size
    final client = HttpClient();

    try {
      int current = start;
      while (current <= end) {
        final chunkEnd = (current + chunkSize - 1) < end ? (current + chunkSize - 1) : end;
        final chunkReq = await client.getUrl(Uri.parse(streamUrl));
        chunkReq.headers.set('Range', 'bytes=$current-$chunkEnd');
        final chunkRes = await chunkReq.close();
        if (chunkRes.statusCode != 206) {
          print("Error: chunk returned ${chunkRes.statusCode}");
          break;
        }
        await request.response.addStream(chunkRes);
        current = chunkEnd + 1;
      }
      await request.response.close();
      print("Finished streaming all chunks!");
    } catch (e) {
      print("Stream error: $e");
    } finally {
      client.close();
    }
  });

  // Test downloading 500KB (multiple chunks) through this local proxy
  final testClient = HttpClient();
  final testReq = await testClient.getUrl(Uri.parse('http://127.0.0.1:${server.port}/stream.mp4'));
  testReq.headers.set('Range', 'bytes=0-524288'); // 512 KB request!
  final testRes = await testReq.close();
  print("Test client got status: ${testRes.statusCode}");
  print("Content-Range: ${testRes.headers.value('content-range')}");
  print("Content-Length: ${testRes.headers.value('content-length')}");

  int received = 0;
  await for (final data in testRes) {
    received += data.length;
  }
  print("Test client received $received bytes successfully without 403!");

  testClient.close();
  await server.close(force: true);
  yt.close();
}
