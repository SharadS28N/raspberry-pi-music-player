import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/pi_aamps_service.dart';
import '../services/party_service.dart';
import '../services/account_service.dart';
import '../views/party_view.dart';

class OutputTargetModal extends StatefulWidget {
  final AudioTarget currentTarget;
  final Function(AudioTarget) onSelectTarget;
  final PiAampsService? piService;

  const OutputTargetModal({
    super.key,
    required this.currentTarget,
    required this.onSelectTarget,
    this.piService,
  });

  @override
  State<OutputTargetModal> createState() => _OutputTargetModalState();
}

class _OutputTargetModalState extends State<OutputTargetModal> {
  late final PiAampsService _piService;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _piService = widget.piService ?? PiAampsService.instance;
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    if (!mounted) return;
    setState(() => _isChecking = true);
    await _piService.fetchFullStatus();
    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  void _showIpConfigDialog() {
    final ipController = TextEditingController(text: _piService.ipAddress);
    final portController = TextEditingController(text: _piService.port.toString());

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Configure Pi-Aamps IP:Port', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the local IP address and port of your Raspberry Pi running pi-aamps.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ipController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'IP Address',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '192.168.18.159',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: portController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Port',
                labelStyle: const TextStyle(color: Colors.white70),
                hintText: '8000',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF27272A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
            onPressed: () async {
              final newIp = ipController.text.trim();
              final newPort = int.tryParse(portController.text.trim()) ?? 8000;
              if (newIp.isNotEmpty) {
                await _piService.saveSettings(ip: newIp, port: newPort);
                if (mounted) setState(() {});
                await _checkConnection();
              }
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Save & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _piService.currentState.isConnected;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.speaker_group_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Choose Audio Output Target',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isChecking)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                  tooltip: 'Check Pi Connection',
                  onPressed: _checkConnection,
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                tooltip: 'Configure Pi-Aamps Network IP:Port',
                onPressed: _showIpConfigDialog,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select whether playback routes through your phone or your Raspberry Pi hardware streamer',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Option 1: Phone Speakers (Always available)
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: widget.currentTarget == AudioTarget.phoneLocal ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            leading: Icon(
              Icons.phone_android_rounded,
              color: widget.currentTarget == AudioTarget.phoneLocal ? Colors.white : Colors.white70,
              size: 28,
            ),
            title: const Text('This Phone (Local Audio)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Play directly on Android phone speakers or Bluetooth headphones', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: widget.currentTarget == AudioTarget.phoneLocal ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
            onTap: () {
              widget.onSelectTarget(AudioTarget.phoneLocal);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Raspberry Pi Speaker (Enabled when connected)
          Opacity(
            opacity: isConnected ? 1.0 : 0.65,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: widget.currentTarget == AudioTarget.piSpeaker ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
              leading: Icon(
                Icons.radio_rounded,
                color: widget.currentTarget == AudioTarget.piSpeaker
                    ? (isConnected ? const Color(0xFF22C55E) : Colors.white70)
                    : (isConnected ? Colors.white : Colors.white38),
                size: 28,
              ),
              title: Row(
                children: [
                  const Text('pi-aamps (Raspberry Pi)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isConnected ? const Color(0xFF22C55E) : Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isConnected ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      color: isConnected ? const Color(0xFF22C55E) : Colors.redAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                isConnected
                    ? '${_piService.ipAddress}:${_piService.port} • Direct bit-perfect DAC & speaker streaming'
                    : 'Unreachable at ${_piService.ipAddress}:${_piService.port} • Tap to configure IP or retry',
                style: TextStyle(
                  color: isConnected ? Colors.white54 : Colors.redAccent.withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
              trailing: isConnected && widget.currentTarget == AudioTarget.piSpeaker
                  ? const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E))
                  : (!isConnected
                      ? TextButton(
                          onPressed: _showIpConfigDialog,
                          child: const Text('Config', style: TextStyle(color: Colors.white70, fontSize: 11)),
                        )
                      : null),
              onTap: () {
                if (isConnected) {
                  widget.onSelectTarget(AudioTarget.piSpeaker);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'pi-aamps is offline at ${_piService.ipAddress}:${_piService.port}. Please check Wi-Fi or configure IP.',
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: const Color(0xFF1E1E24),
                      action: SnackBarAction(
                        label: 'Change IP',
                        textColor: Colors.white,
                        onPressed: _showIpConfigDialog,
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 10),

          // Option 3: Music Party / Group Listening (Jam Mode)
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: PartyService.instance.isInParty ? Colors.white.withValues(alpha: 0.12) : const Color(0xFF18181B),
            leading: Icon(
              Icons.speaker_group_rounded,
              color: PartyService.instance.isInParty ? const Color(0xFF10B981) : Colors.white,
              size: 28,
            ),
            title: Row(
              children: [
                const Text('Music Party / Jam Session', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (PartyService.instance.isInParty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      '${PartyService.instance.currentRoomCode} • ${PartyService.instance.members.length} listening',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              PartyService.instance.isInParty
                  ? 'Listening together • Drift sync active on local Bluetooth earbuds'
                  : 'Listen with friends • Multi-phone sync with individual Bluetooth headphones',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PartyView()),
              );
            },
          ),

          // Option 4: Couple Mode (If couple profile is active)
          if (AccountService.instance.activeAccount.isCoupleProfile) ...[
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              tileColor: const Color(0xFF1C1520),
              leading: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 28),
              title: Row(
                children: [
                  Text('Couple Mode: ${AccountService.instance.activeAccount.partnerName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: const Text('SHARED', style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              subtitle: const Text('Listen together synchronously on your own AirPods / earbuds', style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PartyView()),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
