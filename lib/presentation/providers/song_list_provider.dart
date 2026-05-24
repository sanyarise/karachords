import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';
import 'providers.dart';

class SongListState {
  final List<Song> allSongs;
  final List<Song> filteredSongs;
  final bool isLoading;
  final String? error;
  final String? searchQuery;

  const SongListState({
    this.allSongs = const [],
    this.filteredSongs = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery,
  });
}

class SongListNotifier extends StateNotifier<SongListState> {
  final SongRepository _repository;

  SongListNotifier(this._repository) : super(const SongListState());

  Future<void> load() async {
    state = SongListState(
      isLoading: true,
      searchQuery: state.searchQuery,
    );
    try {
      var songs = await _repository.getAllSongs();
      if (songs.isEmpty) {
        songs = await _repository.importBuiltInSongs();
      }
      state = SongListState(
        allSongs: songs,
        filteredSongs: songs,
        isLoading: false,
        searchQuery: state.searchQuery,
      );
    } catch (e) {
      state = SongListState(
        isLoading: false,
        error: e.toString(),
        searchQuery: state.searchQuery,
      );
    }
  }

  void search(String query) {
    final lower = query.toLowerCase().trim();
    final filtered = state.allSongs.where((song) {
      return song.title.toLowerCase().contains(lower) ||
          song.artist.toLowerCase().contains(lower);
    }).toList();
    state = SongListState(
      allSongs: state.allSongs,
      filteredSongs: filtered,
      isLoading: false,
      searchQuery: query,
    );
  }

  Future<void> deleteSong(Song song) async {
    try {
      await _repository.deleteSong(song.id);
      final updated = state.allSongs.where((s) => s.id != song.id).toList();
      final q = state.searchQuery?.toLowerCase().trim() ?? '';
      final filtered = q.isEmpty
          ? updated
          : updated.where((s) {
              return s.title.toLowerCase().contains(q) ||
                  s.artist.toLowerCase().contains(q);
            }).toList();
      state = SongListState(
        allSongs: updated,
        filteredSongs: filtered,
        isLoading: false,
        searchQuery: state.searchQuery,
      );
    } catch (e) {
      state = SongListState(
        allSongs: state.allSongs,
        filteredSongs: state.filteredSongs,
        isLoading: false,
        error: e.toString(),
        searchQuery: state.searchQuery,
      );
    }
  }

  Future<void> undoDelete(Song song) async {
    try {
      await _repository.saveSong(song);
      await load();
    } catch (e) {
      state = SongListState(
        allSongs: state.allSongs,
        filteredSongs: state.filteredSongs,
        isLoading: false,
        error: e.toString(),
        searchQuery: state.searchQuery,
      );
    }
  }
}

final songListProvider = StateNotifierProvider<SongListNotifier, SongListState>(
  (ref) => SongListNotifier(ref.watch(songRepositoryProvider)),
);
