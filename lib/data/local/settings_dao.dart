import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import '../../domain/models/metronome_settings.dart';
import '../../domain/models/song_settings.dart';
import 'drift_database.dart';

const Map<int, FontWeight> _fontWeightMap = {
  100: FontWeight.w100,
  200: FontWeight.w200,
  300: FontWeight.w300,
  400: FontWeight.w400,
  500: FontWeight.w500,
  600: FontWeight.w600,
  700: FontWeight.w700,
  800: FontWeight.w800,
  900: FontWeight.w900,
};

FontWeight _fontWeightFromValue(int value) {
  return _fontWeightMap[value] ?? FontWeight.normal;
}

class SettingsDao {
  final AppDatabase _db;

  SettingsDao(this._db);

  Future<SongSettings> getSongSettings(String songId) async {
    final key = 'song_settings_$songId';
    final query = _db.select(_db.settings)..where((s) => s.key.equals(key));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return SongSettings(songId: songId);
    }
    return _parseSongSettings(row.jsonValue, songId);
  }

  Future<void> saveSongSettings(SongSettings settings) async {
    final key = 'song_settings_${settings.songId}';
    final jsonValue = jsonEncode(_songSettingsToJson(settings));
    final companion = SettingsCompanion(
      key: Value(key),
      jsonValue: Value(jsonValue),
    );
    await _db.into(_db.settings).insertOnConflictUpdate(companion);
  }

  Future<MetronomeSettings> getMetronomeSettings() async {
    const key = 'metronome_settings';
    final query = _db.select(_db.settings)..where((s) => s.key.equals(key));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return const MetronomeSettings();
    }
    return _parseMetronomeSettings(row.jsonValue);
  }

  Future<void> saveMetronomeSettings(MetronomeSettings settings) async {
    const key = 'metronome_settings';
    final jsonValue = jsonEncode(_metronomeSettingsToJson(settings));
    final companion = SettingsCompanion(
      key: const Value(key),
      jsonValue: Value(jsonValue),
    );
    await _db.into(_db.settings).insertOnConflictUpdate(companion);
  }

  Map<String, dynamic> _songSettingsToJson(SongSettings s) {
    return {
      'songId': s.songId,
      'textFontFamily': s.textFontFamily,
      'chordsFontFamily': s.chordsFontFamily,
      'textFontSize': s.textFontSize,
      'chordsFontSize': s.chordsFontSize,
      'textFontWeight': s.textFontWeight.value,
      'chordsFontWeight': s.chordsFontWeight.value,
      'textActiveColor': s.textActiveColor.toARGB32(),
      'textPendingColor': s.textPendingColor.toARGB32(),
      'textInactiveColor': s.textInactiveColor.toARGB32(),
      'chordsActiveColor': s.chordsActiveColor.toARGB32(),
      'chordsPendingColor': s.chordsPendingColor.toARGB32(),
      'chordsInactiveColor': s.chordsInactiveColor.toARGB32(),
      'backgroundColor': s.backgroundColor.toARGB32(),
      'lineSpacing': s.lineSpacing,
    };
  }

  SongSettings _parseSongSettings(String jsonValue, String songId) {
    final json = jsonDecode(jsonValue) as Map<String, dynamic>;
    return SongSettings(
      songId: json['songId'] as String? ?? songId,
      textFontFamily: json['textFontFamily'] as String? ?? 'Roboto',
      chordsFontFamily: json['chordsFontFamily'] as String? ?? 'Roboto Mono',
      textFontSize: (json['textFontSize'] as num?)?.toDouble() ?? 18.0,
      chordsFontSize: (json['chordsFontSize'] as num?)?.toDouble() ?? 16.0,
      textFontWeight:
          _fontWeightFromValue(json['textFontWeight'] as int? ?? 400),
      chordsFontWeight:
          _fontWeightFromValue(json['chordsFontWeight'] as int? ?? 400),
      textActiveColor: Color(json['textActiveColor'] as int? ?? 0xFFFFFFFF),
      textPendingColor: Color(json['textPendingColor'] as int? ?? 0xFFBBBBBB),
      textInactiveColor: Color(json['textInactiveColor'] as int? ?? 0xFF666666),
      chordsActiveColor: Color(json['chordsActiveColor'] as int? ?? 0xFFBB86FC),
      chordsPendingColor: Color(json['chordsPendingColor'] as int? ?? 0xFF9B66DC),
      chordsInactiveColor: Color(json['chordsInactiveColor'] as int? ?? 0xFF665686),
      backgroundColor: Color(json['backgroundColor'] as int? ?? 0xFF121212),
      lineSpacing: (json['lineSpacing'] as num?)?.toDouble() ?? 1.4,
    );
  }

  Map<String, dynamic> _metronomeSettingsToJson(MetronomeSettings s) {
    return {
      'bpm': s.bpm,
      'isPlaying': s.isPlaying,
      'volume': s.volume,
    };
  }

  MetronomeSettings _parseMetronomeSettings(String jsonValue) {
    final json = jsonDecode(jsonValue) as Map<String, dynamic>;
    return MetronomeSettings(
      bpm: json['bpm'] as int? ?? 120,
      isPlaying: json['isPlaying'] as bool? ?? false,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.8,
    );
  }
}
