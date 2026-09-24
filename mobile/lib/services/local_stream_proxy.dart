import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/track.dart';
import 'download_service.dart';
import 'youtube_service.dart';

class LocalStreamProxy {
  static final LocalStreamProxy instance = LocalStreamProxy._internal();
  factory LocalStreamProxy() => instance;
  LocalStreamProxy._internal();

  HttpServer? _server;
  String? _targetUrl;
  final Map<String, String> _trackStreamUrls = {};
  Directory? _cacheDir;

  int get port => _server?.port ?? 0;

  Future<void> start() async {
    if (_server != null) return;
    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/offline_cache');
      if (!_cacheDir!.existsSync()) {
        _cacheDir!.createSync(recursive: true);
      }
    } catch (_) {}

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen(_handleRequest);
  }

  void setStream(String url) {
    _targetUrl = url;
  }

  void registerTrackStream(String trackId, String url) {
    _trackStreamUrls[trackId] = url;
  }

  String getProxyUrl(String filename) {
    return 'http://${InternetAddress.loopbackIPv4.address}:$port/$filename';
  }

  String getTrackStreamUrl(Track track) {
    return 'http://${InternetAddress.loopbackIPv4.address}:$port/track/${track.id}';
  }

  File? getLocalCacheFile(String trackId) {
    // 1. Check DownloadService
    final downloaded = DownloadService.instance.downloadedTracks.where((t) => t.id == trackId).firstOrNull;
    if (downloaded?.localPath != null && downloaded!.localPath!.isNotEmpty) {
      final f = File(downloaded.localPath!);
      if (f.existsSync() && f.lengthSync() > 10000) return f;
    }

    // 2. Check offline_cache directory
    if (_cacheDir != null) {
      final cachedFile = File('${_cacheDir!.path}/$trackId.m4a');
      if (cachedFile.existsSync() && cachedFile.lengthSync() > 10000) {
        return cachedFile;
      }
    }
    return null;
  }

  bool isTrackAvailableOffline(String trackId) {
    return getLocalCacheFile(trackId) != null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final path = request.uri.path;

    // Check if this is a track request: /track/<trackId>
    if (path.startsWith('/track/')) {
      final trackId = path.replaceFirst('/track/', '').split('?').first;
      await _handleTrackStream(request, trackId);
      return;
    }

    // Legacy targetUrl fallback
    if (_targetUrl == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    await _proxyRemoteUrl(request, _targetUrl!);
  }

  Future<void> _handleTrackStream(HttpRequest request, String trackId) async {
    // 1. Check if track is available as a local file (downloaded or cached)
    final localFile = getLocalCacheFile(trackId);
    if (localFile != null && localFile.existsSync()) {
      await _serveLocalFile(request, localFile);
      return;
    }

    // 2. If not local, resolve stream URL
    String? streamUrl = _trackStreamUrls[trackId];
    if (streamUrl == null || streamUrl.isEmpty) {
      try {
        final ytStream = await YoutubeService().getBestAudioStream(trackId);
        if (ytStream != null) {
          streamUrl = ytStream.url;
          _trackStreamUrls[trackId] = streamUrl;
        }
      } catch (e) {
        debugPrint('[LocalStreamProxy] Stream resolution error for $trackId: $e');
      }
    }

    if (streamUrl == null || streamUrl.isEmpty) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    await _proxyRemoteUrl(request, streamUrl, cacheTrackId: trackId);
  }

  Future<void> _serveLocalFile(HttpRequest request, File file) async {
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    final fileSize = file.lengthSync();
    request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
    request.response.headers.set(HttpHeaders.contentTypeHeader, 'audio/mp4');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final range = rangeHeader.replaceFirst('bytes=', '').trim();
      final parts = range.split('-');
      final start = int.tryParse(parts[0]) ?? 0;
      final end = (parts.length > 1 && parts[1].isNotEmpty)
          ? (int.tryParse(parts[1]) ?? (fileSize - 1))
          : (fileSize - 1);

      final safeEnd = end >= fileSize ? fileSize - 1 : end;
      final contentLength = safeEnd - start + 1;

      request.response.statusCode = HttpStatus.partialContent;
      request.response.headers.set(
        HttpHeaders.contentRangeHeader,
        'bytes $start-$safeEnd/$fileSize',
      );
      request.response.headers.set(
        HttpHeaders.contentLengthHeader,
        contentLength.toString(),
      );

      final raf = file.openSync();
      try {
        raf.setPositionSync(start);
        final bytes = raf.readSync(contentLength);
        request.response.add(bytes);
        await request.response.close();
      } catch (_) {
        try {
          await request.response.close();
        } catch (_) {}
      } finally {
        raf.closeSync();
      }
    } else {
      request.response.statusCode = HttpStatus.ok;
      request.response.headers.set(
        HttpHeaders.contentLengthHeader,
        fileSize.toString(),
      );
      await file.openRead().pipe(request.response);
    }
  }

  Future<void> _proxyRemoteUrl(HttpRequest request, String remoteUrl, {String? cacheTrackId}) async {
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);
    final client = HttpClient();

    try {
      final upstreamReq = await client.getUrl(Uri.parse(remoteUrl));
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

      // If caching is requested and this is a full stream from beginning (start == 0 or no range),
      // we can buffer/save to offline cache in background
      IOSink? cacheSink;
      if (cacheTrackId != null && _cacheDir != null && (rangeHeader == null || rangeHeader.startsWith('bytes=0-'))) {
        try {
          final tempFile = File('${_cacheDir!.path}/$cacheTrackId.m4a');
          cacheSink = tempFile.openWrite();
        } catch (_) {}
      }

      await for (var chunk in upstreamRes) {
        request.response.add(chunk);
        cacheSink?.add(chunk);
      }
      if (cacheSink != null) {
        await cacheSink.flush();
        await cacheSink.close();
      }
      await request.response.close();
    } catch (e) {
      debugPrint('[LocalStreamProxy] Stream proxy error: $e');
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
