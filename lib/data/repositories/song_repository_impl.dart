import '../../domain/models/song.dart';
import '../../domain/repositories/song_repository.dart';
import '../local/song_dao.dart';

class SongRepositoryImpl implements SongRepository {
  final SongDao _dao;

  SongRepositoryImpl(this._dao);

  @override
  Future<List<Song>> getAllSongs() => _dao.getAllSongs();

  @override
  Future<Song?> getSongById(String id) => _dao.getSongById(id);

  @override
  Future<void> saveSong(Song song) => _dao.insertSong(song);

  @override
  Future<void> deleteSong(String id) => _dao.deleteSong(id);

  @override
  Future<List<Song>> importBuiltInSongs() => _dao.importBuiltInSongs();
}
