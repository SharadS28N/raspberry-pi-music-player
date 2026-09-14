import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import 'app_alert.dart';

class AccountSwitcherModal extends StatefulWidget {
  final AccountService accountService;

  const AccountSwitcherModal({
    super.key,
    required this.accountService,
  });

  @override
  State<AccountSwitcherModal> createState() => _AccountSwitcherModalState();
}

class _AccountSwitcherModalState extends State<AccountSwitcherModal> {
  void _showAddAccountDialog(BuildContext parentContext) {
    final nameController = TextEditingController(text: 'YouTube Music User');
    final emailController = TextEditingController(text: '@ytmusic_user');
    String selectedAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';

    final avatarPresets = [
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    ];

    showDialog(
      context: parentContext,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF18181B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text('Add YouTube Music Account', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile Name', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sharad YTM',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('YouTube Handle or Email', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                const SizedBox(height: 6),
                TextField(
                  controller: emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. @sharad_music or user@gmail.com',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Select Profile Avatar', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: avatarPresets.map((url) {
                    final isSelected = selectedAvatar == url;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedAvatar = url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(url),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                if (name.isNotEmpty) {
                  final newAcc = Account(
                    id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    email: email.isNotEmpty ? email : '@user_ytm',
                    avatarUrl: selectedAvatar,
                    isPremium: true,
                    playlistsCount: 8,
                    likedSongsCount: 64,
                    subscriptionsCount: 14,
                  );
                  widget.accountService.addAccount(newAcc);
                  Navigator.pop(dialogCtx);
                  setState(() {});
                  AppAlert.show(
                    parentContext,
                    'Switched to "$name"',
                    icon: Icons.check_circle_rounded,
                    isSuccess: true,
                  );
                }
              },
              child: const Text('Connect & Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.accountService.activeAccount;
    final accounts = widget.accountService.availableAccounts;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141414),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Text(
                'YouTube Music Accounts',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Switch profile or link an additional YouTube Music account',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
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
                tileColor: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.white.withValues(alpha: 0.04),
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
                  style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected)
                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22)
                    else if (accounts.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                        tooltip: 'Remove',
                        onPressed: () {
                          widget.accountService.removeAccount(acc.id);
                          setState(() {});
                        },
                      ),
                  ],
                ),
                onTap: () {
                  widget.accountService.switchAccount(acc);
                  setState(() {});
                  Navigator.pop(context);
                },
              );
            },
          ),
          const SizedBox(height: 20),

          // Add New Account Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.white, width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add / Sign In YouTube Music Account',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              onPressed: () => _showAddAccountDialog(context),
            ),
          ),
        ],
      ),
    );
  }
}
