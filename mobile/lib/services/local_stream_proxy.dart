import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

class LocalStreamProxy {
  HttpServer? _server;
  String? _targetUrl;

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  void setStream(String url) {
    _targetUrl = url;
  }

  String getProxyUrl(String filename) {
    return 'http://${InternetAddress.loopbackIPv4.address}:$port/$filename';
  }

  Future<void> _handleRequest(HttpRequest request) async {
    if (_targetUrl == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    final client = HttpClient();

    try {
      final upstreamReq = await client.getUrl(Uri.parse(_targetUrl!));
      upstreamReq.headers.set(
        HttpHeaders.userAgentHeader,
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      );
      upstreamReq.headers.set('Referer', 'https://www.youtube.com/');
      if (rangeHeader != null) {
        upstreamReq.headers.set(HttpHeaders.rangeHeader, rangeHeader);
      }
      final upstreamRes = await upstreamReq.close();

      request.response.statusCode = upstreamRes.statusCode;
      upstreamRes.headers.forEach((name, values) {
        final lower = name.toLowerCase();
        if (lower != 'transfer-encoding' && lower != 'connection') {
          for (var val in values) {
            request.response.headers.add(name, val);
          }
        }
      });
      request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

      await request.response.addStream(upstreamRes);
      await request.response.close();
    } catch (e) {
      debugPrint('LocalStreamProxy stream proxy error: $e');
      try {
        await request.response.close();
      } catch (_) {}
    } finally {
      client.close();
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}
