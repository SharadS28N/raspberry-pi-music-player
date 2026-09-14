import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  final invidiousInstances = [
    'https://inv.tux.pizza',
    'https://invidious.nerdvpn.de',
    'https://invidious.projectsegfau.lt',
    'https://yt.drgnz.club',
    'https://invidious.drgns.space',
  ];

  for (final inst in invidiousInstances) {
    try {
      print("Testing $inst for yKNxeF4KMsY...");
      final req = await client.getUrl(Uri.parse('$inst/api/v1/videos/yKNxeF4KMsY')).timeout(Duration(seconds: 4));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        final formatStreams = json['adaptiveFormats'] as List<dynamic>?;
        if (formatStreams != null) {
          final audioStreams = formatStreams.where((f) => (f['type'] as String? ?? '').startsWith('audio/')).toList();
          print("  -> Success! Found ${audioStreams.length} audio formats on $inst");
          for (final a in audioStreams.take(2)) {
            print("     URL: ${a['url']}");
          }
          break;
        }
      } else {
        print("  -> Status ${res.statusCode}");
      }
    } catch (e) {
      print("  -> Error: $e");
    }
  }
  client.close();
}
