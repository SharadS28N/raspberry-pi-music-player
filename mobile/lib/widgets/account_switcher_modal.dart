import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/account_service.dart';
import '../views/party_view.dart';
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
    final handleController = TextEditingController(text: '@Coldplay');
    final nameController = TextEditingController();
    String selectedAvatar = 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150';
    bool isSyncing = false;
    String? statusMessage;

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
              Text('Link YouTube / Google Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter YouTube Handle or Channel Name',
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: handleController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. @Coldplay or @yourchannel',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                if (statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    statusMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
                const SizedBox(height: 14),
                const Text(
                  'Or Custom Display Name (Optional)',
                  style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. Sharad Personal',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Profile Avatar Preset (Fallback)', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
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
                          radius: 18,
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
              onPressed: isSyncing ? null : () => Navigator.pop(dialogCtx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: isSyncing
                  ? null
                  : () async {
                      final handleInput = handleController.text.trim();
                      final customName = nameController.text.trim();
                      if (handleInput.isEmpty && customName.isEmpty) return;

                      setDialogState(() {
                        isSyncing = true;
                        statusMessage = 'Connecting with YouTube...';
                      });

                      Account? realAccount;
                      if (handleInput.isNotEmpty) {
                        try {
                          realAccount = await widget.accountService.connectRealYouTubeAccount(handleInput);
                        } catch (e) {
                          debugPrint('Error syncing YouTube account: $e');
                        }
                      }

                      if (realAccount != null) {
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) setState(() {});
                        if (parentContext.mounted) {
                          AppAlert.show(
                            parentContext,
                            'Connected YouTube Account: ${realAccount.name}',
                            icon: Icons.check_circle_rounded,
                            isSuccess: true,
                          );
                        }
                      } else {
                        // Fallback to manual account creation
                        final displayName = customName.isNotEmpty
                            ? customName
                            : (handleInput.isNotEmpty ? handleInput : 'YouTube User');
                        final newAcc = Account(
                          id: 'acc_${DateTime.now().millisecondsSinceEpoch}',
                          name: displayName,
                          email: handleInput.isNotEmpty ? handleInput : '@user',
                          avatarUrl: selectedAvatar,
                          isPremium: true,
                          playlistsCount: 8,
                          likedSongsCount: 42,
                          subscriptionsCount: 12,
                        );
                        widget.accountService.addAccount(newAcc);
                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                        }
                        if (mounted) setState(() {});
                        if (parentContext.mounted) {
                          AppAlert.show(
                            parentContext,
                            'Added Profile: $displayName',
                            icon: Icons.check_circle_rounded,
                            isSuccess: true,
                          );
                        }
                      }
                    },
              child: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                    )
                  : const Text('Sync & Connect', style: TextStyle(fontWeight: FontWeight.bold)),
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
                title: Row(
                  children: [
                    Text(
                      acc.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (acc.isCoupleProfile) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.pinkAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'COUPLE',
                          style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  acc.isCoupleProfile && acc.partnerName.isNotEmpty
                      ? 'Shared with ${acc.partnerName} • Synchronized'
                      : '${acc.email} • ${acc.playlistsCount} Playlists',
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
          const SizedBox(height: 16),

          // Couple Session Listen-Together Action Card (if active account is Couple Profile)
          if (active.isCoupleProfile)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1318),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Couple Listen Together • ${active.partnerName.isNotEmpty ? active.partnerName : 'Partner'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Both phones listen simultaneously on independent earbuds with real-time drift sync.',
                    style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.hub_rounded, size: 18),
                      label: const Text('Start Synchronized Couple Session', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      onPressed: () {
                        Navigator.pop(context);
                        widget.accountService.startCoupleListenTogether();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const PartyView()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Multi-Device Presence Section (Spotify Connect Style)
          const Text(
            'Connected Devices on this Account',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...widget.accountService.connectedDevices.map((dev) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      dev.isPhone
                          ? Icons.smartphone_rounded
                          : dev.isPi
                              ? Icons.memory_rounded
                              : Icons.laptop_rounded,
                      color: dev.isActive ? Colors.greenAccent : Colors.white54,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dev.name,
                        style: TextStyle(
                          color: dev.isActive ? Colors.white : const Color(0xFFA1A1AA),
                          fontSize: 12,
                          fontWeight: dev.isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: dev.isActive
                            ? Colors.greenAccent.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        dev.isActive ? 'ACTIVE' : 'READY',
                        style: TextStyle(
                          color: dev.isActive ? Colors.greenAccent : Colors.white38,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),

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
