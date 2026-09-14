import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/audio_player_service.dart';
import '../services/integration_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';

enum PlayerStyle { modern, classic, vinyl, minimal, glassmorphism }
enum BackgroundStyle { pureBlack, darkGradient, albumArtBlur, dynamicColor }

class SettingsView extends StatefulWidget {
  final AudioPlayerService? audioService;
  final PlayerStyle currentStyle;
  final BackgroundStyle currentBgStyle;
  final Function(PlayerStyle)? onStyleChanged;
  final Function(BackgroundStyle)? onBgStyleChanged;

  const SettingsView({
    super.key,
    this.audioService,
    this.currentStyle = PlayerStyle.modern,
    this.currentBgStyle = BackgroundStyle.pureBlack,
    this.onStyleChanged,
    this.onBgStyleChanged,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final AccountService _account = AccountService.instance;
  final IntegrationService _integration = IntegrationService.instance;
  late AudioPlayerService _audio;

  double _speed = 1.0;
  double _pitch = 1.0;
  double _crossfade = 3.0;
  bool _loudnessNorm = true;

  @override
  void initState() {
    super.initState();
    _audio = widget.audioService ?? AudioPlayerService();
    _speed = widget.audioService?.playbackSpeed ?? 1.0;
    _pitch = widget.audioService?.pitch ?? 1.0;
    _crossfade = widget.audioService?.crossfadeDuration ?? 3.0;
    _loudnessNorm = widget.audioService?.loudnessNormalization ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
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
            tileColor: const Color(0xFF141414),
            leading: CircleAvatar(
              radius: 22,
              backgroundImage: NetworkImage(_account.activeAccount.avatarUrl),
            ),
            title: Text(
              _account.activeAccount.name,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_account.activeAccount.email} • Premium Account',
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AccountSwitcherModal(accountService: _account),
              );
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Player Theme & Aesthetics Customization
          const Text(
            'PLAYER THEME & CUSTOMIZATION',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Player Style Dropdown
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.style_rounded, color: Colors.white),
            title: const Text('Player Style Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              widget.currentStyle.name.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: DropdownButton<PlayerStyle>(
              value: widget.currentStyle,
              dropdownColor: const Color(0xFF18181B),
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
                if (newStyle != null) widget.onStyleChanged?.call(newStyle);
              },
            ),
          ),
          const SizedBox(height: 10),

          // Background Style Dropdown
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.wallpaper_rounded, color: Colors.white),
            title: const Text('Background Canvas Style', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              widget.currentBgStyle.name.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: DropdownButton<BackgroundStyle>(
              value: widget.currentBgStyle,
              dropdownColor: const Color(0xFF18181B),
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
                if (newBg != null) widget.onBgStyleChanged?.call(newBg);
              },
            ),
          ),
          const SizedBox(height: 28),

          // Section 3: Audio DSP Controls (Speed, Pitch, Crossfade, Equalizer, Loudness)
          const Text(
            'AUDIO ENGINE & DSP CONTROLS',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Playback Speed Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.speed_rounded, color: Colors.white),
            title: Text('Playback Speed (${_speed.toStringAsFixed(2)}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _speed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: (val) {
                  setState(() => _speed = val);
                  _audio.setPlaybackSpeed(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Pitch Shifter Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.music_note_rounded, color: Colors.white),
            title: Text('Pitch Shifter (${_pitch.toStringAsFixed(2)}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _pitch,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                onChanged: (val) {
                  setState(() => _pitch = val);
                  _audio.setPitch(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Crossfade Duration Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.tune_rounded, color: Colors.white),
            title: Text('Crossfade Duration (${_crossfade.toInt()}s)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _crossfade,
                min: 0.0,
                max: 12.0,
                divisions: 12,
                onChanged: (val) {
                  setState(() => _crossfade = val);
                  _audio.setCrossfade(val);
                },
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Loudness Normalization Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            secondary: const Icon(Icons.equalizer_rounded, color: Colors.white),
            title: const Text('EBU R128 Loudness Normalization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Balances volume levels across heterogeneous audio streams', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            value: _loudnessNorm,
            activeTrackColor: Colors.white38,
            activeThumbColor: Colors.white,
            onChanged: (val) {
              setState(() => _loudnessNorm = val);
              _audio.setLoudnessNormalization(val);
            },
          ),
          const SizedBox(height: 28),

          // Section 4: Scrobblers & External Integrations
          const Text(
            'SCROBBLERS & INTEGRATIONS',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Last.fm Scrobbler Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            secondary: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
            title: const Text('Last.fm Scrobbler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('Connected as @${_integration.lastFmUsername}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            value: _integration.lastFmEnabled,
            activeTrackColor: Colors.white38,
            activeThumbColor: Colors.white,
            onChanged: (val) => _integration.toggleLastFm(val),
          ),
          const SizedBox(height: 10),

          // ListenBrainz Sync Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            secondary: const Icon(Icons.headphones_rounded, color: Colors.white),
            title: const Text('ListenBrainz Sync', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Submit listens automatically on 50% track completion', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            value: _integration.listenBrainzEnabled,
            activeTrackColor: Colors.white38,
            activeThumbColor: Colors.white,
            onChanged: (val) => _integration.toggleListenBrainz(val),
          ),
          const SizedBox(height: 10),

          // Discord Rich Presence Toggle
          SwitchListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            secondary: const Icon(Icons.discord_rounded, color: Colors.white),
            title: const Text('Discord Rich Presence (RPC)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Display real-time playing status on Discord profile', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            value: _integration.discordRpcEnabled,
            activeTrackColor: Colors.white38,
            activeThumbColor: Colors.white,
            onChanged: (val) => _integration.toggleDiscordRpc(val),
          ),
          const SizedBox(height: 20),

          // Spotify Playlist Import Action
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.library_music_rounded, color: Colors.white),
            title: const Text('Import Playlist from Spotify', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text('Convert public Spotify playlist link into queue', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SpotifyImportModal(
                  integrationService: _integration,
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
