class PiAudioDevice {
  final String id;
  final String name;
  final bool active;
  final String type;

  PiAudioDevice({
    required this.id,
    required this.name,
    required this.active,
    this.type = 'analog',
  });

  factory PiAudioDevice.fromJson(Map<String, dynamic> json) {
    return PiAudioDevice(
      id: json['id'] ?? 'jack',
      name: json['name'] ?? 'Audio Output',
      active: json['active'] ?? false,
      type: json['type'] ?? 'analog',
    );
  }
}

class PiState {
  final bool isConnected;
  final String ipAddress;
  final int port;
  final int volume;
  final bool isMuted;
  final String eqPreset;
  final bool isBluetoothEnabled;
  final String bluetoothDeviceName;
  final String hostname;
  final String currentTrackTitle;
  final String currentArtist;
  final String currentArtworkUrl;
  final String currentTrackUrl;
  final double currentPosition;
  final double currentDuration;
  double get duration => currentDuration;
  final bool isPlaying;
  final double cpuUsage;
  final double ramUsage;
  final int ramUsedMb;
  final int ramTotalMb;
  final double tempCelsius;
  final double tempFahrenheit;
  final String coolingStatus;
  final String throttleStatus;
  final double storageUsedGb;
  final double storageTotalGb;
  final double storagePercent;
  final String uptime;
  final String activeDac;
  final List<PiAudioDevice> audioDevices;

  PiState({
    this.isConnected = false,
    this.ipAddress = '192.168.18.159',
    this.port = 8000,
    this.volume = 60,
    this.isMuted = false,
    this.eqPreset = 'normal',
    this.isBluetoothEnabled = true,
    this.bluetoothDeviceName = 'pi-aamps Audio Receiver',
    this.hostname = 'pi-aamps',
    this.currentTrackTitle = 'Nothing Playing',
    this.currentArtist = 'pi-aamps Hub',
    this.currentArtworkUrl = '',
    this.currentTrackUrl = '',
    this.currentPosition = 0.0,
    this.currentDuration = 0.0,
    this.isPlaying = false,
    this.cpuUsage = 0.0,
    this.ramUsage = 0.0,
    this.ramUsedMb = 0,
    this.ramTotalMb = 1024,
    this.tempCelsius = 0.0,
    this.tempFahrenheit = 0.0,
    this.coolingStatus = 'Optimal (Passive Cooling)',
    this.throttleStatus = 'Healthy (0x0)',
    this.storageUsedGb = 0.0,
    this.storageTotalGb = 0.0,
    this.storagePercent = 0.0,
    this.uptime = '0m',
    this.activeDac = '3.5mm Headphone Jack (Analog)',
    this.audioDevices = const [],
  });

  factory PiState.fromStatusAndMetrics({
    required Map<String, dynamic> status,
    Map<String, dynamic>? metrics,
    Map<String, dynamic>? btStatus,
    required String ip,
    int port = 8000,
  }) {
    final player = status['player'] as Map<String, dynamic>? ?? {};
    final song = status['current_song'] as Map<String, dynamic>? ?? {};
    final audioList = (status['audio'] as List<dynamic>?)
            ?.map((e) => PiAudioDevice.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    final activeDev = audioList.where((d) => d.active).firstOrNull;

    // Memory parsing
    final mem = metrics?['memory'] as Map<String, dynamic>?;
    final disk = metrics?['storage'] as Map<String, dynamic>?;

    return PiState(
      isConnected: true,
      ipAddress: ip,
      port: port,
      volume: (player['volume'] ?? status['master_volume'] ?? 60).toInt(),
      isMuted: (player['volume'] ?? 60) == 0,
      eqPreset: player['equalizer'] ?? 'normal',
      isBluetoothEnabled: btStatus?['powered'] ?? true,
      bluetoothDeviceName: metrics?['bluetooth_name'] ?? 'pi-aamps Audio Receiver',
      hostname: metrics?['hostname'] ?? 'pi-aamps',
      currentTrackTitle: song['title'] ?? 'Nothing Playing',
      currentArtist: song['artist'] ?? 'pi-aamps Hub',
      currentArtworkUrl: song['thumbnail'] ?? '',
      currentTrackUrl: song['url'] ?? '',
      currentPosition: (player['position'] ?? 0.0).toDouble(),
      currentDuration: (player['duration'] ?? song['duration'] ?? 0.0).toDouble(),
      isPlaying: !(player['paused'] ?? true),
      cpuUsage: (metrics?['cpu_usage_percent'] ?? 0.0).toDouble(),
      ramUsage: (mem?['percent'] ?? 0.0).toDouble(),
      ramUsedMb: (mem?['used_mb'] ?? 0).toInt(),
      ramTotalMb: (mem?['total_mb'] ?? 1024).toInt(),
      tempCelsius: (metrics?['temperature_celsius'] ?? 0.0).toDouble(),
      tempFahrenheit: (metrics?['temperature_fahrenheit'] ?? 0.0).toDouble(),
      coolingStatus: metrics?['cooling_status'] ?? 'Optimal (Passive Cooling)',
      throttleStatus: metrics?['throttling'] ?? 'Healthy (0x0)',
      storageUsedGb: (disk?['used_gb'] ?? 0.0).toDouble(),
      storageTotalGb: (disk?['total_gb'] ?? 0.0).toDouble(),
      storagePercent: (disk?['percent'] ?? 0.0).toDouble(),
      uptime: metrics?['uptime'] ?? '0m',
      activeDac: activeDev?.name ?? player['audio_device'] ?? '3.5mm Headphone Jack (Analog)',
      audioDevices: audioList,
    );
  }

  PiState copyWith({
    bool? isConnected,
    String? ipAddress,
    int? port,
    int? volume,
    bool? isMuted,
    String? eqPreset,
    bool? isBluetoothEnabled,
    String? bluetoothDeviceName,
    String? hostname,
    String? currentTrackTitle,
    String? currentArtist,
    String? currentArtworkUrl,
    String? currentTrackUrl,
    double? currentPosition,
    double? currentDuration,
    bool? isPlaying,
    double? cpuUsage,
    double? ramUsage,
    int? ramUsedMb,
    int? ramTotalMb,
    double? tempCelsius,
    double? tempFahrenheit,
    String? coolingStatus,
    String? throttleStatus,
    double? storageUsedGb,
    double? storageTotalGb,
    double? storagePercent,
    String? uptime,
    String? activeDac,
    List<PiAudioDevice>? audioDevices,
  }) {
    return PiState(
      isConnected: isConnected ?? this.isConnected,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      eqPreset: eqPreset ?? this.eqPreset,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      hostname: hostname ?? this.hostname,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentArtworkUrl: currentArtworkUrl ?? this.currentArtworkUrl,
      currentTrackUrl: currentTrackUrl ?? this.currentTrackUrl,
      currentPosition: currentPosition ?? this.currentPosition,
      currentDuration: currentDuration ?? this.currentDuration,
      isPlaying: isPlaying ?? this.isPlaying,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      ramUsedMb: ramUsedMb ?? this.ramUsedMb,
      ramTotalMb: ramTotalMb ?? this.ramTotalMb,
      tempCelsius: tempCelsius ?? this.tempCelsius,
      tempFahrenheit: tempFahrenheit ?? this.tempFahrenheit,
      coolingStatus: coolingStatus ?? this.coolingStatus,
      throttleStatus: throttleStatus ?? this.throttleStatus,
      storageUsedGb: storageUsedGb ?? this.storageUsedGb,
      storageTotalGb: storageTotalGb ?? this.storageTotalGb,
      storagePercent: storagePercent ?? this.storagePercent,
      uptime: uptime ?? this.uptime,
      activeDac: activeDac ?? this.activeDac,
      audioDevices: audioDevices ?? this.audioDevices,
    );
  }
}
