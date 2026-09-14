import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';

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
    );
    final idx = _availableAccounts.indexWhere((a) => a.id == _activeAccount.id);
    if (idx != -1) {
      _availableAccounts[idx] = updated;
    }
    _activeAccount = updated;
    _saveAccounts();
    notifyListeners();
  }
}
