import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/track.dart';
import '../services/party_service.dart';
import '../services/audio_player_service.dart';
import '../services/account_service.dart';
import '../services/youtube_service.dart';
import '../widgets/app_alert.dart';

class PartyView extends StatefulWidget {
  final AudioPlayerService? audioService;

  const PartyView({
    super.key,
    this.audioService,
  });

  @override
  State<PartyView> createState() => _PartyViewState();
}

class _PartyViewState extends State<PartyView> {
  final PartyService _party = PartyService.instance;
  final AccountService _account = AccountService.instance;
  late AudioPlayerService _audio;

  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  List<Track> _searchResults = [];
  bool _isLoadingSearch = false;

  @override
  void initState() {
    super.initState();
    _audio = widget.audioService ?? AudioPlayerService.instance;
    _party.addListener(_onPartyUpdate);
  }

  void _onPartyUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _party.removeListener(_onPartyUpdate);
    _codeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showAddTrackSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141414),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.playlist_add_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Add Song to Party Queue',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search title, artist or paste YouTube URL...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF27272A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (query) async {
                  if (query.trim().isEmpty) return;
                  setSheetState(() => _isLoadingSearch = true);
                  final results = await YoutubeService().searchTracks(query.trim());
                  setSheetState(() {
                    _searchResults = results;
                    _isLoadingSearch = false;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_isLoadingSearch)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              else if (_searchResults.isNotEmpty)
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final track = _searchResults[idx];
                      return ListTile(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        tileColor: const Color(0xFF1E1E24),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: track.artworkUrl.isNotEmpty
                              ? Image.network(track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.music_note, color: Colors.white54))
                              : const Icon(Icons.music_note, color: Colors.white54),
                        ),
                        title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                          tooltip: 'Add to Party',
                          onPressed: () {
                            _party.addToPartyQueue(track);
                            Navigator.pop(ctx);
                            AppAlert.show(this.context, 'Added "${track.title}" to Party Queue', icon: Icons.check_circle_rounded, isSuccess: true);
                          },
                        ),
                      );
                    },
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('Type a song name and tap enter to search', style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: const Color(0xFF000000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          children: [
            Icon(Icons.speaker_group_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text('Music Party & Jam', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          if (_party.isInParty)
            IconButton(
              icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              tooltip: 'Leave Party',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF18181B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Leave Music Party?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    content: const Text('You will disconnect from this synchronized session. Your audio will pause locally.', style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Leave'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _party.leaveParty();
                }
              },
            ),
        ],
      ),
      body: _party.isInParty ? _buildActivePartyView() : _buildLobbyView(),
    );
  }

  // --- 1. LOBBY VIEW (Not in party) ---
  Widget _buildLobbyView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Hero Card: How it works
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E1E24), Color(0xFF121216)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync_rounded, color: Color(0xFF22C55E), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'TIMESTAMP DRIFT SYNC ENGINE',
                      style: TextStyle(color: Color(0xFF22C55E), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Listen Together in Real Time',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Everyone uses their own phone and independent Bluetooth earbuds or AirPods. OpenAamps intelligently synchronizes playback position and collaborative queues.',
                style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 13, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Action 1: Host a New Party
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'START A NEW SESSION',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _party.isConnecting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Icon(Icons.add_circle_rounded, size: 20),
                  label: Text(
                    _party.isConnecting ? 'Starting Party...' : 'Host a Music Party',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  onPressed: _party.isConnecting
                      ? null
                      : () async {
                          final success = await _party.createParty(initialTrack: _audio.currentTrack);
                          if (success && mounted) {
                            AppAlert.show(context, 'Party started! Share room code "${_party.currentRoomCode}"', icon: Icons.celebration_rounded, isSuccess: true);
                          }
                        },
                ),
              ),
              if (_account.activeAccount.isCoupleProfile) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 18),
                    label: Text(
                      'Listen with ${_account.activeAccount.partnerName} (Couple Mode)',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: () async {
                      final success = await _account.startCoupleListenTogether(track: _audio.currentTrack);
                      if (success && mounted) {
                        AppAlert.show(context, 'Couple Session started with ${_account.activeAccount.partnerName}', icon: Icons.favorite_rounded, isSuccess: true);
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Action 2: Join Existing Party with Room Code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF141414),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'JOIN WITH ROOM CODE',
                style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2.0),
                      decoration: InputDecoration(
                        hintText: 'e.g. JAM-8842',
                        hintStyle: const TextStyle(color: Colors.white30, letterSpacing: 1.0),
                        filled: true,
                        fillColor: const Color(0xFF27272A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _party.isConnecting
                          ? null
                          : () async {
                              final code = _codeController.text.trim();
                              if (code.isEmpty) return;
                              final success = await _party.joinParty(code);
                              if (success && mounted) {
                                AppAlert.show(context, 'Joined party $code!', icon: Icons.check_circle_rounded, isSuccess: true);
                              } else if (mounted) {
                                AppAlert.show(context, 'Could not join party. Check room code.', icon: Icons.error_outline_rounded, isSuccess: false);
                              }
                            },
                      child: const Text('Join', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- 2. ACTIVE PARTY VIEW (In party session) ---
  Widget _buildActivePartyView() {
    final currentTrack = _party.partyCurrentTrack ?? _audio.currentTrack;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Room Code Banner & Copy
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF18181B),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ROOM CODE', style: TextStyle(color: Color(0xFFA1A1AA), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                  const SizedBox(height: 2),
                  Text(_party.currentRoomCode ?? 'JAM-0000', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_rounded, color: Colors.white),
                tooltip: 'Copy Code',
                onPressed: () {
                  if (_party.currentRoomCode != null) {
                    Clipboard.setData(ClipboardData(text: _party.currentRoomCode!));
                    AppAlert.show(context, 'Room code copied to clipboard', icon: Icons.copy_rounded, isSuccess: true);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Live Sync Status Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(
                'Synchronized (${_party.driftMs}ms drift)',
                style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const Spacer(),
              const Icon(Icons.headphones_rounded, color: Color(0xFF10B981), size: 16),
              const SizedBox(width: 4),
              const Text('Local Audio Active', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Host Permissions Toggle
        if (_party.isHost)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                const Icon(Icons.group_work_rounded, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Collaborative DJ (Anyone can skip/play)', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
                Switch(
                  value: _party.allowCollaborativeDj,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white38,
                  onChanged: (val) => _party.toggleCollaborativeDj(val),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Participants Avatars Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PARTICIPANTS (${_party.members.length})', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _party.members.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (context, idx) {
              final m = _party.members[idx];
              return Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: m.avatarUrl.isNotEmpty ? NetworkImage(m.avatarUrl) : null,
                        backgroundColor: const Color(0xFF27272A),
                        child: m.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                      ),
                      if (m.role == 'host')
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                            child: const Icon(Icons.star, size: 10, color: Colors.black),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 11)),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Now Playing Card
        if (currentTrack != null) ...[
          const Text('NOW PLAYING IN PARTY', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: currentTrack.artworkUrl.isNotEmpty
                      ? Image.network(currentTrack.artworkUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.music_note, color: Colors.white54, size: 30))
                      : const Icon(Icons.music_note, color: Colors.white54, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(currentTrack.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(currentTrack.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                if (_party.canControlPlayback) ...[
                  IconButton(
                    icon: Icon(_audio.player.playing ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 38),
                    onPressed: () {
                      if (_audio.player.playing) {
                        _audio.pause();
                      } else {
                        _audio.resume();
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28),
                    tooltip: 'Skip to Next',
                    onPressed: () => _party.skipPartyTrack(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Collaborative Queue
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('SHARED QUEUE (${_party.partyQueue.length})', style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 16, color: Colors.white),
              label: const Text('Add Song', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: _showAddTrackSheet,
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_party.partyQueue.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.queue_music_rounded, color: Colors.white38, size: 36),
                  const SizedBox(height: 8),
                  const Text('Party queue is empty', style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF27272A), foregroundColor: Colors.white),
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text('Search & Add Tracks'),
                    onPressed: _showAddTrackSheet,
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _party.partyQueue.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, idx) {
              final qItem = _party.partyQueue[idx];
              final hasVoted = qItem.votedMembers.contains(_account.activeAccount.id);

              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                tileColor: const Color(0xFF141414),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: qItem.track.artworkUrl.isNotEmpty
                      ? Image.network(qItem.track.artworkUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (context, error, stack) => const Icon(Icons.music_note, color: Colors.white54))
                      : const Icon(Icons.music_note, color: Colors.white54),
                ),
                title: Text(qItem.track.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('${qItem.track.artist} • Added by ${qItem.addedByName}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                trailing: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: hasVoted ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                  ),
                  icon: Icon(Icons.thumb_up_alt_rounded, size: 16, color: hasVoted ? Colors.white : Colors.white54),
                  label: Text('${qItem.votes}', style: TextStyle(color: hasVoted ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                  onPressed: () => _party.voteQueueTrack(qItem.track.id),
                ),
              );
            },
          ),
      ],
    );
  }
}
