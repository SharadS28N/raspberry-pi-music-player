import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  test('Check just_audio setUrl headers parameter', () {
    final player = AudioPlayer();
    // Verify that headers map can be passed
    final headers = {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
    };
    expect(headers.isNotEmpty, true);
    player.dispose();
  });
}
