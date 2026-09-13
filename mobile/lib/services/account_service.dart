import 'package:flutter/foundation.dart';
import '../models/account.dart';

class AccountService extends ChangeNotifier {
  static final AccountService instance = AccountService();

  Account _activeAccount = Account(
    id: 'acc_1',
    name: 'Sharad Bhandari',
    email: 'sharad@aamps-audio.io',
    avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    isPremium: true,
    playlistsCount: 16,
    likedSongsCount: 240,
    subscriptionsCount: 38,
  );

  final List<Account> _availableAccounts = [
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
      id: 'acc_2',
      name: 'aimyon Official',
      email: 'aimyon@vocaloid.jp',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      isPremium: true,
      playlistsCount: 8,
      likedSongsCount: 89,
      subscriptionsCount: 12,
    ),
    Account(
      id: 'acc_3',
      name: 'Hi-Fi Studio Account',
      email: 'studio@hifi-audio.net',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
      isPremium: true,
      playlistsCount: 32,
      likedSongsCount: 512,
      subscriptionsCount: 64,
    ),
  ];

  Account get activeAccount => _activeAccount;
  List<Account> get availableAccounts => List.unmodifiable(_availableAccounts);

  void switchAccount(Account account) {
    if (_activeAccount.id != account.id) {
      _activeAccount = account;
      notifyListeners();
    }
  }

  void addAccount(Account account) {
    if (!_availableAccounts.any((a) => a.id == account.id)) {
      _availableAccounts.add(account);
      _activeAccount = account;
      notifyListeners();
    }
  }

  void removeAccount(String accountId) {
    if (_availableAccounts.length > 1) {
      _availableAccounts.removeWhere((a) => a.id == accountId);
      if (_activeAccount.id == accountId) {
        _activeAccount = _availableAccounts.first;
      }
      notifyListeners();
    }
  }
}
