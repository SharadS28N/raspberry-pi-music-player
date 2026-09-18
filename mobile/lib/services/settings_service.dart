import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayerStyle { modern, classic, vinyl, minimal, glassmorphism }
enum BackgroundStyle { pureBlack, darkGradient, albumArtBlur, dynamicColor, deepNebula, cyberNoir, velvetNight, customWallpaper }
enum EqualizerPreset { flat, bassBoost, vocalBoost, trebleBoost, hifi }

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService();

  static const List<Map<String, String>> defaultWallpapers = [
    {
      'id': 'deepNebula',
      'name': 'Deep Cosmic Nebula',
      'url': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=1080',
    },
    {
      'id': 'cyberNoir',
      'name': 'Cyber Noir Studio',
      'url': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1080',
    },
    {
      'id': 'velvetNight',
      'name': 'Velvet Aurora Midnight',
      'url': 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=1080',
    },
    {
      'id': 'minimalAcoustic',
      'name': 'Dark Vinyl Studio',
      'url': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=1080',
    },
    {
      'id': 'astralWaves',
      'name': 'Astral Soundwaves',
      'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=1080',
    },
  ];

  PlayerStyle _playerStyle = PlayerStyle.modern;
  BackgroundStyle _backgroundStyle = BackgroundStyle.pureBlack;
  String _customWallpaperUrl = '';
  EqualizerPreset _equalizerPreset = EqualizerPreset.flat;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  double _crossfadeDuration = 3.0;
  bool _loudnessNormalization = true;

  PlayerStyle get playerStyle => _playerStyle;
  BackgroundStyle get backgroundStyle => _backgroundStyle;
  String get customWallpaperUrl => _customWallpaperUrl;
  EqualizerPreset get equalizerPreset => _equalizerPreset;
  double get playbackSpeed => _playbackSpeed;
  double get pitch => _pitch;
  double get crossfadeDuration => _crossfadeDuration;
  bool get loudnessNormalization => _loudnessNormalization;

  SettingsService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _playerStyle = PlayerStyle.modern;

      final bIndex = prefs.getInt('pref_bg_style') ?? 0;
      if (bIndex >= 0 && bIndex < BackgroundStyle.values.length) {
        _backgroundStyle = BackgroundStyle.values[bIndex];
      }

      _customWallpaperUrl = prefs.getString('pref_custom_wallpaper') ?? '';

      final eIndex = prefs.getInt('pref_eq_preset') ?? 0;
      if (eIndex >= 0 && eIndex < EqualizerPreset.values.length) {
        _equalizerPreset = EqualizerPreset.values[eIndex];
      }

      _playbackSpeed = prefs.getDouble('pref_playback_speed') ?? 1.0;
      _pitch = prefs.getDouble('pref_pitch') ?? 1.0;
      _crossfadeDuration = prefs.getDouble('pref_crossfade') ?? 3.0;
      _loudnessNormalization = prefs.getBool('pref_loudness_norm') ?? true;

      notifyListeners();
    } catch (_) {}
  }

  Future<void> setPlayerStyle(PlayerStyle style) async {
    _playerStyle = PlayerStyle.modern;
    notifyListeners();
  }

  Future<void> setBackgroundStyle(BackgroundStyle style) async {
    _backgroundStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_bg_style', style.index);
  }

  Future<void> setCustomWallpaperUrl(String url) async {
    _customWallpaperUrl = url;
    _backgroundStyle = BackgroundStyle.customWallpaper;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_custom_wallpaper', url);
    await prefs.setInt('pref_bg_style', BackgroundStyle.customWallpaper.index);
  }

  Future<void> setEqualizerPreset(EqualizerPreset preset) async {
    _equalizerPreset = preset;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_eq_preset', preset.index);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pref_playback_speed', speed);
  }

  Future<void> setPitch(double pitchVal) async {
    _pitch = pitchVal;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pref_pitch', pitchVal);
  }

  Future<void> setCrossfade(double seconds) async {
    _crossfadeDuration = seconds;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pref_crossfade', seconds);
  }

  Future<void> setLoudnessNormalization(bool enabled) async {
    _loudnessNormalization = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_loudness_norm', enabled);
  }
}
