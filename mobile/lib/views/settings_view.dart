import 'package:flutter/material.dart';
import '../services/audio_player_service.dart';
import '../services/account_service.dart';
import '../services/integration_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';

enum PlayerStyle { modern, glassmorphism, vinyl, classicCard }
enum BackgroundStyle { meshGradient, blurredArt, pitchBlack, solidVelvet }

class SettingsView extends StatefulWidget {
  final AudioPlayerService audioService;
  final AccountService accountService;
  final IntegrationService integrationService;
  final PlayerStyle currentStyle;
  final BackgroundStyle currentBgStyle;
  final Function(PlayerStyle) onStyleChanged;
  final Function(BackgroundStyle) onBgStyleChanged;

  const SettingsView({
    super.key,
    required this.audioService,
    required this.accountService,
    required this.integrationService,
    required this.currentStyle,
    required this.currentBgStyle,
    required this.onStyleChanged,
    required this.onBgStyleChanged,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late double _speed;
  late double _pitch;
  late double _crossfade;
  late bool _loudnessNorm;

  @override
  void initState() {
    super.initState();
    _speed = widget.audioService.playbackSpeed;
    _pitch = widget.audioService.pitch;
    _crossfade = widget.audioService.crossfadeDuration;
    _loudnessNorm = widget.audioService.loudnessNormalization;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings & Audio Preferences',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section 1: Active Account & Profile
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Colors.white.withValues(alpha: 0.05),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(widget.accountService.activeAccount.avatarUrl),
            ),
            title: Text(
              widget.accountService.activeAccount.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${widget.accountService.activeAccount.email} • Premium Account',
              style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.8), fontSize: 12),
            ),
            trailing: const Icon(Icons.swap_horiz_rounded, color: Colors.cyanAccent),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AccountSwitcherModal(accountService: widget.accountService),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Player Theme & Aesthetics Customization
          const Text(
            'Player Theme & Layout Customization',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),

          // Player Style Dropdown
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            leading: const Icon(Icons.style_rounded, color: Colors.purpleAccent),
            title: const Text('Player Style Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              widget.currentStyle.name.toUpperCase(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
            trailing: DropdownButton<PlayerStyle>(
              value: widget.currentStyle,
              dropdownColor: const Color(0xFF0F172A),
              underline: const SizedBox(),
              items: PlayerStyle.values.map((style) {
                return DropdownMenuItem(
                  value: style,
                  child: Text(
                    style.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (newStyle) {
                if (newStyle != null) widget.onStyleChanged(newStyle);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Background Style Dropdown
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            leading: const Icon(Icons.wallpaper_rounded, color: Colors.cyanAccent),
            title: const Text('Background Canvas Style', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              widget.currentBgStyle.name.toUpperCase(),
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
            ),
            trailing: DropdownButton<BackgroundStyle>(
              value: widget.currentBgStyle,
              dropdownColor: const Color(0xFF0F172A),
              underline: const SizedBox(),
              items: BackgroundStyle.values.map((bg) {
                return DropdownMenuItem(
                  value: bg,
                  child: Text(
                    bg.name.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (newBg) {
                if (newBg != null) widget.onBgStyleChanged(newBg);
              },
            ),
          ),
          const SizedBox(height: 28),

          // Section 3: Audio DSP Controls (Speed, Pitch, Crossfade, Equalizer, Loudness)
          const Text(
            'Audio Engine & DSP Controls',
            style: TextStyle(color: Colors.purpleAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),

          // Playback Speed Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            leading: const Icon(Icons.speed_rounded, color: Colors.amberAccent),
            title: Text('Playback Speed (${_speed.toStringAsFixed(2)}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.amberAccent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.amberAccent,
              ),
              child: Slider(
                value: _speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: (val) {
                  setState(() => _speed = val);
                  widget.audioService.setPlaybackSpeed(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Crossfade Duration Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            leading: const Icon(Icons.tune_rounded, color: Colors.cyanAccent),
            title: Text('Crossfade Duration (${_crossfade.toInt()}s)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.cyanAccent,
                inactiveTrackColor: Colors.white12,
                thumbColor: Colors.cyanAccent,
              ),
              child: Slider(
                value: _crossfade,
                min: 0.0,
                max: 12.0,
                divisions: 12,
                onChanged: (val) {
                  setState(() => _crossfade = val);
                  widget.audioService.setCrossfade(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Loudness Normalization Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            secondary: const Icon(Icons.equalizer_rounded, color: Colors.greenAccent),
            title: const Text('EBU R128 Loudness Normalization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Balances volume levels across heterogeneous audio streams', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: _loudnessNorm,
            activeColor: Colors.greenAccent,
            onChanged: (val) {
              setState(() => _loudnessNorm = val);
              widget.audioService.setLoudnessNormalization(val);
            },
          ),
          const SizedBox(height: 28),

          // Section 4: Scrobblers & External Integrations
          const Text(
            'Scrobblers & Third-Party Sync',
            style: TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 12),

          // Last.fm Scrobbler Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            secondary: const Icon(Icons.graphic_eq_rounded, color: Colors.redAccent),
            title: const Text('Last.fm Scrobbler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Connected as @${widget.integrationService.lastFmUsername}', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: widget.integrationService.lastFmEnabled,
            activeColor: Colors.redAccent,
            onChanged: (val) => widget.integrationService.toggleLastFm(val),
          ),
          const SizedBox(height: 10),

          // ListenBrainz Sync Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            secondary: const Icon(Icons.headphones_rounded, color: Colors.orangeAccent),
            title: const Text('ListenBrainz Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Submit listens automatically on 50% track completion', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: widget.integrationService.listenBrainzEnabled,
            activeColor: Colors.orangeAccent,
            onChanged: (val) => widget.integrationService.toggleListenBrainz(val),
          ),
          const SizedBox(height: 10),

          // Discord Rich Presence Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.white.withValues(alpha: 0.04),
            secondary: const Icon(Icons.discord_rounded, color: Colors.indigoAccent),
            title: const Text('Discord Rich Presence (RPC)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Display real-time playing status on Discord profile', style: TextStyle(color: Colors.white54, fontSize: 12)),
            value: widget.integrationService.discordRpcEnabled,
            activeColor: Colors.indigoAccent,
            onChanged: (val) => widget.integrationService.toggleDiscordRpc(val),
          ),
          const SizedBox(height: 20),

          // Spotify Playlist Import Action
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: Colors.greenAccent.withValues(alpha: 0.1),
            leading: const Icon(Icons.library_music_rounded, color: Colors.greenAccent),
            title: const Text('Import Playlist from Spotify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Convert public Spotify playlist link into OpenAamps queue', style: TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.greenAccent, size: 16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SpotifyImportModal(
                  integrationService: widget.integrationService,
                  onImportSuccess: (tracks) {},
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
