import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';

class AccountSwitcherModal extends StatelessWidget {
  final AccountService accountService;

  const AccountSwitcherModal({
    super.key,
    required this.accountService,
  });

  @override
  Widget build(BuildContext context) {
    final active = accountService.activeAccount;
    final accounts = accountService.availableAccounts;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: Colors.cyanAccent, size: 26),
              const SizedBox(width: 10),
              const Text(
                'Switch Account Profile',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select your active YouTube Music / OpenAamps account',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: accounts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final acc = accounts[index];
              final isSelected = acc.id == active.id;
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: isSelected ? Colors.cyanAccent.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
                leading: CircleAvatar(
                  radius: 22,
                  backgroundImage: NetworkImage(acc.avatarUrl),
                ),
                title: Text(
                  acc.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                subtitle: Text(
                  '${acc.email} • ${acc.playlistsCount} Playlists',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle_rounded, color: Colors.cyanAccent, size: 24)
                    : null,
                onTap: () {
                  accountService.switchAccount(acc);
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Add New Account Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.cyanAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.cyanAccent),
              label: const Text(
                'Add Another YouTube Music Account',
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                accountService.addAccount(
                  Account(
                    id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                    name: 'Guest Artist Account',
                    email: 'guest@music.io',
                    avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
                    isPremium: true,
                    playlistsCount: 5,
                    likedSongsCount: 42,
                    subscriptionsCount: 9,
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
