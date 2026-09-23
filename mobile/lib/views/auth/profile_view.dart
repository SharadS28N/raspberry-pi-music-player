import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_data_repository.dart';
import 'login_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF09090B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'User Profile & AI Taste',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.login_rounded, color: Colors.white70),
            tooltip: 'Sign In / Switch',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginView()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<UserProfile?>(
        stream: AppAuthRepository.instance.authStateChanges,
        initialData: AppAuthRepository.instance.currentUser,
        builder: (context, snapshot) {
          final profile = snapshot.data ?? UserProfile.defaultProfile();
          final taste = UserDataRepository.instance.tasteVector;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E24), Color(0xFF141418)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF6366F1),
                        backgroundImage: profile.photoUrl.isNotEmpty
                            ? NetworkImage(profile.photoUrl)
                            : null,
                        child: profile.photoUrl.isEmpty
                            ? Text(
                                profile.displayName.isNotEmpty
                                    ? profile.displayName[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: profile.isGuest
                                        ? Colors.amberAccent.withValues(alpha: 0.2)
                                        : Colors.greenAccent.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    profile.isGuest ? 'DEMO' : 'ACTIVE',
                                    style: TextStyle(
                                      color: profile.isGuest ? Colors.amberAccent : Colors.greenAccent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile.email,
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Listening Statistics Row
                const Text(
                  'Listening Telemetry',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Listening Time',
                        value: '${(profile.totalListeningTimeSeconds / 60).toInt()} min',
                        icon: Icons.timer_outlined,
                        color: Colors.lightBlueAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        title: 'Tracks Played',
                        value: '${profile.totalTracksPlayed}',
                        icon: Icons.music_note_rounded,
                        color: Colors.purpleAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // AI Acoustic Taste Vector Breakdown
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'AI Acoustic Taste Vector',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Dynamically updated as you listen, like (+1.8), skip (-2.0), or complete tracks.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141418),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _buildAcousticBar('Energy Intensity', taste.energy, Colors.redAccent),
                      _buildAcousticBar('Valence / Positivity', taste.valence, Colors.amberAccent),
                      _buildAcousticBar('Danceability', taste.danceability, Colors.greenAccent),
                      _buildAcousticBar('Acoustic Richness', taste.acousticness, Colors.lightBlueAccent),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Average Tempo', style: TextStyle(color: Colors.white70, fontSize: 13)),
                            Text(
                              '${taste.tempo.toInt()} BPM',
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Preferred Genres
                const Text(
                  'Preferred Genres',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: profile.preferredGenres.map((g) {
                    return Chip(
                      label: Text(g, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      backgroundColor: const Color(0xFF222228),
                      side: const BorderSide(color: Colors.white12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32),

                // Sign Out / Reset Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text('Sign Out / Reset Session'),
                    onPressed: () async {
                      await AppAuthRepository.instance.signOut();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Session reset to demo mode.')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAcousticBar(String label, double value, Color barColor) {
    final pct = (value * 100).toInt();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
