import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/pi_state.dart';
import '../models/track.dart';

class PiAampsService {
  String _ipAddress = '192.168.18.159';
  final int _port = 8000;
  WebSocketChannel? _wsChannel;
  final StreamController<PiState> _stateController = StreamController<PiState>.broadcast();
  PiState _currentState = PiState();

  String get ipAddress => _ipAddress;
  PiState get currentState => _currentState;
  Stream<PiState> get stateStream => _stateController.stream;

  void setIpAddress(String ip) {
    _ipAddress = ip;
    connectWebSocket();
  }

  String get baseUrl => 'http://$_ipAddress:$_port';
  String get wsUrl => 'ws://$_ipAddress:$_port/ws';

  Future<bool> checkConnection() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/health')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        _currentState = _currentState.copyWith(isConnected: true, ipAddress: _ipAddress);
        _stateController.add(_currentState);
        return true;
      }
    } catch (_) {}
    _currentState = _currentState.copyWith(isConnected: false);
    _stateController.add(_currentState);
    return false;
  }

  Future<PiState> fetchStatus() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/api/status')).timeout(const Duration(seconds: 3));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _currentState = PiState.fromJson(data, _ipAddress);
        _stateController.add(_currentState);
        return _currentState;
      }
    } catch (_) {}
    _currentState = _currentState.copyWith(isConnected: false);
    _stateController.add(_currentState);
    return _currentState;
  }

  void connectWebSocket() {
    _wsChannel?.sink.close();
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      _wsChannel!.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _currentState = PiState.fromJson(data, _ipAddress);
            _stateController.add(_currentState);
          } catch (_) {}
        },
        onError: (_) {
          _currentState = _currentState.copyWith(isConnected: false);
          _stateController.add(_currentState);
        },
        onDone: () {
          _currentState = _currentState.copyWith(isConnected: false);
          _stateController.add(_currentState);
        },
      );
    } catch (_) {
      _currentState = _currentState.copyWith(isConnected: false);
      _stateController.add(_currentState);
    }
  }

  Future<bool> playTrackOnPi(Track track) async {
    try {
      final ytUrl = track.id.startsWith('http')
          ? track.id
          : 'https://www.youtube.com/watch?v=${track.id}';
      final res = await http.post(Uri.parse('$baseUrl/api/play?url=${Uri.encodeComponent(ytUrl)}'));
      if (res.statusCode != 200) {
        final query = Uri.encodeComponent('${track.title} ${track.artist}');
        await http.post(Uri.parse('$baseUrl/api/play?query=$query'));
      }
      fetchStatus();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> togglePlayPause() async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/toggle_pause'));
      fetchStatus();
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setVolume(int level) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/volume?level=$level'));
      _currentState = _currentState.copyWith(volume: level);
      _stateController.add(_currentState);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setEqPreset(String preset) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/equalizer?preset=$preset'));
      _currentState = _currentState.copyWith(eqPreset: preset);
      _stateController.add(_currentState);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleBluetoothReceiver(bool enable) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/api/bluetooth/toggle?enable=$enable'));
      _currentState = _currentState.copyWith(isBluetoothEnabled: enable);
      _stateController.add(_currentState);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _wsChannel?.sink.close();
    _stateController.close();
  }
}
