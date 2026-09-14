import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() async {
  final yt = YoutubeExplode();
  final m = await yt.videos.streams.getManifest('yKNxeF4KMsY', ytClients: [YoutubeApiClient.android]);
  File('test/url.txt').writeAsStringSync(m.audioOnly.first.url.toString());
  print("Saved URL to test/url.txt");
  yt.close();
}
