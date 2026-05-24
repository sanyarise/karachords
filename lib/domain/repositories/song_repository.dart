import '../models/song.dart';

abstract class SongRepository {
  Future<List<Song>> getAllSongs();
  Future<Song?> getSongById(String id);
  Future<void> saveSong(Song song);
  Future<void> deleteSong(String id);
  Future<List<Song>> importBuiltInSongs();
}
