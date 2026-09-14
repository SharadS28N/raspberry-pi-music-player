import 'dart:convert';
import 'dart:io';

void main() async {
  final client = HttpClient();
  client.userAgent = 'Mozilla/5.0';

  final req = await client.getUrl(Uri.parse('https://api.github.com/search/repositories?q=echo+music+player&sort=stars&order=desc'));
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body);
  for (final item in (json['items'] as List<dynamic>).take(5)) {
    print("- ${item['full_name']}: ${item['description']}");
  }
  client.close();
}
