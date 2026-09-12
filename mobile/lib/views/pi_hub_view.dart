import 'package:flutter/material.dart';
import '../models/pi_state.dart';
import '../services/pi_aamps_service.dart';

class PiHubView extends StatefulWidget {
  final PiAampsService piService;

  const PiHubView({super.key, required this.piService});

  @override
  State<PiHubView> createState() => _PiHubViewState();
}

class _PiHubViewState extends State<PiHubView> {
  final TextEditingController _ipController = TextEditingController(text: '192.168.18.159');
  PiState _state = PiState();
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  void _refreshStatus() async {
    setState(() {
      _isChecking = true;
    });
    widget.piService.setIpAddress(_ipController.text.trim());
    final state = await widget.piService.fetchStatus();
    if (mounted) {
      setState(() {
        _state = state;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.radio_rounded, color: Colors.purpleAccent, size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'pi-aamps Remote Hub',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Manage Raspberry Pi hardware, equalizer & bluetooth',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Connection Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _state.isConnected ? Colors.greenAccent : Colors.redAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _state.isConnected ? Icons.wifi_tethering_rounded : Icons.wifi_off_rounded,
                          color: _state.isConnected ? Colors.greenAccent : Colors.redAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _state.isConnected ? 'Connected to Raspberry Pi' : 'Disconnected',
                          style: TextStyle(
                            color: _state.isConnected ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _ipController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Raspberry Pi IP Address',
                              labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.cyanAccent,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _isChecking ? null : _refreshStatus,
                          child: _isChecking
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Connect'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bluetooth Speaker Receiver Toggle
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.bluetooth_audio_rounded, color: Colors.blueAccent, size: 28),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bluetooth Receiver Mode',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Transform Pi into wireless A2DP speaker',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Switch(
                      value: _state.isBluetoothEnabled,
                      activeThumbColor: Colors.blueAccent,
                      onChanged: (val) async {
                        await widget.piService.toggleBluetoothReceiver(val);
                        _refreshStatus();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 10-Band Equalizer Presets
              Row(
                children: [
                  const Icon(Icons.graphic_eq_rounded, color: Colors.purpleAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    '10-Band Equalizer Presets',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Flat', 'Bass Boost', 'Vocal', 'Treble', 'Party', 'Rock', 'Jazz', 'Electronic', 'Acoustic']
                    .map((preset) => ChoiceChip(
                          label: Text(preset),
                          selected: _state.eqPreset.toLowerCase() == preset.toLowerCase(),
                          selectedColor: Colors.purpleAccent,
                          labelStyle: TextStyle(
                            color: _state.eqPreset.toLowerCase() == preset.toLowerCase() ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) async {
                            if (selected) {
                              await widget.piService.setEqPreset(preset);
                              _refreshStatus();
                            }
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Live System Hardware Telemetry
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    'Raspberry Pi Hardware Telemetry',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _telemetryTile('CPU Load', '${_state.cpuUsage.toStringAsFixed(1)}%', Icons.memory_rounded, Colors.amberAccent),
                  const SizedBox(width: 10),
                  _telemetryTile('RAM Usage', '${_state.ramUsage.toStringAsFixed(1)}%', Icons.pie_chart_rounded, Colors.cyanAccent),
                  const SizedBox(width: 10),
                  _telemetryTile('Temp', '${_state.tempCelsius.toStringAsFixed(1)}°C', Icons.thermostat_rounded, Colors.orangeAccent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _telemetryTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
