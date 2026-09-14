import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0';

  final req = await client.getUrl(Uri.parse('https://api.github.com/repos/rukamori/ArchiveTune/contents'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body);
  if (json is List) {
    for (final item in json) {
      print("- ${item['name']} (${item['type']})");
    }
  } else {
    print(body);
  }
  client.close();
}
