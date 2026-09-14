import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/account_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/local_audio_service.dart';
import 'album_view.dart';
import 'settings_view.dart';
import '../widgets/app_alert.dart';

class LibraryView extends StatefulWidget {
  final AccountService accountService;
  final LocalAudioService localAudioService;
  final Function(Track) onPlayTrack;
  final AudioPlayerService? audioService;

  const LibraryView({
    super.key,
    required this.accountService,
    required this.localAudioService,
    required this.onPlayTrack,
    this.audioService,
  });

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['Library', 'Playlists', 'Songs', 'Albums', 'Artists'];

  @override
  void initState() {
    super.initState();
    DownloadService.instance.addListener(_onStateChange);
    widget.audioService?.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DownloadService.instance.removeListener(_onStateChange);
    widget.audioService?.removeListener(_onStateChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localTracks = widget.localAudioService.localTracks;
    final activeAccount = widget.accountService.activeAccount;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Top Bar with App Logo
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.0),
                  ),
                  child: const Center(
                    child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Library',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white70),
                  tooltip: 'History',
                  onPressed: () => _showHistoryModal(context),
                ),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white70),
                  tooltip: 'Equalizer & DSP',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsView()),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsView()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal Filter Pills (Matching screenshot_8.jpg)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedFilterIndex;
                  return ChoiceChip(
                    label: Text(
                      _filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.black : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.white,
                    backgroundColor: const Color(0xFF141414),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilterIndex = index);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Featured "MOST PLAYED" Banner (Matching screenshot_8.jpg)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumView(
                      albumTitle: 'The Problem Einstein Couldn\'t Solve',
                      artistName: '40mP',
                      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
                      audioService: widget.onPlayTrack as dynamic,
                      onPlayTrack: widget.onPlayTrack,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=300',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '☆ MOST PLAYED',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'The Problem Einstein couldn\'t solve',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '11 songs',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFC4E0B8),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 22),
                          label: const Text('Play all', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () {
                            widget.onPlayTrack(Track(
                              id: '34Na4j8AVgA',
                              title: 'Starboy',
                              artist: 'The Weeknd ft. Daft Punk',
                              album: 'Starboy (Deluxe)',
                              duration: const Duration(minutes: 3, seconds: 50),
                              artworkUrl: 'https://i.ytimg.com/vi/34Na4j8AVgA/hqdefault.jpg',
                              streamUrl: '',
                              codec: 'FLAC 24-bit',
                            ));
                          },
                        ),
                        const Spacer(),
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white12,
                          child: IconButton(
                            icon: const Icon(Icons.shuffle_rounded, color: Colors.white, size: 18),
                            tooltip: 'Shuffle',
                            onPressed: () {
                              widget.onPlayTrack(Track(
                                id: '4NRXx6U8ABQ',
                                title: 'Blinding Lights',
                                artist: 'The Weeknd',
                                album: 'After Hours',
                                duration: const Duration(minutes: 3, seconds: 20),
                                artworkUrl: 'https://i.ytimg.com/vi/4NRXx6U8ABQ/hqdefault.jpg',
                                streamUrl: '',
                                codec: 'OPUS 160kbps',
                              ));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Grid Cards (Matching screenshot_8.jpg)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildLibraryCard(
                  icon: Icons.favorite_rounded,
                  iconColor: Colors.white,
                  title: 'Liked songs',
                  subtitle: '${widget.audioService?.likedTracks.length ?? activeAccount.likedSongsCount} tracks',
                  onTap: () => _showLikedTracksModal(context),
                ),
                _buildLibraryCard(
                  icon: Icons.offline_pin_rounded,
                  iconColor: Colors.white,
                  title: 'Offline',
                  subtitle: '${DownloadService.instance.downloadedTracks.length} tracks',
                  onTap: () => _showOfflineTracksModal(context),
                ),
                _buildLibraryCard(
                  icon: Icons.cached_rounded,
                  iconColor: Colors.white,
                  title: 'Cached',
                  subtitle: 'Instant playback',
                  onTap: () {
                    widget.onPlayTrack(Track(
                      id: '34Na4j8AVgA',
                      title: 'Starboy',
                      artist: 'The Weeknd ft. Daft Punk',
                      album: 'Starboy (Deluxe)',
                      duration: const Duration(minutes: 3, seconds: 50),
                      artworkUrl: 'https://i.ytimg.com/vi/34Na4j8AVgA/hqdefault.jpg',
                      streamUrl: '',
                      codec: 'FLAC 24-bit',
                    ));
                  },
                ),
                _buildLibraryCard(
                  icon: Icons.folder_rounded,
                  iconColor: Colors.white,
                  title: 'Local Files',
                  subtitle: '${localTracks.length} On device',
                  onTap: () async {
                    await widget.localAudioService.scanDeviceAudio();
                    if (context.mounted) {
                      AppAlert.show(
                        context,
                        'Found ${widget.localAudioService.localTracks.length} local audio files on device',
                        icon: Icons.folder_open_rounded,
                        isSuccess: true,
                      );
                    }
                  },
                ),
                _buildLibraryCard(
                  icon: Icons.trending_up_rounded,
                  iconColor: Colors.white,
                  title: 'My top 50',
                  subtitle: 'All time',
                  onTap: () {
                    widget.onPlayTrack(Track(
                      id: 'TUVcZfQe-Kw',
                      title: 'Levitating',
                      artist: 'Dua Lipa',
                      album: 'Future Nostalgia',
                      duration: const Duration(minutes: 3, seconds: 23),
                      artworkUrl: 'https://i.ytimg.com/vi/TUVcZfQe-Kw/hqdefault.jpg',
                      streamUrl: '',
                      codec: 'OPUS 160kbps',
                    ));
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: iconColor.withValues(alpha: 0.15),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showOfflineTracksModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final currentDownloaded = DownloadService.instance.downloadedTracks;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.offline_pin_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Offline Tracks (${currentDownloaded.length})',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (currentDownloaded.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Column(
                        children: [
                          Icon(Icons.download_for_offline_outlined, color: Colors.white38, size: 48),
                          SizedBox(height: 12),
                          Text(
                            'No Offline Downloads',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Tap the download button on any song while playing or searching to store it offline on your device.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: currentDownloaded.length,
                        separatorBuilder: (c, i) => const SizedBox(height: 8),
                        itemBuilder: (c, i) {
                          final track = currentDownloaded[i];
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            tileColor: Colors.white.withValues(alpha: 0.04),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover),
                            ),
                            title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('${track.artist} • Offline M4A', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 20),
                                  tooltip: 'Delete download',
                                  onPressed: () async {
                                    await DownloadService.instance.deleteDownloadedTrack(track.id);
                                    setModalState(() {});
                                    setState(() {});
                                  },
                                ),
                                const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              widget.onPlayTrack(track);
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLikedTracksModal(BuildContext context) {
    final liked = widget.audioService?.likedTracks ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.favorite_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Liked Songs (${liked.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (liked.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.favorite_border_rounded, color: Colors.white38, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No Liked Songs Yet',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Tap the heart icon on any playing song to add it to your favorite collection.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: liked.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final track = liked[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          tileColor: Colors.white.withValues(alpha: 0.04),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('${track.artist} • ${track.album}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                          trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onPlayTrack(track);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showHistoryModal(BuildContext context) {
    final history = widget.audioService?.history ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'Listening History (${history.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: const Column(
                      children: [
                        Icon(Icons.history_toggle_off_rounded, color: Colors.white38, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No Listening History',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Songs you stream or play will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: history.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final track = history[i];
                        return ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          tileColor: Colors.white.withValues(alpha: 0.04),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover),
                          ),
                          title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text(track.artist, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                          trailing: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                          onTap: () {
                            Navigator.pop(ctx);
                            widget.onPlayTrack(track);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
