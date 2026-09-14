import 'dart:async';
import 'dart:io';

class LocalStreamProxy {
  HttpServer? _server;
  String? _targetUrl;
  int _totalBytes = 0;

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  void setStream(String url, int totalBytes) {
    _targetUrl = url;
    _totalBytes = totalBytes > 0 ? totalBytes : 5000000;
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
    int start = 0;
    int end = _totalBytes - 1;

    if (rangeHeader != null) {
      final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(rangeHeader);
      if (match != null) {
        start = int.tryParse(match.group(1) ?? '') ?? 0;
        final endParsed = int.tryParse(match.group(2) ?? '');
        if (endParsed != null && endParsed > 0) {
          end = endParsed;
        }
      }
    }

    if (end >= _totalBytes && _totalBytes > 0) {
      end = _totalBytes - 1;
    }
    if (start > end) {
      start = 0;
    }

    final contentLength = end - start + 1;

    if (rangeHeader != null) {
      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$_totalBytes');
    } else {
      request.response.statusCode = HttpStatus.ok;
    }
    final contentType = request.uri.path.endsWith('.webm') ? 'audio/webm' : 'audio/mp4';
    request.response.headers.set(HttpHeaders.contentTypeHeader, contentType);
    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    request.response.headers.set(HttpHeaders.contentLengthHeader, contentLength.toString());

    const chunkSize = 128 * 1024; // Safe 128KB chunks for YouTube GoogleVideo
    final client = HttpClient();

    try {
      int current = start;
      while (current <= end) {
        final chunkEnd = (current + chunkSize - 1) < end ? (current + chunkSize - 1) : end;
        final chunkReq = await client.getUrl(Uri.parse(_targetUrl!));
        chunkReq.headers.set('Range', 'bytes=$current-$chunkEnd');
        final chunkRes = await chunkReq.close();
        
        if (chunkRes.statusCode != 206 && chunkRes.statusCode != 200) {
          break;
        }

        await request.response.addStream(chunkRes);
        current = chunkEnd + 1;
      }
      await request.response.close();
    } catch (_) {
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
