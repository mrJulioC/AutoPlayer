import 'package:flutter/services.dart';

import '../../models/song_item.dart';

class MusicScannerService {
  static const MethodChannel _channel = MethodChannel(
    'com.mrjulioc.autoplayer/media_store',
  );

  Future<List<SongItem>> scanMyMusic() async {
    try {
      final rawItems = await _channel.invokeListMethod<dynamic>('queryMedia');
      if (rawItems == null) return [];

      final songsBySource = <String, SongItem>{};

      for (final rawItem in rawItems) {
        if (rawItem is! Map) continue;

        final item = Map<String, dynamic>.from(rawItem);
        final source = (item['uri'] as String? ?? '').trim();
        if (source.isEmpty) continue;

        final displayName = (item['displayName'] as String? ?? '').trim();
        final metadataTitle = _cleanMetadata(
          item['title'] as String? ?? '',
        );
        final mimeType = (item['mimeType'] as String? ?? '').toLowerCase();
        final extension = _resolveExtension(displayName, mimeType);
        final title = metadataTitle.isNotEmpty
            ? metadataTitle
            : _cleanTitle(displayName.isNotEmpty ? displayName : source);

        songsBySource[source] = SongItem(
          title: title,
          path: source,
          extension: extension,
          size: (item['size'] as num?)?.toInt() ?? 0,
        );
      }

      final songs = songsBySource.values.toList()
        ..sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

      return songs;
    } on PlatformException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> deleteSong(SongItem song) async {
    try {
      final deleted = await _channel.invokeMethod<bool>(
        'deleteMedia',
        <String, dynamic>{'uri': song.path},
      );

      return deleted == true;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  String _resolveExtension(String displayName, String mimeType) {
    final dotIndex = displayName.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < displayName.length - 1) {
      return displayName.substring(dotIndex).toLowerCase();
    }

    const mimeExtensions = <String, String>{
      'audio/mpeg': '.mp3',
      'audio/mp4': '.m4a',
      'audio/aac': '.aac',
      'audio/flac': '.flac',
      'audio/ogg': '.ogg',
      'audio/opus': '.opus',
      'audio/wav': '.wav',
      'audio/x-wav': '.wav',
      'audio/amr': '.amr',
      'audio/3gpp': '.3gp',
      'video/mp4': '.mp4',
    };

    return mimeExtensions[mimeType] ?? '.audio';
  }

  String _cleanTitle(String value) {
    final fileName = value.split('/').last;
    return fileName.replaceAll(RegExp(r'\.[^.]+$'), '').trim();
  }

  String _cleanMetadata(String value) {
    final clean = value.trim();
    final lower = clean.toLowerCase();

    if (lower.isEmpty || lower == '<unknown>' || lower == 'unknown') {
      return '';
    }

    return clean;
  }
}
