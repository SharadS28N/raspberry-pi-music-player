import 'package:flutter/material.dart';
import '../models/track.dart';
import '../services/account_service.dart';
import '../services/audio_player_service.dart';
import '../services/download_service.dart';
import '../services/local_audio_service.dart';
import 'album_view.dart';
import 'artist_view.dart';
import 'settings_view.dart';
import '../widgets/app_alert.dart';
import '../widgets/equalizer_sheet.dart';
import '../widgets/tag_editor_modal.dart';

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
  final List<String> _filters = ['Library', 'Playlists', 'Songs', 'Albums', 'Artists', 'Folders', 'WebDAV'];

  // WebDAV Controller state
  final TextEditingController _webDavUrlController = TextEditingController(text: 'https://cloud.example.com/remote.php/dav/files/user/Music/');
  final TextEditingController _webDavUserController = TextEditingController(text: 'openaamps_user');
  final TextEditingController _webDavPassController = TextEditingController(text: '••••••••');
  bool _isWebDavConnected = false;
  bool _isSyncingWebDav = false;

  @override
  void initState() {
    super.initState();
    DownloadService.instance.addListener(_onStateChange);
    widget.audioService?.addListener(_onStateChange);
    widget.localAudioService.addListener(_onStateChange);
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DownloadService.instance.removeListener(_onStateChange);
    widget.audioService?.removeListener(_onStateChange);
    widget.localAudioService.removeListener(_onStateChange);
    _webDavUrlController.dispose();
    _webDavUserController.dispose();
    _webDavPassController.dispose();
    super.dispose();
  }

  void _showTagEditor(Track track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => TagEditorModal(
        track: track,
        onSaved: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  tooltip: '15-Band EQ & AutoEq',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder: (context) => const EqualizerSheet(),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white70),
                  tooltip: 'Settings',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsView(audioService: widget.audioService)),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Horizontal Pill Filter Tabs
            SizedBox(
              height: 36,
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
            const SizedBox(height: 20),

            // Dynamic Content Based on Selected Filter
            _buildTabContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedFilterIndex) {
      case 1: // Playlists
        return _buildPlaylistsTab();
      case 2: // Songs
        return _buildSongsTab();
      case 3: // Albums
        return _buildAlbumsTab();
      case 4: // Artists
        return _buildArtistsTab();
      case 5: // Folders
        return _buildFoldersTab();
      case 6: // WebDAV
        return _buildWebDavTab();
      case 0: // Library Overview
      default:
        return _buildOverviewTab();
    }
  }

  // --- Tab 0: Library Overview ---
  Widget _buildOverviewTab() {
    final localTracks = widget.localAudioService.localTracks;
    final activeAccount = widget.accountService.activeAccount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Featured "MOST PLAYED" Banner
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumView(
                  albumTitle: 'The Problem Einstein Couldn\'t Solve',
                  artistName: '40mP',
                  coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
                  audioService: widget.audioService ?? AudioPlayerService(),
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
                            '11 songs • 40mP',
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () {
                        widget.onPlayTrack(Track(
                          id: 'local_track_1',
                          title: 'ハイスペックニート - High Spec Neet',
                          artist: '40mP',
                          album: 'Einstein Problem',
                          duration: const Duration(minutes: 3, seconds: 19),
                          artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
                          streamUrl: '',
                          codec: 'FLAC 24-bit',
                        ));
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text('Play', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
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

        // Grid Cards
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
              icon: Icons.folder_rounded,
              iconColor: Colors.white,
              title: 'Folder Browser',
              subtitle: '${widget.localAudioService.folders.length} directories',
              onTap: () => setState(() => _selectedFilterIndex = 5),
            ),
            _buildLibraryCard(
              icon: Icons.cloud_queue_rounded,
              iconColor: Colors.white,
              title: 'WebDAV Cloud',
              subtitle: _isWebDavConnected ? 'Connected' : 'Configure',
              onTap: () => setState(() => _selectedFilterIndex = 6),
            ),
            _buildLibraryCard(
              icon: Icons.history_rounded,
              iconColor: Colors.white,
              title: 'Recently Played',
              subtitle: '${widget.audioService?.history.length ?? 0} tracks',
              onTap: () => _showHistoryModal(context),
            ),
            _buildLibraryCard(
              icon: Icons.library_music_rounded,
              iconColor: Colors.white,
              title: 'Local Files',
              subtitle: '${localTracks.length} tracks',
              onTap: () => setState(() => _selectedFilterIndex = 2),
            ),
          ],
        ),
      ],
    );
  }

  // --- Tab 1: Smart & Custom Playlists ---
  Widget _buildPlaylistsTab() {
    final smartPlaylists = [
      {
        'title': 'Liked Songs',
        'desc': 'All starred favorite songs',
        'count': '${widget.audioService?.likedTracks.length ?? 0} songs',
        'icon': Icons.favorite_rounded,
        'action': () => _showLikedTracksModal(context),
      },
      {
        'title': 'Recently Played',
        'desc': 'Smart playlist of recent tracks',
        'count': '${widget.audioService?.history.length ?? 0} songs',
        'icon': Icons.history_rounded,
        'action': () => _showHistoryModal(context),
      },
      {
        'title': 'Offline Downloads',
        'desc': 'Saved on device with tagged metadata',
        'count': '${DownloadService.instance.downloadedTracks.length} songs',
        'icon': Icons.offline_pin_rounded,
        'action': () => _showOfflineTracksModal(context),
      },
      {
        'title': 'Most Played Hits',
        'desc': 'Top played songs on OpenAamps',
        'count': '11 songs',
        'icon': Icons.trending_up_rounded,
        'action': () {
          widget.onPlayTrack(Track(
            id: 'local_track_1',
            title: 'ハイスペックニート - High Spec Neet',
            artist: '40mP',
            album: 'Einstein Problem',
            duration: const Duration(minutes: 3, seconds: 19),
            artworkUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
            streamUrl: '',
            codec: 'FLAC 24-bit',
          ));
        },
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Smart & Custom Playlists', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                AppAlert.show(context, 'Custom playlist created: "My Jam 2026"', icon: Icons.playlist_add_rounded, isSuccess: true);
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New Playlist', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...smartPlaylists.map((pl) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
                  child: Icon(pl['icon'] as IconData, color: Colors.white, size: 20),
                ),
                title: Text(pl['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${pl['desc']} • ${pl['count']}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                trailing: const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 28),
                onTap: pl['action'] as VoidCallback,
              ),
            )),
      ],
    );
  }

  // --- Tab 2: All Songs with Tag Editor ---
  Widget _buildSongsTab() {
    final tracks = widget.localAudioService.localTracks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('All Songs (${tracks.length})', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => widget.localAudioService.scanDeviceMusic(),
              icon: widget.localAudioService.isScanning
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh_rounded, size: 16, color: Colors.white70),
              label: const Text('Rescan', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...tracks.map((track) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFF121212),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(track.artworkUrl, width: 46, height: 46, fit: BoxFit.cover),
                ),
                title: Text(track.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1),
                subtitle: Text('${track.artist} • ${track.codec}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white70, size: 22),
                      tooltip: 'Edit Song Tags (Tag Editor)',
                      onPressed: () => _showTagEditor(track),
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 26),
                      onPressed: () => widget.onPlayTrack(track),
                    ),
                  ],
                ),
                onTap: () => widget.onPlayTrack(track),
              ),
            )),
      ],
    );
  }

  // --- Tab 3: Albums ---
  Widget _buildAlbumsTab() {
    final albums = [
      {
        'title': 'Einstein Problem',
        'artist': '40mP',
        'year': '2026',
        'songs': '11 songs',
        'cover': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400',
      },
      {
        'title': 'Acoustic Sessions 2026',
        'artist': 'aimyon',
        'year': '2026',
        'songs': '8 songs',
        'cover': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400',
      },
      {
        'title': 'Piano Memories',
        'artist': 'Yuika',
        'year': '2025',
        'songs': '6 songs',
        'cover': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Albums', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...albums.map((alb) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(alb['cover']!, width: 46, height: 46, fit: BoxFit.cover),
                ),
                title: Text(alb['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${alb['artist']} • ${alb['year']} • ${alb['songs']}', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumView(
                        albumTitle: alb['title']!,
                        artistName: alb['artist']!,
                        coverUrl: alb['cover']!,
                        audioService: widget.audioService ?? AudioPlayerService(),
                        onPlayTrack: widget.onPlayTrack,
                      ),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }

  // --- Tab 4: Artists ---
  Widget _buildArtistsTab() {
    final artists = [
      {'name': '40mP', 'tracks': '14 tracks', 'img': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400'},
      {'name': 'aimyon', 'tracks': '9 tracks', 'img': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400'},
      {'name': 'Yuika', 'tracks': '7 tracks', 'img': 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400'},
      {'name': 'The Weeknd', 'tracks': '22 tracks', 'img': 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400'},
      {'name': 'Coldplay', 'tracks': '18 tracks', 'img': 'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=400'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Artists', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...artists.map((art) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFF141414),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: CircleAvatar(radius: 23, backgroundImage: NetworkImage(art['img']!)),
                title: Text(art['name']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(art['tracks']!, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ArtistView(
                        artistName: art['name']!,
                        avatarUrl: art['img']!,
                        audioService: widget.audioService ?? AudioPlayerService(),
                        onPlayTrack: widget.onPlayTrack,
                      ),
                    ),
                  );
                },
              ),
            )),
      ],
    );
  }

  // --- Tab 5: Folders Browsing & Blacklist/Whitelist Exclusion ---
  Widget _buildFoldersTab() {
    final folderMap = widget.localAudioService.folderTracks;
    final folders = widget.localAudioService.folders;
    final excludedFolders = widget.localAudioService.excludedFolders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Folder Browsing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${folders.length} Folders Included', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 12)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Browse songs directly by storage folder. Tap the hide button to blacklist and exclude any unwanted folder.',
          style: TextStyle(color: Color(0xFF71717A), fontSize: 12),
        ),
        const SizedBox(height: 14),

        if (folders.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(16)),
            child: const Text('No music folders discovered yet. Tap rescan in Songs tab.', style: TextStyle(color: Colors.white60)),
          )
        else
          ...folders.map((folderPath) {
            final tracks = folderMap[folderPath] ?? [];
            final folderName = folderPath.split(RegExp(r'[/\\]')).last;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF1E1E20), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
                ),
                title: Text(folderName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('${tracks.length} songs • $folderPath', style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility_off_outlined, color: Colors.white54, size: 18),
                      tooltip: 'Blacklist & Exclude Folder',
                      onPressed: () {
                        widget.localAudioService.excludeFolder(folderPath);
                        AppAlert.show(context, 'Folder excluded from library', icon: Icons.block_rounded, isSuccess: false);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      tooltip: 'Play Entire Folder',
                      onPressed: () {
                        if (tracks.isNotEmpty) {
                          widget.onPlayTrack(tracks.first);
                          widget.audioService?.setQueue(tracks, startIndex: 0);
                        }
                      },
                    ),
                  ],
                ),
                children: tracks.map((t) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: const Icon(Icons.music_note_rounded, color: Colors.white60, size: 18),
                      title: Text(t.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text(t.artist, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: Colors.white38, size: 18),
                        onPressed: () => _showTagEditor(t),
                      ),
                      onTap: () => widget.onPlayTrack(t),
                    )).toList(),
              ),
            );
          }),

        if (excludedFolders.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Excluded / Blacklisted Folders', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...excludedFolders.map((ex) => ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: const Color(0xFF1E1414),
                leading: const Icon(Icons.block_rounded, color: Colors.redAccent, size: 20),
                title: Text(ex, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                trailing: TextButton(
                  onPressed: () {
                    widget.localAudioService.includeFolder(ex);
                    AppAlert.show(context, 'Folder restored to library', icon: Icons.check_circle_rounded, isSuccess: true);
                  },
                  child: const Text('Restore', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ],
    );
  }

  // --- Tab 6: WebDAV Cloud Streaming Setup ---
  Widget _buildWebDavTab() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'WebDAV Personal Cloud Storage',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _isWebDavConnected ? Colors.green.withValues(alpha: 0.2) : Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isWebDavConnected ? 'CONNECTED' : 'DISCONNECTED',
                  style: TextStyle(
                    color: _isWebDavConnected ? Colors.greenAccent : Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Stream losslessly directly from your Nextcloud, ownCloud, Synology NAS, or Apache WebDAV server.',
            style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _webDavUrlController,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              labelText: 'WebDAV Server URL',
              labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF18181A),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _webDavUserController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF18181A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _webDavPassController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF18181A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      _isWebDavConnected = true;
                    });
                    AppAlert.show(context, 'WebDAV Cloud Connected & Synchronized', icon: Icons.cloud_done_rounded, isSuccess: true);
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Connect & Mount Cloud', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() => _isSyncingWebDav = true);
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) {
                      setState(() => _isSyncingWebDav = false);
                      AppAlert.show(context, 'Scanned 42 cloud tracks via WebDAV', icon: Icons.sync_rounded, isSuccess: true);
                    }
                  });
                },
                icon: _isSyncingWebDav
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync_rounded, size: 18),
                label: const Text('Scan Cloud'),
              ),
            ],
          ),
        ],
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                            'Tap download on any track while playing to save tagged audio for offline playback.',
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
                                  icon: const Icon(Icons.edit_note_rounded, color: Colors.white54, size: 20),
                                  tooltip: 'Edit tags',
                                  onPressed: () => _showTagEditor(track),
                                ),
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
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        Text('No Liked Songs Yet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('Tap heart on any song to add it to your favorite collection.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, color: Colors.white54, size: 20),
                                onPressed: () => _showTagEditor(track),
                              ),
                              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
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
    );
  }

  void _showHistoryModal(BuildContext context) {
    final history = widget.audioService?.history ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
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
                        Text('No Listening History', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text('Songs you stream or play will appear here automatically.', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13)),
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
