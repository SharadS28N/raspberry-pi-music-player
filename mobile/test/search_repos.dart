import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0';

  final repos = [
    'opentune',
    'archivetune',
    'vimusic',
    'innertune',
  ];

  for (final q in repos) {
    try {
      final req = await client.getUrl(Uri.parse('https://api.github.com/search/repositories?q=$q&sort=stars&order=desc'));
      final res = await req.close();
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final json = jsonDecode(body);
        final items = json['items'] as List<dynamic>?;
        print("\nQuery: $q -> Found ${items?.length} repos");
        for (final item in (items ?? []).take(2)) {
          print("  - ${item['full_name']}: ${item['description']}");
        }
      } else {
        print("Query $q failed with status ${res.statusCode}");
      }
    } catch (e) {
      print("Query $q error: $e");
    }
  }
  client.close();
}
