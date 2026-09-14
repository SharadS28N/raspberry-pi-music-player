import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PlayerStyle { modern, classic, vinyl, minimal, glassmorphism }
enum BackgroundStyle { pureBlack, darkGradient, albumArtBlur, dynamicColor }
enum EqualizerPreset { flat, bassBoost, vocalBoost, trebleBoost, hifi }

class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService();

  PlayerStyle _playerStyle = PlayerStyle.modern;
  BackgroundStyle _backgroundStyle = BackgroundStyle.pureBlack;
  EqualizerPreset _equalizerPreset = EqualizerPreset.flat;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  double _crossfadeDuration = 3.0;
  bool _loudnessNormalization = true;

  PlayerStyle get playerStyle => _playerStyle;
  BackgroundStyle get backgroundStyle => _backgroundStyle;
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
      final pIndex = prefs.getInt('pref_player_style') ?? 0;
      if (pIndex >= 0 && pIndex < PlayerStyle.values.length) {
        _playerStyle = PlayerStyle.values[pIndex];
      }

      final bIndex = prefs.getInt('pref_bg_style') ?? 0;
      if (bIndex >= 0 && bIndex < BackgroundStyle.values.length) {
        _backgroundStyle = BackgroundStyle.values[bIndex];
      }

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
    _playerStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_player_style', style.index);
  }

  Future<void> setBackgroundStyle(BackgroundStyle style) async {
    _backgroundStyle = style;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_bg_style', style.index);
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
