import 'package:flutter_test/flutter_test.dart';
import 'package:open_aamps/services/youtube_service.dart';

void main() {
  test('Search tracks for Yellow and get audio stream URL', () async {
    final yt = YoutubeService();
    final tracks = await yt.searchTracks('Yellow Coldplay');
    print('Found ${tracks.length} tracks');
    expect(tracks.isNotEmpty, true);
    final firstTrack = tracks.first;
    print('First track: ${firstTrack.title} by ${firstTrack.artist} (id: ${firstTrack.id})');
    
    final streamUrl = await yt.getAudioStreamUrl(firstTrack.id, queryFallback: '${firstTrack.title} ${firstTrack.artist}');
    print('Stream URL: $streamUrl');
    expect(streamUrl != null && streamUrl.isNotEmpty, true);
    expect(streamUrl!.contains('googlevideo.com'), true);
    yt.dispose();
  });
}
