import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_data_repository.dart';
import '../services/account_service.dart';
import '../views/auth/login_view.dart';
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
  bool _isSyncing = false;

  Future<void> _handleSyncYouTube() async {
    setState(() => _isSyncing = true);
    try {
      final success = await widget.accountService.syncRealYouTubeAccount();
      if (mounted) {
        if (success) {
          AppAlert.show(
            context,
            'YouTube Music playlists & liked songs synchronized successfully!',
            icon: Icons.check_circle_rounded,
            isSuccess: true,
          );
        } else {
          // If no token, prompt Google Sign-In
          AppAlert.show(
            context,
            'Please sign in with Google to grant YouTube Music access.',
            icon: Icons.info_outline_rounded,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppAlert.show(
          context,
          'Sync failed: ${e.toString().replaceAll('Exception: ', '')}',
          icon: Icons.error_outline_rounded,
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _handleSignOut() async {
    Navigator.pop(context);
    await AppAuthRepository.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = AppAuthRepository.instance.currentUser;
    final active = widget.accountService.activeAccount;
    final hasGoogle = user?.linkedServices['youtube_music'] == true;
    final playlists = UserDataRepository.instance.playlists;
    final ytPlaylistsCount = playlists.where((p) => p.id.startsWith('yt_')).length;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Account & Connected Services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Authenticated User Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFF2E2E34),
                    backgroundImage: NetworkImage(active.avatarUrl),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                active.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 16),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          active.email,
                          style: const TextStyle(
                            color: Color(0xFFA1A1AA),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'AUTHENTICATED • FIREBASE & GOOGLE',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // YouTube Music Integration Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasGoogle ? Colors.redAccent.withValues(alpha: 0.3) : Colors.white12,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.play_circle_fill_rounded, color: Colors.redAccent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'YouTube Music Synchronisation',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hasGoogle
                                  ? '$ytPlaylistsCount synced playlists • Direct OAuth Access'
                                  : 'Connect Google account to sync your playlists and liked music',
                              style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasGoogle ? Colors.white : Colors.redAccent,
                        foregroundColor: hasGoogle ? Colors.black : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: _isSyncing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.sync_rounded, size: 18),
                      label: Text(
                        _isSyncing
                            ? 'Synchronizing Playlists...'
                            : hasGoogle
                                ? 'Sync YouTube Music Playlists'
                                : 'Connect YouTube with Google Sign-In',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: _isSyncing
                          ? null
                          : () {
                              if (hasGoogle) {
                                _handleSyncYouTube();
                              } else {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginView()),
                                );
                              }
                            },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Connected Hardware / Devices
            const Text(
              'Connected Devices & Streamers',
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

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text(
                  'Sign Out',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: _handleSignOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
