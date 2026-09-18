import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/track.dart';
import 'party_service.dart';
import 'pi_aamps_service.dart';
import 'youtube_service.dart';

class ConnectedDevice {
  final String id;
  final String name;
  final String type; // "phone", "speaker", "desktop", "car"
  final bool isCurrent;
  final bool isOnline;
  final String subtitle;

  ConnectedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isCurrent,
    required this.isOnline,
    required this.subtitle,
  });

  bool get isPhone => type == 'phone';
  bool get isPi => type == 'speaker' || type == 'pi';
  bool get isDesktop => type == 'desktop';
  bool get isActive => isCurrent || isOnline;
}

class AccountService extends ChangeNotifier {
  static final AccountService instance = AccountService();

  static final List<Account> _defaultAccounts = [
    Account(
      id: 'acc_1',
      name: 'Sharad Bhandari',
      email: 'sharad@aamps-audio.io',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      isPremium: true,
      playlistsCount: 16,
      likedSongsCount: 240,
      subscriptionsCount: 38,
      isCoupleProfile: false,
    ),
    Account(
      id: 'acc_couple_1',
      name: 'Couple Shared Account',
      email: 'couple.shared@open-aamps.io',
      avatarUrl: 'https://images.unsplash.com/photo-1516589178581-6cd7833ae3b2?w=150',
      isPremium: true,
      playlistsCount: 28,
      likedSongsCount: 520,
      subscriptionsCount: 64,
      isCoupleProfile: true,
      partnerName: 'Radha',
      partnerAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    ),
    Account(
      id: 'acc_ytm_1',
      name: 'YouTube Music Premium',
      email: 'ytm.member@youtube.com',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      isPremium: true,
      playlistsCount: 12,
      likedSongsCount: 384,
      subscriptionsCount: 52,
      isCoupleProfile: false,
    ),
  ];

  Account _activeAccount = _defaultAccounts.first;
  final List<Account> _availableAccounts = [];

  Account get activeAccount => _activeAccount;
  List<Account> get availableAccounts => List.unmodifiable(_availableAccounts);

  AccountService() {
    _initAccounts();
  }

  Future<void> _initAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('available_user_accounts');
      final activeId = prefs.getString('active_user_account_id');

      _availableAccounts.clear();
      if (savedList != null && savedList.isNotEmpty) {
        for (var str in savedList) {
          try {
            _availableAccounts.add(Account.fromJson(jsonDecode(str)));
          } catch (_) {}
        }
      }

      if (_availableAccounts.isEmpty) {
        _availableAccounts.addAll(_defaultAccounts);
        await _saveAccounts();
      }

      if (activeId != null) {
        final match = _availableAccounts.firstWhere(
          (a) => a.id == activeId,
          orElse: () => _availableAccounts.first,
        );
        _activeAccount = match;
      } else {
        _activeAccount = _availableAccounts.first;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading accounts: $e');
    }
  }

  Future<void> _saveAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listStr = _availableAccounts.map((a) => jsonEncode(a.toJson())).toList();
      await prefs.setStringList('available_user_accounts', listStr);
      await prefs.setString('active_user_account_id', _activeAccount.id);
    } catch (e) {
      debugPrint('Error saving accounts: $e');
    }
  }

  void switchAccount(Account account) {
    if (_activeAccount.id != account.id) {
      _activeAccount = account;
      _saveAccounts();
      notifyListeners();
    }
  }

  void addAccount(Account account) {
    _availableAccounts.removeWhere((a) => a.id == account.id);
    _availableAccounts.add(account);
    _activeAccount = account;
    _saveAccounts();
    notifyListeners();
  }

  void removeAccount(String accountId) {
    if (_availableAccounts.length > 1) {
      _availableAccounts.removeWhere((a) => a.id == accountId);
      if (_activeAccount.id == accountId) {
        _activeAccount = _availableAccounts.first;
      }
      _saveAccounts();
      notifyListeners();
    }
  }

  void updateActiveAccount({
    required String name,
    required String email,
    String? avatarUrl,
    bool? isCoupleProfile,
    String? partnerName,
    String? partnerAvatarUrl,
  }) {
    final updated = Account(
      id: _activeAccount.id,
      name: name,
      email: email,
      avatarUrl: avatarUrl ?? _activeAccount.avatarUrl,
      isPremium: _activeAccount.isPremium,
      playlistsCount: _activeAccount.playlistsCount,
      likedSongsCount: _activeAccount.likedSongsCount,
      subscriptionsCount: _activeAccount.subscriptionsCount,
      isCoupleProfile: isCoupleProfile ?? _activeAccount.isCoupleProfile,
      partnerName: partnerName ?? _activeAccount.partnerName,
      partnerAvatarUrl: partnerAvatarUrl ?? _activeAccount.partnerAvatarUrl,
    );
    final idx = _availableAccounts.indexWhere((a) => a.id == _activeAccount.id);
    if (idx != -1) {
      _availableAccounts[idx] = updated;
    }
    _activeAccount = updated;
    _saveAccounts();
    notifyListeners();
  }

  Future<Account?> connectRealYouTubeAccount(String handleOrQuery) async {
    final yt = YoutubeService();
    final channel = await yt.getChannelByHandle(handleOrQuery);
    if (channel != null) {
      final clean = handleOrQuery.trim();
      final handle = clean.startsWith('@') ? clean : '@$clean';
      final newAcc = Account(
        id: channel.id.value,
        name: channel.title,
        email: handle,
        avatarUrl: channel.logoUrl,
        isPremium: true,
        playlistsCount: 16,
        likedSongsCount: 240,
        subscriptionsCount: 38,
        isCoupleProfile: false,
      );
      addAccount(newAcc);
      return newAcc;
    }
    return null;
  }

  // --- Spotify Connect Style Device Presence ---
  List<ConnectedDevice> get connectedDevices {
    final pi = PiAampsService.instance;
    final isPiOnline = pi.currentState.isConnected;

    return [
      ConnectedDevice(
        id: 'device_phone_current',
        name: 'This Device (Galaxy A16)',
        type: 'phone',
        isCurrent: true,
        isOnline: true,
        subtitle: 'Local playback • Bluetooth Earbuds / AirPods',
      ),
      ConnectedDevice(
        id: 'device_pi_streamer',
        name: 'pi-aamps (Raspberry Pi 4)',
        type: 'speaker',
        isCurrent: false,
        isOnline: isPiOnline,
        subtitle: isPiOnline
            ? '${pi.ipAddress}:${pi.port} • Bit-perfect ALSA DAC Hub'
            : 'Offline at ${pi.ipAddress}:${pi.port}',
      ),
      if (_activeAccount.isCoupleProfile)
        ConnectedDevice(
          id: 'device_partner_phone',
          name: '${_activeAccount.partnerName}\'s Device (Couple Session)',
          type: 'phone',
          isCurrent: false,
          isOnline: true,
          subtitle: 'Listen Together • Synchronized dual AirPods playback',
        ),
      ConnectedDevice(
        id: 'device_desktop_web',
        name: 'Desktop Web Player',
        type: 'desktop',
        isCurrent: false,
        isOnline: isPiOnline,
        subtitle: 'Spotify-style web interface in browser',
      ),
    ];
  }

  // --- Launch Couple Mode / Listen Together ---
  Future<bool> startCoupleListenTogether({Track? track}) async {
    final party = PartyService.instance;
    if (!party.isInParty) {
      final success = await party.createParty(initialTrack: track);
      return success;
    }
    return true;
  }
}
