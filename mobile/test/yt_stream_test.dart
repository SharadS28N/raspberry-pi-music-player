import 'package:flutter_test/flutter_test.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

void main() {
  test('Test YouTube audio extraction for Yellow', () async {
    final yt = YoutubeExplode();
    print('Searching for Yellow...');
    final results = await yt.search.search('Yellow Coldplay');
    expect(results.isNotEmpty, true);
    final video = results.first;
    print('Found video: ${video.title} (ID: ${video.id.value})');

    try {
      final manifest = await yt.videos.streamsClient.getManifest(video.id.value);
      print('Audio streams: ${manifest.audioOnly.length}');
      for (var s in manifest.audioOnly) {
        print('Stream format: ${s.container.name}, bitrate: ${s.bitrate}, url length: ${s.url.toString().length}');
      }
      final best = manifest.audioOnly.withHighestBitrate();
      print('Selected best audio URL: ${best.url}');
    } catch (e, st) {
      print('Error getting manifest: $e');
      print('Stack: $st');
    } finally {
      yt.close();
    }
  });
}
