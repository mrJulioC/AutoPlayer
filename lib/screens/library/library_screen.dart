import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/song_item.dart';
import '../../services/music/music_scanner_service.dart';
import '../../services/player/audio_player_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final MusicScannerService _scanner = MusicScannerService();
  final AudioPlayerService _playerService = AudioPlayerService();

  bool _loading = true;
  List<SongItem> _songs = [];

  @override
  void initState() {
    super.initState();
    _scanSongs();
  }

  Future<void> _scanSongs() async {
    final permission = await Permission.audio.request();

    if (!permission.isGranted) {
      if (!mounted) return;
      setState(() {
        _songs = [];
        _loading = false;
      });
      return;
    }

    final songs = await _scanner.scanMyMusic();

    if (!mounted) return;

    setState(() {
      _songs = songs;
      _loading = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await _scanSongs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Música local'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _refresh,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? const Center(
                  child: Text(
                    'No se encontraron canciones.\n\nGuarda tus MP3 en:\nAlmacenamiento interno/AutoPlayer',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = _songs[index];

                    return ListTile(
                      leading: const Icon(Icons.music_note_rounded),
                      title: Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(song.extension.toUpperCase()),
                      trailing: const Icon(Icons.play_arrow_rounded),
                      onTap: () async {
                        await _playerService.playSong(song);
                      },
                    );
                  },
                ),
    );
  }
}
