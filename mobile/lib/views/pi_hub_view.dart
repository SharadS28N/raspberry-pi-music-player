import 'package:flutter/material.dart';
import '../models/pi_state.dart';
import '../services/pi_aamps_service.dart';

class PiHubView extends StatefulWidget {
  final PiAampsService? piService;

  const PiHubView({super.key, this.piService});

  @override
  State<PiHubView> createState() => _PiHubViewState();
}

class _PiHubViewState extends State<PiHubView> {
  late PiAampsService _service;
  bool _isScanningBt = false;
  List<Map<String, dynamic>> _scannedBtDevices = [];

  @override
  void initState() {
    super.initState();
    _service = widget.piService ?? PiAampsService.instance;
    _service.addListener(_onStateChange);
    _service.fetchFullStatus();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _service.removeListener(_onStateChange);
    super.dispose();
  }

  void _showIpConfigDialog() {
    final ipController = TextEditingController(text: _service.ipAddress);
    final portController = TextEditingController(text: _service.port.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        title: const Row(
          children: [
            Icon(Icons.router_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Connect to Raspberry Pi',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Pi IP Address',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: 'e.g. 192.168.18.159',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Port',
                labelStyle: const TextStyle(color: Colors.white60),
                hintText: '8000',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1E1E1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final ip = ipController.text.trim();
              final port = int.tryParse(portController.text.trim()) ?? 8000;
              if (ip.isNotEmpty) {
                _service.saveSettings(ip: ip, port: port);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBluetoothScanModal() async {
    setState(() => _isScanningBt = true);
    final devices = await _service.scanBluetoothDevices();
    if (mounted) {
      setState(() {
        _isScanningBt = false;
        _scannedBtDevices = devices;
      });
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: Colors.white12),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bluetooth Devices',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: _isScanningBt
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () async {
                      setModalState(() => _isScanningBt = true);
                      final devs = await _service.scanBluetoothDevices();
                      setModalState(() {
                        _isScanningBt = false;
                        _scannedBtDevices = devs;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_scannedBtDevices.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  alignment: Alignment.center,
                  child: Text(
                    _isScanningBt ? 'Scanning for nearby Bluetooth devices...' : 'No Bluetooth devices discovered nearby.',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _scannedBtDevices.length,
                    separatorBuilder: (_, _) => const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, idx) {
                      final dev = _scannedBtDevices[idx];
                      final name = dev['name'] ?? dev['mac'] ?? 'Unknown Device';
                      final mac = dev['mac'] ?? '';
                      final isConnected = dev['connected'] == true;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.bluetooth_rounded, color: Colors.white),
                        title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(mac, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isConnected ? Colors.red.shade900 : Colors.white,
                            foregroundColor: isConnected ? Colors.white : Colors.black,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            if (isConnected) {
                              await _service.disconnectBluetoothDevice(mac);
                            } else {
                              await _service.connectBluetoothDevice(mac);
                            }
                            final devs = await _service.scanBluetoothDevices();
                            setModalState(() => _scannedBtDevices = devs);
                          },
                          child: Text(isConnected ? 'Disconnect' : 'Connect', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.currentState;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: RefreshIndicator(
          color: Colors.white,
          backgroundColor: const Color(0xFF141414),
          onRefresh: () => _service.fetchFullStatus(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          child: const Icon(Icons.radio_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'pi-aamps',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              state.isConnected ? '${state.hostname} • ${state.ipAddress}:${state.port}' : 'Disconnected',
                              style: TextStyle(
                                color: state.isConnected ? const Color(0xFFA1A1AA) : Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _showIpConfigDialog,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: state.isConnected ? Colors.green.withValues(alpha: 0.5) : Colors.white24,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: state.isConnected ? Colors.greenAccent : Colors.redAccent,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              state.isConnected ? 'ONLINE' : 'CONNECT',
                              style: TextStyle(
                                color: state.isConnected ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Hardware Telemetry & Metrics Dashboard Card (Pure Spotify AMOLED style)
                _buildTelemetrySection(state),
                const SizedBox(height: 20),

                // Now Playing on Pi Hardware Remote Card
                _buildNowPlayingRemote(state),
                const SizedBox(height: 20),

                // Audio DAC Output Selector
                _buildDacSelector(state),
                const SizedBox(height: 20),

                // Bluetooth Receiver / Speaker Controller
                _buildBluetoothSection(state),
                const SizedBox(height: 20),

                // Hardware DSP Equalizer Presets
                _buildHardwareEqualizer(state),
                const SizedBox(height: 20),

                // Multi-Mode Sleep Timer on Pi
                _buildSleepTimerSection(state),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetrySection(PiState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'HARDWARE TELEMETRY',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'Uptime: ${state.uptime}',
                  style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 4 Grid metrics: CPU, RAM, Heat/Temp, Cooling
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.memory_rounded,
                  title: 'CPU Load',
                  value: '${state.cpuUsage.toStringAsFixed(1)}%',
                  subvalue: 'ARM Cortex-A',
                  progress: state.cpuUsage / 100.0,
                  color: state.cpuUsage > 80 ? Colors.redAccent : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.storage_rounded,
                  title: 'RAM Memory',
                  value: '${state.ramUsage.toStringAsFixed(0)}%',
                  subvalue: '${state.ramUsedMb}MB / ${state.ramTotalMb}MB',
                  progress: state.ramUsage / 100.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.thermostat_rounded,
                  title: 'SoC Heat',
                  value: '${state.tempCelsius.toStringAsFixed(1)}°C',
                  subvalue: '${state.tempFahrenheit.toStringAsFixed(1)}°F',
                  progress: (state.tempCelsius / 85.0).clamp(0.0, 1.0),
                  color: state.tempCelsius > 70 ? Colors.redAccent : (state.tempCelsius > 55 ? Colors.amberAccent : Colors.greenAccent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  icon: Icons.ac_unit_rounded,
                  title: 'Cooling State',
                  value: state.coolingStatus.contains('Optimal') ? 'Optimal' : 'Active',
                  subvalue: state.throttleStatus,
                  progress: 0.2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String title,
    required String value,
    required String subvalue,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(title, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(subvalue, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNowPlayingRemote(PiState state) {
    final hasSong = state.currentTrackTitle != 'Nothing Playing';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speaker_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'PI PLAYBACK REMOTE',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: state.isPlaying ? Colors.white : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.isPlaying ? 'PLAYING ON PI' : 'PAUSED',
                  style: TextStyle(
                    color: state.isPlaying ? Colors.black : Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: state.currentArtworkUrl.isNotEmpty
                    ? Image.network(
                        state.currentArtworkUrl,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 56,
                          height: 56,
                          color: const Color(0xFF1E1E1E),
                          child: const Icon(Icons.music_note_rounded, color: Colors.white60),
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        color: const Color(0xFF1E1E1E),
                        child: const Icon(Icons.music_note_rounded, color: Colors.white60),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.currentTrackTitle,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.currentArtist,
                      style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  state.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                  color: Colors.white,
                  size: 42,
                ),
                onPressed: () => _service.togglePlayPause(),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Scrubber slider
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: Colors.white,
              inactiveTrackColor: Color(0xFF27272A),
              thumbColor: Colors.white,
            ),
            child: Slider(
              value: state.currentPosition.clamp(0.0, state.currentDuration > 0 ? state.currentDuration : 1.0),
              max: state.currentDuration > 0 ? state.currentDuration : 1.0,
              onChanged: hasSong ? (val) => _service.seek(val) : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.currentPosition.toInt()),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  _formatDuration(state.currentDuration.toInt()),
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Volume Slider
          Row(
            children: [
              Icon(
                state.volume == 0 ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
                    activeTrackColor: Colors.white,
                    inactiveTrackColor: Color(0xFF27272A),
                    thumbColor: Colors.white,
                  ),
                  child: Slider(
                    value: state.volume.toDouble().clamp(0.0, 100.0),
                    min: 0.0,
                    max: 100.0,
                    onChanged: (val) => _service.setVolume(val.toInt()),
                  ),
                ),
              ),
              Text('${state.volume}%', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDacSelector(PiState state) {
    return Material(
      color: const Color(0xFF121212),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.cable_rounded, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'AUDIO DAC OUTPUT ROUTING',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.audioDevices.isEmpty)
              _buildDacItem(id: 'jack', name: '3.5mm Headphone Jack (Analog)', active: true)
            else
              ...state.audioDevices.map((dev) => _buildDacItem(id: dev.id, name: dev.name, active: dev.active)),
          ],
        ),
      ),
    );
  }

  Widget _buildDacItem({required String id, required String name, required bool active}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: active ? Colors.white : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          id.contains('hdmi') ? Icons.tv_rounded : Icons.headphones_rounded,
          color: active ? Colors.black : Colors.white70,
          size: 18,
        ),
      ),
      title: Text(
        name,
        style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.bold : FontWeight.normal),
      ),
      trailing: active
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('ACTIVE', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          : TextButton(
              onPressed: () => _service.setAudioOutput(id),
              child: const Text('Select', style: TextStyle(color: Colors.white60, fontSize: 12)),
            ),
      onTap: () => _service.setAudioOutput(id),
    );
  }

  Widget _buildBluetoothSection(PiState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bluetooth_audio_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'BLUETOOTH AUDIO ENGINE',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                ],
              ),
              Switch(
                value: state.isBluetoothEnabled,
                activeTrackColor: Colors.white38,
                activeThumbColor: Colors.white,
                onChanged: (val) => _service.toggleBluetoothPower(val),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            state.isBluetoothEnabled
                ? 'Broadcasting as "${state.bluetoothDeviceName}" • Connect phones or Bluetooth speakers directly to Raspberry Pi.'
                : 'Raspberry Pi Bluetooth adapter is disabled.',
            style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: state.isBluetoothEnabled ? _showBluetoothScanModal : null,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Scan Devices', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: state.isBluetoothEnabled
                      ? () => _service.setBluetoothMode('receiver')
                      : null,
                  icon: const Icon(Icons.speaker_phone_rounded, size: 16),
                  label: const Text('Receiver Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareEqualizer(PiState state) {
    final presets = ['normal', 'bass', 'rock', 'pop', 'vocal', 'acoustic', 'jazz', 'flat'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.equalizer_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'PI HARDWARE EQUALIZER PRESETS',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presets.map((preset) {
              final active = state.eqPreset.toLowerCase() == preset.toLowerCase();
              return InkWell(
                onTap: () => _service.setEqPreset(preset),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? Colors.white : Colors.white12),
                  ),
                  child: Text(
                    preset.toUpperCase(),
                    style: TextStyle(
                      color: active ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSleepTimerSection(PiState state) {
    final times = [15, 30, 45, 60, 0];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bedtime_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                'PI HARDWARE SLEEP TIMER',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: times.map((mins) {
              final label = mins == 0 ? 'OFF' : '$mins MIN';
              return InkWell(
                onTap: () => _service.setSleepTimer(mins),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds < 0) totalSeconds = 0;
    final mins = totalSeconds ~/ 60;
    final secs = totalSeconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
