import 'package:flutter/material.dart';
import '../services/account_service.dart';
import '../services/audio_player_service.dart';
import '../services/integration_service.dart';
import '../services/settings_service.dart';
import '../widgets/account_switcher_modal.dart';
import '../widgets/spotify_import_modal.dart';

class SettingsView extends StatefulWidget {
  final AudioPlayerService? audioService;

  const SettingsView({
    super.key,
    this.audioService,
  });

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final AccountService _account = AccountService.instance;
  final IntegrationService _integration = IntegrationService.instance;
  final SettingsService _settings = SettingsService.instance;
  late AudioPlayerService _audio;

  @override
  void initState() {
    super.initState();
    _audio = widget.audioService ?? AudioPlayerService();
    _settings.addListener(_onSettingsChange);
  }

  void _onSettingsChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsChange);
    super.dispose();
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
          'Settings & Preferences',
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
              '${_account.activeAccount.email} • YouTube Music Active',
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => AccountSwitcherModal(accountService: _account),
              ).then((_) => setState(() {}));
            },
          ),
          const SizedBox(height: 24),

          // Section 2: Player Theme & Aesthetics Customization
          const Text(
            'PLAYER THEME & CANVAS CUSTOMIZATION',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Player Style Dropdown & Picker
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.style_rounded, color: Colors.white),
            title: const Text('Player Style Theme', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _settings.playerStyle.name.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
            onTap: () => _showPlayerStylePicker(context),
          ),
          const SizedBox(height: 10),

          // Background Style Dropdown & Picker
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.wallpaper_rounded, color: Colors.white),
            title: const Text('Background Canvas Style', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _settings.backgroundStyle.name.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
            onTap: () => _showBackgroundStylePicker(context),
          ),
          const SizedBox(height: 28),

          // Section 3: Audio Engine & DSP Controls
          const Text(
            'AUDIO ENGINE & DSP CONTROLS',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Equalizer DSP Preset
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.graphic_eq_rounded, color: Colors.white),
            title: const Text('Equalizer DSP Preset', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _settings.equalizerPreset.name.toUpperCase(),
              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
            ),
            trailing: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 28),
            onTap: () => _showEqualizerPicker(context),
          ),
          const SizedBox(height: 10),

          // Playback Speed Slider
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.speed_rounded, color: Colors.white),
            title: Text('Playback Speed (${_settings.playbackSpeed.toStringAsFixed(2)}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _settings.playbackSpeed,
                min: 0.5,
                max: 2.0,
                divisions: 6,
                onChanged: (val) {
                  _settings.setPlaybackSpeed(val);
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
            title: Text('Pitch Shifter (${_settings.pitch.toStringAsFixed(2)}x)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _settings.pitch,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                onChanged: (val) {
                  _settings.setPitch(val);
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
            title: Text('Crossfade Duration (${_settings.crossfadeDuration.toInt()}s)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: SliderTheme(
              data: const SliderThemeData(
                trackHeight: 3,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Color(0xFF27272A),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: _settings.crossfadeDuration,
                min: 0.0,
                max: 12.0,
                divisions: 12,
                onChanged: (val) {
                  _settings.setCrossfade(val);
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
            subtitle: const Text('Balances dynamic volume ranges to target -14 LUFS', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
            value: _settings.loudnessNormalization,
            activeTrackColor: Colors.white38,
            activeThumbColor: Colors.white,
            onChanged: (val) {
              _settings.setLoudnessNormalization(val);
              _audio.setLoudnessNormalization(val);
            },
          ),
          const SizedBox(height: 28),

          // Section 4: Scrobblers & Integrations
          const Text(
            'CONNECT SPOTIFY & INTEGRATIONS',
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 12),

          // Spotify Account Connection Tile
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            tileColor: const Color(0xFF141414),
            leading: const Icon(Icons.library_music_rounded, color: Colors.white),
            title: const Text('Spotify Account Synchronization', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              _integration.spotifyConnected
                  ? 'Connected as @${_integration.spotifyUsername}'
                  : 'Tap to connect Spotify profile and sync playlists',
              style: TextStyle(
                color: _integration.spotifyConnected ? Colors.white : const Color(0xFFA1A1AA),
                fontSize: 12,
              ),
            ),
            trailing: Icon(
              _integration.spotifyConnected ? Icons.check_circle_rounded : Icons.arrow_forward_ios_rounded,
              color: Colors.white,
              size: _integration.spotifyConnected ? 22 : 16,
            ),
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => SpotifyImportModal(
                  integrationService: _integration,
                  onImportSuccess: (tracks) {
                    if (tracks.isNotEmpty) {
                      _audio.playTrack(tracks.first);
                    }
                  },
                ),
              ).then((_) => setState(() {}));
            },
          ),
          const SizedBox(height: 10),

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
        ],
      ),
    );
  }

  void _showPlayerStylePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Select Player Theme', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                ...PlayerStyle.values.map((style) {
                  final isSelected = _settings.playerStyle == style;
                  String desc = '';
                  switch (style) {
                    case PlayerStyle.modern:
                      desc = 'Full-width cinematic card with seamless shadow';
                      break;
                    case PlayerStyle.classic:
                      desc = 'Vintage framed border with retro high-contrast typography';
                      break;
                    case PlayerStyle.vinyl:
                      desc = 'Authentic spinning vinyl disc with grooves and center spindle';
                      break;
                    case PlayerStyle.minimal:
                      desc = 'Ultra-clean focus on typography and audio waveform';
                      break;
                    case PlayerStyle.glassmorphism:
                      desc = 'Frosted glass translucent backdrop with subtle glow';
                      break;
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF222222) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                    ),
                    child: ListTile(
                      title: Text(style.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(desc, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
                      onTap: () {
                        _settings.setPlayerStyle(style);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBackgroundStylePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Background Canvas Style', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                ...BackgroundStyle.values.map((bg) {
                  final isSelected = _settings.backgroundStyle == bg;
                  String desc = '';
                  switch (bg) {
                    case BackgroundStyle.pureBlack:
                      desc = 'True pure black AMOLED canvas with maximum battery savings';
                      break;
                    case BackgroundStyle.darkGradient:
                      desc = 'Deep monochrome dark zinc-to-black vertical gradient';
                      break;
                    case BackgroundStyle.albumArtBlur:
                      desc = 'Real-time cinematic blurred backdrop reflecting current artwork';
                      break;
                    case BackgroundStyle.dynamicColor:
                      desc = 'Adaptive monochrome luminescence reacting to track';
                      break;
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF222222) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                    ),
                    child: ListTile(
                      title: Text(bg.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(desc, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
                      onTap: () {
                        _settings.setBackgroundStyle(bg);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEqualizerPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Equalizer DSP Preset', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                const SizedBox(height: 12),
                ...EqualizerPreset.values.map((preset) {
                  final isSelected = _settings.equalizerPreset == preset;
                  String desc = '';
                  switch (preset) {
                    case EqualizerPreset.flat:
                      desc = 'Studio reference direct flat frequency response';
                      break;
                    case EqualizerPreset.bassBoost:
                      desc = 'Warm low-end harmonic enhancement for sub-bass';
                      break;
                    case EqualizerPreset.vocalBoost:
                      desc = 'Enhanced mid-range clarity for vocals and acoustic';
                      break;
                    case EqualizerPreset.trebleBoost:
                      desc = 'Airy high frequencies for cymbals and strings';
                      break;
                    case EqualizerPreset.hifi:
                      desc = 'Dynamic wide-spectrum audiophile soundstage tuning';
                      break;
                  }
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF222222) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? Colors.white : Colors.white12),
                    ),
                    child: ListTile(
                      title: Text(preset.name.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(desc, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                      trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Colors.white) : null,
                      onTap: () {
                        _settings.setEqualizerPreset(preset);
                        Navigator.pop(ctx);
                        setState(() {});
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
