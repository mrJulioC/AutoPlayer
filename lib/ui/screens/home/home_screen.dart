import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../models/song_item.dart';
import '../../../services/music/music_scanner_service.dart';
import '../../../services/player/audio_player_service.dart';
import '../../widgets/home_action_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final MusicScannerService _scanner = MusicScannerService();
  final AudioPlayerService _player = AudioPlayerService();
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  List<SongItem> _songs = [];
  List<SongItem> _filteredSongs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSongs();
    _searchController.addListener(_filterSongs);
  }

  Future<void> _loadSongs() async {
    if (mounted) {
      setState(() => _loading = true);
    }

    try {
      final statuses = await <Permission>[
        Permission.audio,
        Permission.storage,
      ].request();

      final canReadAudio =
          statuses[Permission.audio]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true;

      if (!canReadAudio) {
        if (!mounted) return;
        setState(() {
          _songs = [];
          _filteredSongs = [];
          _loading = false;
        });
        return;
      }

      final songs = await _scanner.scanMyMusic();

      if (!mounted) return;
      setState(() {
        _songs = songs;
        _filteredSongs = songs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _songs = [];
        _filteredSongs = [];
        _loading = false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSongs();
    }
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .trim();
  }

  void _filterSongs() {
    final query = _normalize(_searchController.text);

    setState(() {
      _filteredSongs = query.isEmpty
          ? _songs
          : _songs.where((song) {
              return _normalize(song.title).contains(query);
            }).toList();
    });
  }

  Future<void> _playFirstSearchResult() async {
    if (_filteredSongs.isEmpty) return;

    await _player.playSong(_filteredSongs.first);

    _searchController.clear();

    if (!mounted) return;

    setState(() {
      _filteredSongs = _songs;
    });
  }

  Future<void> _stopAudio() async {
    await _player.stop();

    if (!mounted) return;

    setState(() {});
  }

  Future<void> _confirmDeleteSong(SongItem song) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar canción'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final deleted = await _scanner.deleteSong(song);
    if (!deleted) return;

    await _player.removeSong(song);
    await _loadSongs();
  }

  void _showSongMenu(SongItem song) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF17171F),
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
            title: const Text('Eliminar canción'),
            onTap: () {
              Navigator.of(sheetContext).pop();
              _confirmDeleteSong(song);
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  Widget _logo() {
    return Center(
      child: Image.asset(
        'assets/icons/app_icon.png',
        width: 58,
        height: 58,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.music_note_rounded,
            size: 58,
            color: Color(0xFF00E676),
          );
        },
      ),
    );
  }

  Widget _nowPlayingBox() {
    return ValueListenableBuilder<SongItem?>(
      valueListenable: _player.currentSongNotifier,
      builder: (context, song, _) {
        if (song == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF17171F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            song.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
        );
      },
    );
  }

  Widget _searchBox() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _playFirstSearchResult(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                hintText: '',
                filled: true,
                fillColor: const Color(0xFF17171F),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ValueListenableBuilder<SongItem?>(
            valueListenable: _player.currentSongNotifier,
            builder: (context, song, _) {
              if (song == null) return const SizedBox.shrink();

              return SizedBox(
                width: 42,
                height: 42,
                child: ElevatedButton(
                  onPressed: _stopAudio,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Icon(Icons.stop_rounded, size: 24),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _songList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_filteredSongs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'No se encontraron canciones.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredSongs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final song = _filteredSongs[index];

        return ValueListenableBuilder<SongItem?>(
          valueListenable: _player.currentSongNotifier,
          builder: (context, currentSong, _) {
            final isCurrent = currentSong?.path == song.path;

            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              leading: Icon(
                isCurrent ? Icons.play_arrow_rounded : Icons.music_note_rounded,
                size: 20,
                color: isCurrent ? const Color(0xFF00E676) : Colors.white54,
              ),
              title: Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrent ? const Color(0xFF00E676) : Colors.white,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: Text(
                song.extension.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white38),
              ),
              trailing: IconButton(
                tooltip: 'Opciones',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: Colors.white54,
                ),
                onPressed: () => _showSongMenu(song),
              ),
              onTap: () async {
                await _player.playSong(song);
              },
            );
          },
        );
      },
    );
  }

  Widget _controls() {
    return Column(
      children: [
        HomeActionButton(
          icon: Icons.play_arrow_rounded,
          title: 'Reproducir lista',
          subtitle: 'En orden',
          onTap: () => _player.playList(_songs),
        ),
        const SizedBox(height: 8),
        HomeActionButton(
          icon: Icons.shuffle_rounded,
          title: 'Aleatorio',
          subtitle: 'Mezclar',
          onTap: () => _player.playRandom(_songs),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<bool>(
          valueListenable: _player.isPlayingNotifier,
          builder: (context, isPlaying, _) {
            return HomeActionButton(
              icon: isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_circle_fill_rounded,
              title: isPlaying ? 'Pausar' : 'Continuar',
              subtitle: 'Control',
              onTap: () => _player.togglePause(),
            );
          },
        ),
        const SizedBox(height: 8),
        HomeActionButton(
          icon: Icons.skip_next_rounded,
          title: 'Siguiente',
          subtitle: 'Pasar',
          onTap: () => _player.next(),
        ),
        const SizedBox(height: 8),
        HomeActionButton(
          icon: Icons.skip_previous_rounded,
          title: 'Anterior',
          subtitle: 'Volver',
          onTap: () => _player.previous(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadSongs,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _logo(),
              const SizedBox(height: 6),
              const Text(
                'AutoPlayer',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _loading ? 'Escaneando...' : '${_songs.length} canciones',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.white60),
              ),
              const SizedBox(height: 10),
              _nowPlayingBox(),
              const SizedBox(height: 10),
              _searchBox(),
              const SizedBox(height: 10),
              _controls(),
              const SizedBox(height: 14),
              const Text(
                'Canciones',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _songList(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
