class PiState {
  final bool isConnected;
  final String ipAddress;
  final int volume;
  final bool isMuted;
  final String eqPreset;
  final bool isBluetoothEnabled;
  final String bluetoothDeviceName;
  final String hostname;
  final String currentTrackTitle;
  final String currentArtist;
  final String currentArtworkUrl;
  final bool isPlaying;
  final double cpuUsage;
  final double ramUsage;
  final double tempCelsius;
  final String activeDac;

  PiState({
    this.isConnected = false,
    this.ipAddress = '192.168.18.159',
    this.volume = 80,
    this.isMuted = false,
    this.eqPreset = 'Flat',
    this.isBluetoothEnabled = false,
    this.bluetoothDeviceName = 'pi-aamps-audio',
    this.hostname = 'pi-aamps',
    this.currentTrackTitle = 'Nothing Playing',
    this.currentArtist = 'pi-aamps Hub',
    this.currentArtworkUrl = '',
    this.isPlaying = false,
    this.cpuUsage = 0.0,
    this.ramUsage = 0.0,
    this.tempCelsius = 0.0,
    this.activeDac = 'Analog 3.5mm',
  });

  factory PiState.fromJson(Map<String, dynamic> json, String ip) {
    return PiState(
      isConnected: true,
      ipAddress: ip,
      volume: (json['volume'] ?? 80).toInt(),
      isMuted: json['is_muted'] ?? false,
      eqPreset: json['eq_preset'] ?? 'Flat',
      isBluetoothEnabled: json['bluetooth_enabled'] ?? json['bluetooth_active'] ?? false,
      bluetoothDeviceName: json['bluetooth_name'] ?? 'pi-aamps-audio',
      hostname: json['hostname'] ?? 'pi-aamps',
      currentTrackTitle: json['title'] ?? json['current_track']?['title'] ?? 'Nothing Playing',
      currentArtist: json['artist'] ?? json['current_track']?['artist'] ?? 'pi-aamps Hub',
      currentArtworkUrl: json['artwork_url'] ?? json['current_track']?['artwork_url'] ?? '',
      isPlaying: json['is_playing'] ?? json['playing'] ?? false,
      cpuUsage: (json['cpu_percent'] ?? json['cpu'] ?? 0.0).toDouble(),
      ramUsage: (json['ram_percent'] ?? json['ram'] ?? 0.0).toDouble(),
      tempCelsius: (json['cpu_temp'] ?? json['temp'] ?? 0.0).toDouble(),
      activeDac: json['active_dac'] ?? json['dac'] ?? 'Analog 3.5mm',
    );
  }

  PiState copyWith({
    bool? isConnected,
    String? ipAddress,
    int? volume,
    bool? isMuted,
    String? eqPreset,
    bool? isBluetoothEnabled,
    String? bluetoothDeviceName,
    String? hostname,
    String? currentTrackTitle,
    String? currentArtist,
    String? currentArtworkUrl,
    bool? isPlaying,
    double? cpuUsage,
    double? ramUsage,
    double? tempCelsius,
    String? activeDac,
  }) {
    return PiState(
      isConnected: isConnected ?? this.isConnected,
      ipAddress: ipAddress ?? this.ipAddress,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      eqPreset: eqPreset ?? this.eqPreset,
      isBluetoothEnabled: isBluetoothEnabled ?? this.isBluetoothEnabled,
      bluetoothDeviceName: bluetoothDeviceName ?? this.bluetoothDeviceName,
      hostname: hostname ?? this.hostname,
      currentTrackTitle: currentTrackTitle ?? this.currentTrackTitle,
      currentArtist: currentArtist ?? this.currentArtist,
      currentArtworkUrl: currentArtworkUrl ?? this.currentArtworkUrl,
      isPlaying: isPlaying ?? this.isPlaying,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      tempCelsius: tempCelsius ?? this.tempCelsius,
      activeDac: activeDac ?? this.activeDac,
    );
  }
}
