import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/settings_dao.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/models/song_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'providers.dart';

final settingsDaoProvider = Provider<SettingsDao>((ref) {
  return SettingsDao(ref.watch(appDatabaseProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsDaoProvider));
});

/// Notifier for per-song visual settings with debounced persistence.
class SongSettingsNotifier extends StateNotifier<SongSettings> {
  final SettingsRepository _repository;
  final String songId;

  Timer? _debounceTimer;

  SongSettingsNotifier(this._repository, this.songId)
      : super(SongSettings(songId: songId));

  Future<void> load() async {
    state = await _repository.getSongSettings(songId);
  }

  void update({
    String? textFontFamily,
    String? chordsFontFamily,
    double? textFontSize,
    double? chordsFontSize,
    FontWeight? textFontWeight,
    FontWeight? chordsFontWeight,
    Color? textActiveColor,
    Color? textPendingColor,
    Color? textInactiveColor,
    Color? chordsActiveColor,
    Color? chordsPendingColor,
    Color? chordsInactiveColor,
    Color? backgroundColor,
    double? lineSpacing,
  }) {
    final next = state.copyWith(
      textFontFamily: textFontFamily,
      chordsFontFamily: chordsFontFamily,
      textFontSize: textFontSize,
      chordsFontSize: chordsFontSize,
      textFontWeight: textFontWeight,
      chordsFontWeight: chordsFontWeight,
      textActiveColor: textActiveColor,
      textPendingColor: textPendingColor,
      textInactiveColor: textInactiveColor,
      chordsActiveColor: chordsActiveColor,
      chordsPendingColor: chordsPendingColor,
      chordsInactiveColor: chordsInactiveColor,
      backgroundColor: backgroundColor,
      lineSpacing: lineSpacing,
    );
    state = next;
    _saveDebounced(next);
  }

  void reset() {
    final defaults = SongSettings(songId: songId);
    state = defaults;
    _saveDebounced(defaults);
  }

  void _saveDebounced(SongSettings settings) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _repository.saveSongSettings(settings);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// Family provider keyed by [songId].
final songSettingsProvider =
    StateNotifierProvider.family<SongSettingsNotifier, SongSettings, String>(
  (ref, songId) {
    final repo = ref.watch(settingsRepositoryProvider);
    final notifier = SongSettingsNotifier(repo, songId);
    // Eagerly load persisted settings.
    notifier.load();
    return notifier;
  },
);
