import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';

import '../../domain/models/song.dart' as domain;
import 'drift_database.dart';

const List<String> _builtInSongAssets = [
  'assets/songs/kukushka.json',
  'assets/songs/alye_parusa.json',
  'assets/songs/zvezda_po_imeni_solntse.json',
  'assets/songs/gruppa_krovi.json',
  'assets/songs/pesnya_o_vetre.json',
];

class SongDao {
  final AppDatabase _db;

  SongDao(this._db);

  Future<List<domain.Song>> getAllSongs() async {
    final rows = await _db.select(_db.songs).get();
    return rows.map(_rowToSong).toList();
  }

  Future<domain.Song?> getSongById(String id) async {
    final query = _db.select(_db.songs)..where((s) => s.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _rowToSong(row) : null;
  }

  Future<void> insertSong(domain.Song song) async {
    final companion = SongsCompanion(
      id: Value(song.id),
      title: Value(song.title),
      artist: Value(song.artist),
      bpm: Value(song.bpm),
      jsonContent: Value(jsonEncode(song.toJson())),
      isBuiltIn: Value(song.isBuiltIn),
    );
    await _db.into(_db.songs).insertOnConflictUpdate(companion);
  }

  Future<void> deleteSong(String id) async {
    final query = _db.delete(_db.songs)..where((s) => s.id.equals(id));
    await query.go();
  }

  Future<List<domain.Song>> importBuiltInSongs() async {
    final songs = <domain.Song>[];
    for (final asset in _builtInSongAssets) {
      try {
        final jsonString = await rootBundle.loadString(asset);
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final song = domain.Song.fromJson(json);
        await insertSong(song);
        songs.add(song);
      } catch (_) {
        // Skip assets that fail to load or parse.
      }
    }
    return songs;
  }

  domain.Song _rowToSong(Song row) {
    final json = jsonDecode(row.jsonContent) as Map<String, dynamic>;
    return domain.Song.fromJson(json);
  }
}
