import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';

class OutputTargetModal extends StatelessWidget {
  final AudioTarget currentTarget;
  final Function(AudioTarget) onSelectTarget;

  const OutputTargetModal({
    super.key,
    required this.currentTarget,
    required this.onSelectTarget,
  });

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.volume_up_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              const Text(
                'Choose Audio Output Target',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select where music playback should be directed',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),

          // Option 1: Phone Speakers
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: currentTarget == AudioTarget.phoneLocal ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            leading: Icon(
              Icons.phone_android_rounded,
              color: currentTarget == AudioTarget.phoneLocal ? Colors.white : Colors.white70,
              size: 28,
            ),
            title: const Text('This Phone (Local Audio)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Play directly on Android phone speakers or Bluetooth headphones', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: currentTarget == AudioTarget.phoneLocal ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
            onTap: () {
              onSelectTarget(AudioTarget.phoneLocal);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Raspberry Pi Speaker
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: currentTarget == AudioTarget.piSpeaker ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
            leading: Icon(
              Icons.radio_rounded,
              color: currentTarget == AudioTarget.piSpeaker ? Colors.white : Colors.white70,
              size: 28,
            ),
            title: const Text('pi-aamps (Hardware Streamer)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Stream audio to external DAC & Hi-Fi Speakers (Coming Soon)', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: currentTarget == AudioTarget.piSpeaker ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
            onTap: () {
              onSelectTarget(AudioTarget.piSpeaker);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
