import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0';

  final req = await client.getUrl(Uri.parse('https://api.github.com/search/code?q=playback+repo:z-huang/InnerTune+path:app'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  print(body.substring(0, body.length > 500 ? 500 : body.length));
  client.close();
}
